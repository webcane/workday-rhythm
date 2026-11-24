import XCTest

@testable import Program

final class DailyProgramRulesTests: XCTestCase {
    func testStandardRulesDescribeProgramBoundariesAndDefaults() {
        let rules = DailyProgramRules.standard

        XCTAssertTrue(rules.startMinutes.contains(480))
        XCTAssertTrue(rules.startMinutes.contains(780))
        XCTAssertFalse(rules.startMinutes.contains(495))
        XCTAssertEqual(rules.allowedDayHours, [4, 6, 8, 10])
        XCTAssertEqual(rules.focusDurationMinutes, 10...120)
        XCTAssertEqual(rules.restDurationMinutes, 5...35)
        XCTAssertEqual(rules.restOverrideDurationMinutes, 20...240)
        XCTAssertEqual(rules.maximumRestOverrides, 2)
        XCTAssertEqual(rules.initialFocusDurationMinutes, 40)
        XCTAssertEqual(rules.initialRestDurationMinutes, 20)
    }

    func testDailyProgramUsesStandardRulesForValidation() {
        let rules = DailyProgramRules.standard

        XCTAssertNoThrow(
            try DailyProgram(
                startMinutes: rules.startMinutes.range.lowerBound,
                dayHours: rules.allowedDayHours[0],
                defaults: [
                    .init(kind: .focus, durationMinutes: rules.focusDurationMinutes.lowerBound),
                    .init(kind: .rest, durationMinutes: rules.restDurationMinutes.lowerBound),
                ],
                restDurationOverrides: [
                    .init(afterFocusNumber: 1, durationMinutes: rules.restOverrideDurationMinutes.lowerBound),
                    .init(afterFocusNumber: 2, durationMinutes: rules.restOverrideDurationMinutes.upperBound),
                ]
            ))
    }
}
