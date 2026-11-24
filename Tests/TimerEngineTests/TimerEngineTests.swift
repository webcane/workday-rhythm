import Foundation
import XCTest

@testable import Program
@testable import TimerEngine

final class TimerEngineTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }

    func testFocusRestAndConfirmationTransitionsAreIdempotent() throws {
        var engine = TimerEngine()
        let start = time(hour: 9)
        engine.start(program: try program(), at: start, calendar: calendar)
        XCTAssertEqual(engine.snapshot.phase, .focus)
        XCTAssertEqual(engine.snapshot.focusNumber, 1)

        let focusEnd = advanced(start, minutes: 40)
        XCTAssertEqual(engine.advance(to: focusEnd, calendar: calendar), [.focusCompleted(number: 1)])
        XCTAssertEqual(engine.snapshot.phase, .rest)
        XCTAssertEqual(engine.advance(to: focusEnd, calendar: calendar), [])

        let restEnd = advanced(start, minutes: 60)
        XCTAssertEqual(engine.advance(to: restEnd, calendar: calendar), [.restCompleted(number: 1)])
        XCTAssertEqual(engine.snapshot.phase, .awaitingConfirmation)
        XCTAssertEqual(engine.advance(to: restEnd, calendar: calendar), [])

        engine.continueAfterRest(at: restEnd, calendar: calendar)
        XCTAssertEqual(engine.snapshot.phase, .focus)
        XCTAssertEqual(engine.snapshot.focusNumber, 2)
    }

    func testSleepProducesOnlyCurrentSignal() throws {
        var engine = TimerEngine()
        let start = time(hour: 12)
        engine.start(program: try program(), at: start, calendar: calendar)

        let wakeDuringRest = advanced(start, minutes: 50)
        XCTAssertEqual(engine.advance(to: wakeDuringRest, calendar: calendar), [.focusCompleted(number: 1)])
        XCTAssertEqual(engine.snapshot.phase, .rest)
        XCTAssertEqual(engine.snapshot.remainingSeconds, 10 * 60)

        engine.stop()
        engine.start(program: try program(), at: start, calendar: calendar)
        let wakeAfterRest = advanced(start, minutes: 75)
        XCTAssertEqual(engine.advance(to: wakeAfterRest, calendar: calendar), [.restCompleted(number: 1)])
        XCTAssertEqual(engine.snapshot.phase, .awaitingConfirmation)
    }

    func testSeveralPausesAccumulateAndRejectNestedPause() throws {
        var engine = TimerEngine()
        let start = time(hour: 9)
        engine.start(program: try program(), at: start, calendar: calendar)

        engine.pause(at: advanced(start, minutes: 10), calendar: calendar)
        XCTAssertEqual(engine.snapshot.pauseCount, 1)
        engine.pause(at: advanced(start, minutes: 12), calendar: calendar)
        XCTAssertEqual(engine.snapshot.pauseCount, 1)
        engine.resume(at: advanced(start, minutes: 15), calendar: calendar)

        engine.pause(at: advanced(start, minutes: 25), calendar: calendar)
        XCTAssertEqual(engine.snapshot.pauseCount, 2)
        engine.resume(at: advanced(start, minutes: 35), calendar: calendar)

        let completion = advanced(start, minutes: 55)
        XCTAssertEqual(engine.advance(to: completion, calendar: calendar), [.focusCompleted(number: 1)])
        XCTAssertEqual(engine.snapshot.pauseCount, 2)
        XCTAssertEqual(engine.snapshot.phase, .rest)
    }

    func testLateConfirmationStartsFullFocusWhenItFits() throws {
        var engine = TimerEngine()
        let start = time(hour: 12)
        engine.start(program: try program(dayHours: 6), at: start, calendar: calendar)
        engine.advance(to: advanced(start, minutes: 60), calendar: calendar)

        let confirmation = advanced(start, minutes: 75)
        engine.continueAfterRest(at: confirmation, calendar: calendar)

        XCTAssertEqual(engine.snapshot.phase, .focus)
        XCTAssertEqual(engine.snapshot.remainingSeconds, 40 * 60)
        XCTAssertEqual(engine.snapshot.projectedIntervalEnd, confirmation.date.addingTimeInterval(40 * 60))
    }

    func testOverrideEndAndFullFitRules() throws {
        let lunchProgram = try program(
            overrides: [.init(afterFocusNumber: 4, durationMinutes: 60)])
        var lunch = TimerEngine()
        lunch.start(program: lunchProgram, at: time(hour: 9), calendar: calendar)
        XCTAssertEqual(lunch.snapshot.dayEnd, date(hour: 17, minute: 40))

        var exact = TimerEngine()
        exact.start(
            program: try program(startMinutes: 600),
            at: time(hour: 17, minute: 20),
            calendar: calendar
        )
        XCTAssertEqual(exact.snapshot.phase, .focus)

        var tooLate = TimerEngine()
        tooLate.start(
            program: try program(startMinutes: 600),
            at: time(hour: 17, minute: 35),
            calendar: calendar
        )
        XCTAssertEqual(tooLate.snapshot.phase, .ready)
    }

    func testLunchAfterFourthFocusKeepsAlternationAndRestNumber() throws {
        var engine = TimerEngine()
        let start = time(hour: 9)
        engine.start(
            program: try program(
                overrides: [.init(afterFocusNumber: 4, durationMinutes: 60)]
            ),
            at: start,
            calendar: calendar
        )

        for cycle in 0..<3 {
            let focusEnd = advanced(start, minutes: cycle * 60 + 40)
            engine.advance(to: focusEnd, calendar: calendar)
            let restEnd = advanced(start, minutes: (cycle + 1) * 60)
            engine.advance(to: restEnd, calendar: calendar)
            engine.continueAfterRest(at: restEnd, calendar: calendar)
        }

        XCTAssertEqual(engine.snapshot.phase, .focus)
        XCTAssertEqual(engine.snapshot.focusNumber, 4)
        engine.advance(to: advanced(start, minutes: 3 * 60 + 40), calendar: calendar)
        XCTAssertEqual(engine.snapshot.phase, .rest)
        XCTAssertEqual(engine.snapshot.restNumber, 4)
        XCTAssertEqual(engine.snapshot.remainingSeconds, 60 * 60)
    }

    func testStartedFocusFinishesAfterEndAndSkipsRest() throws {
        var engine = TimerEngine()
        let start = time(hour: 16, minute: 20)
        engine.start(program: try program(), at: start, calendar: calendar)
        engine.pause(at: advanced(start, minutes: 20), calendar: calendar)
        engine.resume(at: advanced(start, minutes: 40), calendar: calendar)

        let completion = advanced(start, minutes: 60)
        XCTAssertEqual(engine.advance(to: completion, calendar: calendar), [.focusCompleted(number: 1)])
        XCTAssertEqual(engine.snapshot.phase, .finished)
    }

    func testRestAndLongRestAreSkippedWithoutTruncation() throws {
        var shortRest = TimerEngine()
        let start = time(hour: 17, minute: 15)
        shortRest.start(
            program: try program(startMinutes: 600),
            at: start,
            calendar: calendar
        )
        XCTAssertEqual(
            shortRest.advance(to: advanced(start, minutes: 40), calendar: calendar),
            [.focusCompleted(number: 1)]
        )
        XCTAssertEqual(shortRest.snapshot.phase, .finished)

        var longRest = TimerEngine()
        let longRestStart = time(hour: 18, minute: 30)
        longRest.start(
            program: try program(
                startMinutes: 600,
                focusMinutes: 10,
                restMinutes: 5,
                overrides: [.init(afterFocusNumber: 1, durationMinutes: 60)]
            ),
            at: longRestStart,
            calendar: calendar
        )
        longRest.advance(to: advanced(longRestStart, minutes: 10), calendar: calendar)
        XCTAssertEqual(longRest.snapshot.phase, .awaitingConfirmation)
        XCTAssertEqual(longRest.snapshot.focusNumber, 2)
    }

    func testUpdatingDurationsPreservesConsumedTime() throws {
        var engine = TimerEngine()
        let start = time(hour: 9)
        engine.start(program: try program(), at: start, calendar: calendar)
        let afterThirty = advanced(start, minutes: 30)

        XCTAssertEqual(
            engine.updateProgram(
                try program(focusMinutes: 20), at: afterThirty, calendar: calendar),
            [.focusCompleted(number: 1)]
        )
        XCTAssertEqual(engine.snapshot.phase, .rest)

        engine.stop()
        engine.start(program: try program(), at: start, calendar: calendar)
        engine.updateProgram(try program(focusMinutes: 60), at: afterThirty, calendar: calendar)
        XCTAssertEqual(engine.snapshot.remainingSeconds, 30 * 60)
    }

    func testUpdatingRestAndBoundaryAppliesImmediately() throws {
        var engine = TimerEngine()
        let start = time(hour: 9)
        engine.start(program: try program(), at: start, calendar: calendar)
        engine.advance(to: advanced(start, minutes: 40), calendar: calendar)
        let afterTenRest = advanced(start, minutes: 50)

        engine.updateProgram(try program(restMinutes: 15), at: afterTenRest, calendar: calendar)
        XCTAssertEqual(engine.snapshot.remainingSeconds, 5 * 60)

        let withLunch = try program(
            restMinutes: 20,
            overrides: [.init(afterFocusNumber: 4, durationMinutes: 60)])
        engine.updateProgram(withLunch, at: afterTenRest, calendar: calendar)
        XCTAssertEqual(engine.snapshot.dayEnd, date(hour: 17, minute: 40))

        let changedDefault = try program(
            restMinutes: 15,
            overrides: [.init(afterFocusNumber: 4, durationMinutes: 60)])
        engine.updateProgram(changedDefault, at: afterTenRest, calendar: calendar)
        XCTAssertEqual(engine.snapshot.dayEnd, date(hour: 17, minute: 45))
    }

    func testUpdatingCommonRestDoesNotChangeCurrentOverride() throws {
        var engine = TimerEngine()
        let start = time(hour: 9)
        engine.start(
            program: try program(
                focusMinutes: 10,
                overrides: [.init(afterFocusNumber: 1, durationMinutes: 60)]
            ),
            at: start,
            calendar: calendar
        )
        engine.advance(to: advanced(start, minutes: 10), calendar: calendar)
        let afterTenRest = advanced(start, minutes: 20)

        engine.updateProgram(
            try program(
                focusMinutes: 10,
                restMinutes: 15,
                overrides: [.init(afterFocusNumber: 1, durationMinutes: 60)]
            ),
            at: afterTenRest,
            calendar: calendar
        )
        XCTAssertEqual(engine.snapshot.remainingSeconds, 50 * 60)

        engine.updateProgram(
            try program(
                focusMinutes: 10,
                restMinutes: 15,
                overrides: [.init(afterFocusNumber: 1, durationMinutes: 20)]
            ),
            at: afterTenRest,
            calendar: calendar
        )
        XCTAssertEqual(engine.snapshot.remainingSeconds, 10 * 60)
    }

    func testShorterDayFinishesRestAndWaitingButNotCurrentFocus() throws {
        let shorter = try program(dayHours: 6)

        var focus = TimerEngine()
        let focusStart = time(hour: 16)
        focus.start(program: try program(), at: focusStart, calendar: calendar)
        XCTAssertEqual(focus.updateProgram(shorter, at: focusStart, calendar: calendar), [])
        XCTAssertEqual(focus.snapshot.phase, .focus)
        focus.advance(to: advanced(focusStart, minutes: 40), calendar: calendar)
        XCTAssertEqual(focus.snapshot.phase, .finished)

        var rest = TimerEngine()
        let restStart = time(hour: 15, minute: 10)
        rest.start(program: try program(), at: restStart, calendar: calendar)
        rest.advance(to: advanced(restStart, minutes: 40), calendar: calendar)
        XCTAssertEqual(rest.snapshot.phase, .rest)
        XCTAssertEqual(
            rest.updateProgram(shorter, at: advanced(restStart, minutes: 50), calendar: calendar),
            [.dayFinished]
        )
        XCTAssertEqual(rest.snapshot.phase, .finished)

        var waiting = TimerEngine()
        let waitingStart = time(hour: 15)
        waiting.start(program: try program(), at: waitingStart, calendar: calendar)
        waiting.advance(to: advanced(waitingStart, minutes: 60), calendar: calendar)
        XCTAssertEqual(waiting.snapshot.phase, .awaitingConfirmation)
        XCTAssertEqual(
            waiting.updateProgram(shorter, at: advanced(waitingStart, minutes: 60), calendar: calendar),
            [.dayFinished]
        )
        XCTAssertEqual(waiting.snapshot.phase, .finished)
    }

    func testClockChangePreservesRemainingAndMidnightFinishes() throws {
        var engine = TimerEngine()
        let start = time(hour: 9)
        engine.start(program: try program(), at: start, calendar: calendar)
        let afterTwentyFive = advanced(start, minutes: 25)
        let clockMoved = TimerTime(
            date: afterTwentyFive.date.addingTimeInterval(3_600),
            elapsedSeconds: afterTwentyFive.elapsedSeconds
        )

        engine.calendarChanged(at: clockMoved, calendar: calendar)
        XCTAssertEqual(engine.snapshot.remainingSeconds, 15 * 60)

        let midnight = TimerTime(date: date(day: 2, hour: 0), elapsedSeconds: 24 * 60 * 60)
        XCTAssertEqual(engine.advance(to: midnight, calendar: calendar), [.dayFinished])
        XCTAssertEqual(engine.snapshot.phase, .finished)
    }

    private func program(
        startMinutes: Int = 540,
        dayHours: Int = 8,
        focusMinutes: Int = 40,
        restMinutes: Int = 20,
        overrides: [RestDurationOverride] = []
    ) throws -> DailyProgram {
        try DailyProgram(
            startMinutes: startMinutes,
            dayHours: dayHours,
            defaults: [
                .init(kind: .focus, durationMinutes: focusMinutes),
                .init(kind: .rest, durationMinutes: restMinutes),
            ],
            restDurationOverrides: overrides
        )
    }

    private func time(hour: Int, minute: Int = 0) -> TimerTime {
        TimerTime(
            date: date(hour: hour, minute: minute),
            elapsedSeconds: TimeInterval((hour * 60 + minute) * 60)
        )
    }

    private func date(day: Int = 1, hour: Int, minute: Int = 0) -> Date {
        calendar.date(
            from: DateComponents(year: 2026, month: 1, day: day, hour: hour, minute: minute))!
    }

    private func advanced(_ time: TimerTime, minutes: Int) -> TimerTime {
        let seconds = TimeInterval(minutes * 60)
        return TimerTime(
            date: time.date.addingTimeInterval(seconds),
            elapsedSeconds: time.elapsedSeconds + seconds
        )
    }
}
