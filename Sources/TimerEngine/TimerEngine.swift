import Foundation
import Program

/// Чистая машина дневной сессии с явными календарным и монотонным временем.
public struct TimerEngine: Sendable {
    private struct Context: Sendable {
        var program: DailyProgram
        var dayEnd: Date
        var midnight: Date
        var pauseCount: Int
    }

    private struct ActiveInterval: Sendable {
        var context: Context
        let kind: WorkdayIntervalKind
        let number: Int
        var durationSeconds: TimeInterval
        var consumedSeconds: TimeInterval
        var segmentStart: TimerTime

        func consumed(at time: TimerTime) -> TimeInterval {
            consumedSeconds + max(0, time.elapsedSeconds - segmentStart.elapsedSeconds)
        }

        func remaining(at time: TimerTime) -> TimeInterval {
            max(0, durationSeconds - consumed(at: time))
        }

        var completionElapsedSeconds: TimeInterval {
            segmentStart.elapsedSeconds + max(0, durationSeconds - consumedSeconds)
        }

        var projectedEnd: Date {
            segmentStart.date.addingTimeInterval(max(0, durationSeconds - consumedSeconds))
        }

        mutating func rebase(at time: TimerTime) {
            consumedSeconds = min(durationSeconds, consumed(at: time))
            segmentStart = time
        }
    }

    private struct PausedFocus: Sendable {
        var interval: ActiveInterval
        let number: Int
    }

    private struct AwaitingConfirmation: Sendable {
        var context: Context
        let nextFocusNumber: Int
    }

    private enum State: Sendable {
        case ready
        case focus(ActiveInterval)
        case paused(PausedFocus)
        case rest(ActiveInterval)
        case awaiting(AwaitingConfirmation)
        case finished(Context)
    }

    private var state: State = .ready
    private var referenceTime = TimerTime(date: .distantPast, elapsedSeconds: 0)

    public init() {}

    public var snapshot: TimerSessionSnapshot {
        switch state {
        case .ready:
            return TimerSessionSnapshot(phase: .ready)
        case .focus(let interval):
            return activeSnapshot(.focus, interval: interval)
        case .paused(let pause):
            return TimerSessionSnapshot(
                phase: .paused,
                focusNumber: pause.interval.number,
                pauseCount: pause.number,
                remainingSeconds: pause.interval.durationSeconds - pause.interval.consumedSeconds,
                dayEnd: pause.interval.context.dayEnd
            )
        case .rest(let interval):
            return activeSnapshot(.rest, interval: interval)
        case .awaiting(let waiting):
            return TimerSessionSnapshot(
                phase: .awaitingConfirmation,
                focusNumber: waiting.nextFocusNumber,
                pauseCount: waiting.context.pauseCount,
                dayEnd: waiting.context.dayEnd
            )
        case .finished(let context):
            return TimerSessionSnapshot(
                phase: .finished,
                pauseCount: context.pauseCount,
                dayEnd: context.dayEnd
            )
        }
    }

    @discardableResult
    public mutating func start(
        program: DailyProgram,
        at time: TimerTime,
        calendar: Calendar
    ) -> [TimerEffect] {
        referenceTime = time
        switch state {
        case .ready:
            return beginDay(program: program, at: time, calendar: calendar)
        case .finished(let oldContext):
            guard let newContext = makeContext(program: program, at: time, calendar: calendar),
                newContext.midnight != oldContext.midnight
            else { return [] }
            state = .ready
            return beginDay(program: program, at: time, calendar: calendar)
        default:
            return []
        }
    }

    @discardableResult
    public mutating func advance(to time: TimerTime, calendar: Calendar) -> [TimerEffect] {
        referenceTime = time
        guard !isPastMidnight(time.date) else {
            return finishForMidnight()
        }

        var latestEffect: TimerEffect?
        var shouldContinue = true
        while shouldContinue {
            shouldContinue = false
            switch state {
            case .focus(let interval) where interval.remaining(at: time) == 0:
                let boundary = boundaryTime(for: interval, observedAt: time)
                latestEffect = completeFocus(interval, at: boundary)
                shouldContinue = stateHasCompletedInterval(at: time)
            case .rest(let interval) where interval.remaining(at: time) == 0:
                let boundary = boundaryTime(for: interval, observedAt: time)
                latestEffect = completeRest(interval, at: boundary)
            case .awaiting(let waiting) where time.date >= effectiveLimit(for: waiting.context):
                state = .finished(waiting.context)
                latestEffect = .dayFinished
            default:
                break
            }
        }
        return latestEffect.map { [$0] } ?? []
    }

    @discardableResult
    public mutating func pause(at time: TimerTime, calendar: Calendar) -> [TimerEffect] {
        let effects = advance(to: time, calendar: calendar)
        guard effects.isEmpty, case .focus(var interval) = state,
            time.date < interval.context.dayEnd
        else { return effects }

        interval.rebase(at: time)
        interval.context.pauseCount += 1
        state = .paused(PausedFocus(interval: interval, number: interval.context.pauseCount))
        return []
    }

    @discardableResult
    public mutating func resume(at time: TimerTime, calendar: Calendar) -> [TimerEffect] {
        referenceTime = time
        guard case .paused(var pause) = state else { return [] }
        guard time.date < pause.interval.context.midnight else {
            state = .finished(pause.interval.context)
            return [.dayFinished]
        }
        pause.interval.segmentStart = time
        state = .focus(pause.interval)
        return []
    }

    @discardableResult
    public mutating func continueAfterRest(
        at time: TimerTime,
        calendar: Calendar
    ) -> [TimerEffect] {
        referenceTime = time
        guard case .awaiting(let waiting) = state else { return [] }
        guard time.date < waiting.context.midnight,
            canFit(
                durationMinutes: waiting.context.program.duration(for: .focus),
                from: time.date,
                in: waiting.context
            )
        else {
            state = .finished(waiting.context)
            return [.dayFinished]
        }
        state = .focus(
            makeInterval(
                context: waiting.context,
                kind: .focus,
                number: waiting.nextFocusNumber,
                durationMinutes: waiting.context.program.duration(for: .focus),
                start: time
            ))
        return []
    }

    @discardableResult
    public mutating func updateProgram(
        _ program: DailyProgram,
        at time: TimerTime,
        calendar: Calendar
    ) -> [TimerEffect] {
        referenceTime = time
        switch state {
        case .ready:
            return []
        case .focus(var interval):
            interval.rebase(at: time)
            interval.context = updatedContext(interval.context, program: program, at: time, calendar: calendar)
            interval.durationSeconds = seconds(program.duration(for: .focus))
            if interval.consumedSeconds >= interval.durationSeconds {
                interval.consumedSeconds = interval.durationSeconds
                return [completeFocus(interval, at: time)]
            }
            state = .focus(interval)
            return []
        case .paused(var pause):
            pause.interval.context = updatedContext(
                pause.interval.context, program: program, at: time, calendar: calendar)
            pause.interval.durationSeconds = seconds(program.duration(for: .focus))
            if pause.interval.consumedSeconds >= pause.interval.durationSeconds {
                pause.interval.consumedSeconds = pause.interval.durationSeconds
                return [completeFocus(pause.interval, at: time)]
            }
            state = .paused(pause)
            return []
        case .rest(var interval):
            interval.rebase(at: time)
            interval.context = updatedContext(interval.context, program: program, at: time, calendar: calendar)
            interval.durationSeconds = seconds(program.restDuration(afterFocusNumber: interval.number))
            guard time.date < effectiveLimit(for: interval.context) else {
                state = .finished(interval.context)
                return [.dayFinished]
            }
            if interval.consumedSeconds >= interval.durationSeconds {
                interval.consumedSeconds = interval.durationSeconds
                return [completeRest(interval, at: time)]
            }
            state = .rest(interval)
            return []
        case .awaiting(var waiting):
            waiting.context = updatedContext(waiting.context, program: program, at: time, calendar: calendar)
            if time.date >= effectiveLimit(for: waiting.context) {
                state = .finished(waiting.context)
                return [.dayFinished]
            }
            state = .awaiting(waiting)
            return []
        case .finished(var context):
            context = updatedContext(context, program: program, at: time, calendar: calendar)
            state = .finished(context)
            return []
        }
    }

    @discardableResult
    public mutating func calendarChanged(
        at time: TimerTime,
        calendar: Calendar
    ) -> [TimerEffect] {
        referenceTime = time
        switch state {
        case .focus(var interval):
            interval.rebase(at: time)
            interval.context = updatedContext(
                interval.context, program: interval.context.program, at: time, calendar: calendar)
            state = .focus(interval)
        case .paused(var pause):
            pause.interval.context = updatedContext(
                pause.interval.context, program: pause.interval.context.program, at: time, calendar: calendar)
            state = .paused(pause)
        case .rest(var interval):
            interval.rebase(at: time)
            interval.context = updatedContext(
                interval.context, program: interval.context.program, at: time, calendar: calendar)
            if time.date >= effectiveLimit(for: interval.context) {
                state = .finished(interval.context)
                return [.dayFinished]
            }
            state = .rest(interval)
        case .awaiting(var waiting):
            waiting.context = updatedContext(
                waiting.context, program: waiting.context.program, at: time, calendar: calendar)
            if time.date >= effectiveLimit(for: waiting.context) {
                state = .finished(waiting.context)
                return [.dayFinished]
            }
            state = .awaiting(waiting)
        case .ready, .finished:
            break
        }
        return []
    }

    public mutating func stop() {
        state = .ready
        referenceTime = TimerTime(date: .distantPast, elapsedSeconds: 0)
    }

    private func activeSnapshot(
        _ phase: TimerSessionPhase,
        interval: ActiveInterval
    ) -> TimerSessionSnapshot {
        TimerSessionSnapshot(
            phase: phase,
            focusNumber: interval.number,
            restNumber: phase == .rest ? interval.number : nil,
            pauseCount: interval.context.pauseCount,
            remainingSeconds: interval.remaining(at: referenceTime),
            projectedIntervalEnd: interval.projectedEnd,
            dayEnd: interval.context.dayEnd
        )
    }

    private mutating func beginDay(
        program: DailyProgram,
        at time: TimerTime,
        calendar: Calendar
    ) -> [TimerEffect] {
        guard let context = makeContext(program: program, at: time, calendar: calendar),
            canFit(
                durationMinutes: program.duration(for: .focus),
                from: time.date,
                in: context
            )
        else { return [] }
        state = .focus(
            makeInterval(
                context: context,
                kind: .focus,
                number: 1,
                durationMinutes: program.duration(for: .focus),
                start: time
            ))
        return []
    }

    private func makeContext(
        program: DailyProgram,
        at time: TimerTime,
        calendar: Calendar
    ) -> Context? {
        let startOfDay = calendar.startOfDay(for: time.date)
        guard let midnight = calendar.date(byAdding: .day, value: 1, to: startOfDay),
            let dayEnd = calendar.date(byAdding: .minute, value: program.endMinutes, to: startOfDay)
        else { return nil }
        return Context(program: program, dayEnd: dayEnd, midnight: midnight, pauseCount: 0)
    }

    private func updatedContext(
        _ context: Context,
        program: DailyProgram,
        at time: TimerTime,
        calendar: Calendar
    ) -> Context {
        guard var updated = makeContext(program: program, at: time, calendar: calendar) else {
            return context
        }
        updated.pauseCount = context.pauseCount
        return updated
    }

    private func makeInterval(
        context: Context,
        kind: WorkdayIntervalKind,
        number: Int,
        durationMinutes: Int,
        start: TimerTime
    ) -> ActiveInterval {
        ActiveInterval(
            context: context,
            kind: kind,
            number: number,
            durationSeconds: seconds(durationMinutes),
            consumedSeconds: 0,
            segmentStart: start
        )
    }

    private mutating func completeFocus(
        _ interval: ActiveInterval,
        at boundary: TimerTime
    ) -> TimerEffect {
        let restMinutes = interval.context.program.restDuration(afterFocusNumber: interval.number)
        if canFit(durationMinutes: restMinutes, from: boundary.date, in: interval.context) {
            state = .rest(
                makeInterval(
                    context: interval.context,
                    kind: .rest,
                    number: interval.number,
                    durationMinutes: restMinutes,
                    start: boundary
                ))
        } else if canFit(
            durationMinutes: interval.context.program.duration(for: .focus),
            from: boundary.date,
            in: interval.context
        ) {
            state = .awaiting(
                AwaitingConfirmation(context: interval.context, nextFocusNumber: interval.number + 1))
        } else {
            state = .finished(interval.context)
        }
        return .focusCompleted(number: interval.number)
    }

    private mutating func completeRest(
        _ interval: ActiveInterval,
        at boundary: TimerTime
    ) -> TimerEffect {
        if canFit(
            durationMinutes: interval.context.program.duration(for: .focus),
            from: boundary.date,
            in: interval.context
        ) {
            state = .awaiting(
                AwaitingConfirmation(context: interval.context, nextFocusNumber: interval.number + 1))
        } else {
            state = .finished(interval.context)
        }
        return .restCompleted(number: interval.number)
    }

    private func boundaryTime(
        for interval: ActiveInterval,
        observedAt time: TimerTime
    ) -> TimerTime {
        let overshoot = max(0, time.elapsedSeconds - interval.completionElapsedSeconds)
        return TimerTime(
            date: time.date.addingTimeInterval(-overshoot),
            elapsedSeconds: interval.completionElapsedSeconds
        )
    }

    private func stateHasCompletedInterval(at time: TimerTime) -> Bool {
        switch state {
        case .focus(let interval), .rest(let interval):
            return interval.remaining(at: time) == 0
        default:
            return false
        }
    }

    private func canFit(
        durationMinutes: Int,
        from start: Date,
        in context: Context
    ) -> Bool {
        start.addingTimeInterval(seconds(durationMinutes)) <= effectiveLimit(for: context)
    }

    private func effectiveLimit(for context: Context) -> Date {
        min(context.dayEnd, context.midnight)
    }

    private func isPastMidnight(_ date: Date) -> Bool {
        switch state {
        case .focus(let interval), .rest(let interval):
            return date >= interval.context.midnight
        case .paused(let pause):
            return date >= pause.interval.context.midnight
        case .awaiting(let waiting):
            return date >= waiting.context.midnight
        case .finished, .ready:
            return false
        }
    }

    private mutating func finishForMidnight() -> [TimerEffect] {
        switch state {
        case .focus(let interval), .rest(let interval):
            state = .finished(interval.context)
        case .paused(let pause):
            state = .finished(pause.interval.context)
        case .awaiting(let waiting):
            state = .finished(waiting.context)
        case .ready, .finished:
            return []
        }
        return [.dayFinished]
    }

    private func seconds(_ minutes: Int) -> TimeInterval {
        TimeInterval(minutes * 60)
    }
}
