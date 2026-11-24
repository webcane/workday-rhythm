import XCTest

@testable import Program

final class DailyProgramTests: XCTestCase {
    func testInitialProgramAndEndUsingOverrideDelta() throws {
        XCTAssertEqual(DailyProgram.initial.duration(for: .focus), 40)
        XCTAssertEqual(DailyProgram.initial.duration(for: .rest), 20)

        let program = try makeProgram(
            restOverrides: [.init(afterFocusNumber: 4, durationMinutes: 60)])
        XCTAssertEqual(program.restDuration(afterFocusNumber: 3), 20)
        XCTAssertEqual(program.restDuration(afterFocusNumber: 4), 60)
        XCTAssertEqual(program.endMinutes, 17 * 60 + 40)
    }

    func testTwoOverridesAndNegativeDelta() throws {
        let twoLunches = try makeProgram(
            dayHours: 10,
            restOverrides: [
                .init(afterFocusNumber: 4, durationMinutes: 60),
                .init(afterFocusNumber: 8, durationMinutes: 60),
            ])
        XCTAssertEqual(twoLunches.endMinutes, 20 * 60 + 20)

        let shorterOverride = try makeProgram(
            restMinutes: 35,
            restOverrides: [.init(afterFocusNumber: 4, durationMinutes: 20)])
        XCTAssertEqual(shorterOverride.endMinutes, 16 * 60 + 45)
    }

    func testRejectsInvalidRangesAndMissingOrDuplicateKinds() throws {
        XCTAssertThrowsError(try makeProgram(startMinutes: 481))
        XCTAssertThrowsError(try makeProgram(dayHours: 5))
        XCTAssertThrowsError(try makeProgram(focusMinutes: 9))
        XCTAssertThrowsError(try makeProgram(restMinutes: 36))
        XCTAssertThrowsError(
            try DailyProgram(
                startMinutes: 540, dayHours: 8,
                defaults: [.init(kind: .focus, durationMinutes: 40)]))
        XCTAssertThrowsError(
            try DailyProgram(
                startMinutes: 540, dayHours: 8,
                defaults: [
                    .init(kind: .focus, durationMinutes: 40),
                    .init(kind: .focus, durationMinutes: 50),
                ]))
    }

    func testRejectsInvalidAndDuplicateOverrides() throws {
        XCTAssertThrowsError(
            try makeProgram(restOverrides: [.init(afterFocusNumber: 0, durationMinutes: 60)]))
        XCTAssertThrowsError(
            try makeProgram(restOverrides: [.init(afterFocusNumber: 4, durationMinutes: 241)]))
        XCTAssertThrowsError(
            try makeProgram(
                restOverrides: [
                    .init(afterFocusNumber: 4, durationMinutes: 60),
                    .init(afterFocusNumber: 4, durationMinutes: 80),
                ]))
        XCTAssertThrowsError(
            try makeProgram(
                restOverrides: [
                    .init(afterFocusNumber: 2, durationMinutes: 60),
                    .init(afterFocusNumber: 4, durationMinutes: 60),
                    .init(afterFocusNumber: 6, durationMinutes: 60),
                ]))
    }

    private func makeProgram(
        startMinutes: Int = 540,
        dayHours: Int = 8,
        focusMinutes: Int = 40,
        restMinutes: Int = 20,
        restOverrides: [RestDurationOverride] = []
    ) throws -> DailyProgram {
        try DailyProgram(
            startMinutes: startMinutes,
            dayHours: dayHours,
            defaults: [
                .init(kind: .focus, durationMinutes: focusMinutes),
                .init(kind: .rest, durationMinutes: restMinutes),
            ],
            restDurationOverrides: restOverrides
        )
    }
}
