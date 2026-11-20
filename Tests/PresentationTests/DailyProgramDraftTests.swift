import XCTest

@testable import Presentation

final class DailyProgramDraftTests: XCTestCase {
    func testAllowedDayHoursHaveExpectedOptions() {
        XCTAssertEqual(DailyProgramDraft.allowedDayHours, [4, 6, 8, 10])
    }

    func testInitialDayHoursAreAllowed() {
        XCTAssertTrue(DailyProgramDraft().hasAllowedDayHours)
    }

    func testAllowedWorkNumbersCoverReferenceProgramOptions() {
        XCTAssertEqual(DailyProgramDraft.allowedWorkNumbers, Array(1...12))
    }

    func testDayHoursOutsideAllowedOptionsAreRejected() {
        var draft = DailyProgramDraft()

        draft.dayHours = 12

        XCTAssertFalse(draft.hasAllowedDayHours)
    }
}
