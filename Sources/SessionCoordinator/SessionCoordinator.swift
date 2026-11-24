import Foundation
import MacIntegration
import Program
import SettingsStore
import TimerEngine

/// Последовательно связывает чистое ядро, настройки и системные события macOS.
@MainActor
public final class SessionCoordinator {
    public nonisolated static let defaultDailyProgramRules = DailyProgramRulesSnapshot(DailyProgramRules.standard)

    private var engine: TimerEngine
    private let settings: SettingsStore
    private let integration: any MacIntegrating
    private let timeSource: any SystemTimeProviding
    private let calendarProvider: () -> Calendar
    private let signalHandler: (SessionSignal) -> Void

    public var status: SessionStatus {
        let snapshot = engine.snapshot
        return SessionStatus(
            stage: stage(for: snapshot.phase),
            focusNumber: snapshot.focusNumber,
            restNumber: snapshot.restNumber,
            pauseCount: snapshot.pauseCount,
            remainingSeconds: snapshot.remainingSeconds,
            dayEnd: snapshot.dayEnd
        )
    }

    public var program: DailyProgram {
        settings.loadProgram()
    }

    public var programSettings: DailyProgramSettings {
        DailyProgramSettings(program: settings.loadProgram())
    }

    /// Ограничения формы как независимый от Program снимок.
    public var dailyProgramRules: DailyProgramRulesSnapshot {
        Self.defaultDailyProgramRules
    }

    /// Запрос формы через координатор, переданный оболочке приложения.
    public func projectLongBreakOptions(_ request: LongBreakOptionsRequest) -> LongBreakOptionsSnapshot {
        Self.longBreakOptions(for: request)
    }

    /// Синхронный расчёт черновика без изменения настроек и состояния сессии.
    public static func longBreakOptions(for request: LongBreakOptionsRequest) -> LongBreakOptionsSnapshot {
        do {
            let options = try LongBreakProjection.options(
                for: .init(
                    startMinutes: request.startMinutes, dayHours: request.dayHours,
                    defaults: [
                        .init(kind: .focus, durationMinutes: request.focusMinutes),
                        .init(kind: .rest, durationMinutes: request.restMinutes),
                    ], durationMinutes: request.durationMinutes,
                    otherOverrides: request.otherOverrides.map {
                        .init(afterFocusNumber: $0.afterFocusNumber, durationMinutes: $0.durationMinutes)
                    }))
            return LongBreakOptionsSnapshot(
                options: options.map {
                    .init(
                        afterFocusNumber: $0.afterFocusNumber, startMinutes: $0.startMinutes,
                        isAvailable: $0.isAvailable)
                })
        } catch {
            return LongBreakOptionsSnapshot(
                options: [], errorMessage: "Исправьте параметры дня и длительности интервалов.")
        }
    }

    public init(
        settings: SettingsStore,
        integration: any MacIntegrating,
        timeSource: any SystemTimeProviding = MacSystemTimeSource(),
        calendarProvider: @escaping () -> Calendar = { .autoupdatingCurrent },
        signalHandler: @escaping (SessionSignal) -> Void = { _ in }
    ) {
        self.engine = TimerEngine()
        self.settings = settings
        self.integration = integration
        self.timeSource = timeSource
        self.calendarProvider = calendarProvider
        self.signalHandler = signalHandler
        integration.startObserving { [weak self] event in
            self?.handleSystemEvent(event)
        }
    }

    public func startDay() {
        let time = currentTime()
        process(engine.start(program: settings.loadProgram(), at: time, calendar: calendarProvider()))
        rescheduleBoundary()
    }

    public func pause() {
        process(engine.pause(at: currentTime(), calendar: calendarProvider()))
        rescheduleBoundary()
    }

    public func resume() {
        process(engine.resume(at: currentTime(), calendar: calendarProvider()))
        rescheduleBoundary()
    }

    public func continueAfterRest() {
        process(engine.continueAfterRest(at: currentTime(), calendar: calendarProvider()))
        rescheduleBoundary()
    }

    public func saveProgram(_ program: DailyProgram) throws {
        try settings.saveProgram(program)
        process(engine.updateProgram(program, at: currentTime(), calendar: calendarProvider()))
        rescheduleBoundary()
    }

    public func saveProgram(_ values: DailyProgramSettings) throws {
        try saveProgram(values.makeProgram())
    }

    public func handleSystemEvent(_ event: MacSystemEvent) {
        let time = currentTime()
        switch event {
        case .clockChanged, .timeZoneChanged:
            process(engine.calendarChanged(at: time, calendar: calendarProvider()))
            process(engine.advance(to: time, calendar: calendarProvider()))
        case .activity, .wake, .dayChanged:
            process(engine.advance(to: time, calendar: calendarProvider()))
        }
        rescheduleBoundary()
    }

    public func stopSession() {
        integration.cancelScheduledBoundary()
        integration.stopObserving()
        engine.stop()
    }

    private func currentTime() -> TimerTime {
        let time = timeSource.snapshot()
        return TimerTime(date: time.date, elapsedSeconds: time.elapsedSeconds)
    }

    private func timerFired() {
        process(engine.advance(to: currentTime(), calendar: calendarProvider()))
        rescheduleBoundary()
    }

    private func rescheduleBoundary() {
        integration.cancelScheduledBoundary()
        let now = timeSource.snapshot()
        if let remaining = engine.snapshot.remainingSeconds, remaining > 0 {
            integration.scheduleBoundary(after: remaining) { [weak self] in
                self?.timerFired()
            }
        } else if engine.snapshot.phase == .awaitingConfirmation,
            let dayEnd = engine.snapshot.dayEnd
        {
            integration.scheduleBoundary(after: max(0.05, dayEnd.timeIntervalSince(now.date))) {
                [weak self] in
                self?.timerFired()
            }
        }
    }

    private func process(_ effects: [TimerEffect]) {
        guard let effect = effects.last else { return }
        switch effect {
        case .focusCompleted(let number):
            signalHandler(.focusCompleted(number: number))
        case .restCompleted(let number):
            signalHandler(.restCompleted(number: number))
        case .dayFinished:
            signalHandler(.dayFinished)
        }
    }

    private func stage(for phase: TimerSessionPhase) -> SessionStage {
        switch phase {
        case .ready: .ready
        case .focus: .focus
        case .paused: .paused
        case .rest: .rest
        case .awaitingConfirmation: .awaitingConfirmation
        case .finished: .finished
        }
    }
}
