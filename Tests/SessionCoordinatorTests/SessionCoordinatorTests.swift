import Foundation
import XCTest

@testable import MacIntegration
@testable import Program
@testable import SessionCoordinator
@testable import SettingsStore

@MainActor
final class SessionCoordinatorTests: XCTestCase {
    func testSaveAndBoundaryAreSerializedAndStaleBoundaryDoesNotDuplicateSignal() throws {
        let environment = makeEnvironment()
        var signals: [SessionSignal] = []
        let coordinator = environment.coordinator { signals.append($0) }
        coordinator.startDay()
        let staleBoundary = environment.integration.boundaryHandler
        XCTAssertNotNil(staleBoundary)

        environment.time.advance(minutes: 30)
        try coordinator.saveProgram(try program(focusMinutes: 20))
        XCTAssertEqual(signals, [.focusCompleted(number: 1)])
        XCTAssertEqual(coordinator.status.stage, .rest)

        staleBoundary?()
        XCTAssertEqual(signals, [.focusCompleted(number: 1)])
        XCTAssertGreaterThanOrEqual(environment.integration.cancelCount, 2)
    }

    func testRepeatedWakeProducesOneCurrentSignal() throws {
        let environment = makeEnvironment()
        var signals: [SessionSignal] = []
        let coordinator = environment.coordinator { signals.append($0) }
        coordinator.startDay()
        environment.time.advance(minutes: 75)

        environment.integration.emit(.wake)
        environment.integration.emit(.wake)

        XCTAssertEqual(signals, [.restCompleted(number: 1)])
        XCTAssertEqual(coordinator.status.stage, .awaitingConfirmation)
    }

    func testClockChangeKeepsRemainingDuration() {
        let environment = makeEnvironment()
        let coordinator = environment.coordinator()
        coordinator.startDay()
        environment.time.advance(minutes: 25)
        environment.time.date = environment.time.date.addingTimeInterval(3_600)

        environment.integration.emit(.clockChanged)

        XCTAssertEqual(coordinator.status.remainingSeconds, 15 * 60)
    }

    func testExitDropsSessionButKeepsSettings() throws {
        let environment = makeEnvironment()
        let saved = try program(focusMinutes: 45)
        let coordinator = environment.coordinator()
        try coordinator.saveProgram(saved)
        coordinator.startDay()
        XCTAssertEqual(coordinator.status.stage, .focus)

        coordinator.stopSession()
        XCTAssertEqual(coordinator.status.stage, .ready)

        let replacement = environment.coordinator()
        XCTAssertEqual(replacement.status.stage, .ready)
        XCTAssertEqual(replacement.program, saved)
    }

    private func makeEnvironment() -> Environment {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(
            from: DateComponents(year: 2026, month: 1, day: 1, hour: 9))!
        return Environment(
            time: FakeTimeSource(date: date),
            integration: FakeMacIntegration(),
            settings: SettingsStore(defaults: isolatedDefaults()),
            calendar: calendar
        )
    }

    private func isolatedDefaults() -> UserDefaults {
        let name = "SessionCoordinatorTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func program(focusMinutes: Int = 40) throws -> DailyProgram {
        try DailyProgram(
            startMinutes: 540,
            dayHours: 8,
            defaults: [
                .init(kind: .focus, durationMinutes: focusMinutes),
                .init(kind: .rest, durationMinutes: 20),
            ]
        )
    }
}

@MainActor
private struct Environment {
    let time: FakeTimeSource
    let integration: FakeMacIntegration
    let settings: SettingsStore
    let calendar: Calendar

    func coordinator(
        signalHandler: @escaping (SessionSignal) -> Void = { _ in }
    ) -> SessionCoordinator {
        SessionCoordinator(
            settings: settings,
            integration: integration,
            timeSource: time,
            calendarProvider: { calendar },
            signalHandler: signalHandler
        )
    }
}

@MainActor
private final class FakeTimeSource: SystemTimeProviding {
    var date: Date
    var elapsedSeconds: TimeInterval

    init(date: Date, elapsedSeconds: TimeInterval = 0) {
        self.date = date
        self.elapsedSeconds = elapsedSeconds
    }

    func snapshot() -> SystemTimeSnapshot {
        SystemTimeSnapshot(date: date, elapsedSeconds: elapsedSeconds)
    }

    func advance(minutes: Int) {
        let seconds = TimeInterval(minutes * 60)
        date = date.addingTimeInterval(seconds)
        elapsedSeconds += seconds
    }
}

@MainActor
private final class FakeMacIntegration: MacIntegrating {
    private var eventHandler: ((MacSystemEvent) -> Void)?
    var boundaryHandler: (() -> Void)?
    var cancelCount = 0

    func startObserving(_ handler: @escaping (MacSystemEvent) -> Void) {
        eventHandler = handler
    }

    func stopObserving() {
        eventHandler = nil
        cancelScheduledBoundary()
    }

    func scheduleBoundary(after seconds: TimeInterval, handler: @escaping () -> Void) {
        boundaryHandler = handler
    }

    func cancelScheduledBoundary() {
        cancelCount += 1
        boundaryHandler = nil
    }

    func emit(_ event: MacSystemEvent) {
        eventHandler?(event)
    }
}
