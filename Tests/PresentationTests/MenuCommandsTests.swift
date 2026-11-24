import XCTest

@testable import Presentation

final class MenuCommandsTests: XCTestCase {
    func testSettingsCommandCallsOnlySettingsHandler() async {
        await MainActor.run {
            var settingsCalls = 0
            var quitCalls = 0
            let commands = MenuCommands(
                showSettings: { settingsCalls += 1 },
                quit: { quitCalls += 1 }
            )

            commands.perform(#selector(MenuCommands.showSettings))

            XCTAssertEqual(settingsCalls, 1)
            XCTAssertEqual(quitCalls, 0)
        }
    }

    func testQuitCommandCallsOnlyQuitHandler() async {
        await MainActor.run {
            var settingsCalls = 0
            var quitCalls = 0
            let commands = MenuCommands(
                showSettings: { settingsCalls += 1 },
                quit: { quitCalls += 1 }
            )

            commands.perform(#selector(MenuCommands.quit))

            XCTAssertEqual(quitCalls, 1)
            XCTAssertEqual(settingsCalls, 0)
        }
    }

    func testSessionCommandsCallOnlyTheirHandlers() async {
        await MainActor.run {
            var calls: [String] = []
            let commands = MenuCommands(
                showSettings: {},
                quit: {},
                startDay: { calls.append("start") },
                pause: { calls.append("pause") },
                resume: { calls.append("resume") },
                continueAfterRest: { calls.append("continue") }
            )

            commands.perform(#selector(MenuCommands.startDay))
            commands.perform(#selector(MenuCommands.pause))
            commands.perform(#selector(MenuCommands.resume))
            commands.perform(#selector(MenuCommands.continueAfterRest))

            XCTAssertEqual(calls, ["start", "pause", "resume", "continue"])
        }
    }
}
