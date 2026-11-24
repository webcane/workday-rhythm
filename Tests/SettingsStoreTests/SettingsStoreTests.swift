import Foundation
import XCTest

@testable import Program
@testable import SettingsStore

@MainActor
final class SettingsStoreTests: XCTestCase {
    func testUsesInitialProgramWhenValueIsMissingOrInvalid() {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        XCTAssertEqual(store.loadProgram(), .initial)

        defaults.set(Data("invalid".utf8), forKey: "dailyProgram")
        XCTAssertEqual(store.loadProgram(), .initial)
    }

    func testSavesAndLoadsProgramWithoutUsingStandardProfile() throws {
        let defaults = makeDefaults()
        let store = SettingsStore(defaults: defaults)
        let program = try DailyProgram(
            startMinutes: 600,
            dayHours: 6,
            defaults: [
                .init(kind: .focus, durationMinutes: 45),
                .init(kind: .rest, durationMinutes: 15),
            ],
            restDurationOverrides: [.init(afterFocusNumber: 3, durationMinutes: 60)]
        )

        try store.saveProgram(program)

        XCTAssertEqual(SettingsStore(defaults: defaults).loadProgram(), program)
    }

    func testSavesPromptDate() {
        let store = SettingsStore(defaults: makeDefaults())
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertNil(store.lastStartPromptDate())
        store.saveLastStartPromptDate(date)
        XCTAssertEqual(store.lastStartPromptDate(), date)
    }

    private func makeDefaults() -> UserDefaults {
        let name = "SettingsStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name)!
        defaults.removePersistentDomain(forName: name)
        return defaults
    }
}
