import Foundation
import MacIntegration
import SessionCoordinator
import SettingsStore
import XCTest

@testable import Presentation

@MainActor
final class SettingsPreviewViewTests: XCTestCase {
    func testSuccessfulSaveLogsProgramAppliesItAndCloses() throws {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        var messages: [String] = []
        var closeCount = 0
        let view = SettingsPreviewView(
            coordinator: context.coordinator,
            close: { closeCount += 1 },
            log: { messages.append($0) })
        let settings = DailyProgramSettings(
            startMinutes: 570,
            dayHours: 8,
            focusMinutes: 45,
            restMinutes: 15,
            longBreakMinutes: 60,
            longBreakAfter: 4)

        let error = view.save(settings)

        XCTAssertNil(error)
        XCTAssertEqual(context.coordinator.programSettings, settings)
        XCTAssertEqual(closeCount, 1)
        XCTAssertEqual(messages.count, 1)
        XCTAssertTrue(messages[0].contains("Сохранено"))
        XCTAssertTrue(messages[0].contains("начало 09:30"))
        XCTAssertTrue(messages[0].contains("фокусирование 45 мин"))
    }

    func testInvalidSaveDoesNotLogSuccessOrClose() {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let original = context.coordinator.programSettings
        var messages: [String] = []
        var closeCount = 0
        let view = SettingsPreviewView(
            coordinator: context.coordinator,
            close: { closeCount += 1 },
            log: { messages.append($0) })
        let invalid = DailyProgramSettings(
            startMinutes: original.startMinutes,
            dayHours: original.dayHours,
            focusMinutes: 9,
            restMinutes: original.restMinutes,
            longBreakMinutes: original.longBreakMinutes,
            longBreakAfter: original.longBreakAfter)

        XCTAssertNotNil(view.save(invalid))
        XCTAssertEqual(context.coordinator.programSettings, original)
        XCTAssertEqual(closeCount, 0)
        XCTAssertTrue(messages.isEmpty)
    }

    func testCancelLogsWithoutSavingAndCloses() {
        let context = makeContext()
        defer { context.defaults.removePersistentDomain(forName: context.suiteName) }
        let original = context.coordinator.programSettings
        var messages: [String] = []
        var closeCount = 0
        let view = SettingsPreviewView(
            coordinator: context.coordinator,
            close: { closeCount += 1 },
            log: { messages.append($0) })

        view.logChange("Отдых", value: "25 мин")
        view.cancelEditing()

        XCTAssertEqual(context.coordinator.programSettings, original)
        XCTAssertEqual(closeCount, 1)
        XCTAssertEqual(messages, ["[Настройки] Отдых: 25 мин", "[Настройки] Изменения отменены"])
    }

    private func makeContext() -> TestContext {
        let suiteName = "SettingsPreviewViewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        let coordinator = SessionCoordinator(
            settings: SettingsStore(defaults: defaults),
            integration: SettingsTestMacIntegration())
        return TestContext(suiteName: suiteName, defaults: defaults, coordinator: coordinator)
    }
}

@MainActor
private struct TestContext {
    let suiteName: String
    let defaults: UserDefaults
    let coordinator: SessionCoordinator
}

@MainActor
private final class SettingsTestMacIntegration: MacIntegrating {
    func startObserving(_ handler: @escaping (MacSystemEvent) -> Void) {}
    func stopObserving() {}
    func scheduleBoundary(after seconds: TimeInterval, handler: @escaping () -> Void) {}
    func cancelScheduledBoundary() {}
}
