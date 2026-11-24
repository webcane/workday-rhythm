import Program
import XCTest

final class LongBreakProjectionTests: XCTestCase {
    func testRecalculationAndMidnight() throws {
        func project(start: Int = 540, hours: Int = 8, rest: Int = 20, focus: Int = 40)
            throws -> [LongBreakProjection.Option]
        {
            try LongBreakProjection.options(
                for: .init(
                    startMinutes: start, dayHours: hours,
                    defaults: [.init(kind: .focus, durationMinutes: focus), .init(kind: .rest, durationMinutes: rest)],
                    durationMinutes: 60))
        }
        XCTAssertEqual(Array(try project(focus: 45).prefix(3).map(\.startMinutes)), [585, 650, 715])
        XCTAssertEqual(Array(try project(rest: 15).prefix(3).map(\.startMinutes)), [580, 635, 690])
        XCTAssertEqual(try project(start: 570).first?.startMinutes, 610)
        XCTAssertTrue(
            try project(start: 780, hours: 10).filter(\.isAvailable).allSatisfy { $0.startMinutes + 60 + 40 <= 1440 })
        XCTAssertEqual(try project(), try project())
    }

    func testNegativeDeltaAndDuplicateKinds() throws {
        let options = try LongBreakProjection.options(
            for: .init(
                startMinutes: 540, dayHours: 8,
                defaults: [.init(kind: .focus, durationMinutes: 40), .init(kind: .rest, durationMinutes: 35)],
                durationMinutes: 20))
        XCTAssertTrue(options.filter(\.isAvailable).allSatisfy { $0.startMinutes + 20 <= 1005 })
        XCTAssertThrowsError(
            try LongBreakProjection.options(
                for: .init(
                    startMinutes: 540, dayHours: 8,
                    defaults: [.init(kind: .focus, durationMinutes: 40), .init(kind: .focus, durationMinutes: 20)],
                    durationMinutes: 60)))
    }
    func testNominalTimesAndOccupiedPosition() throws {
        let ordinary = try options()
        XCTAssertEqual(Array(ordinary.prefix(3).map(\.startMinutes)), [580, 640, 700])
        let shifted = try options(other: [.init(afterFocusNumber: 1, durationMinutes: 60)])
        XCTAssertEqual(shifted.first?.afterFocusNumber, 1)
        XCTAssertEqual(shifted.first?.isAvailable, false)
        XCTAssertEqual(shifted.first(where: \.isAvailable)?.afterFocusNumber, 2)
        XCTAssertEqual(shifted.first(where: \.isAvailable)?.startMinutes, 680)
    }

    func testBoundaryAndLunchExample() throws {
        let short = try options(hours: 4)
        XCTAssertEqual(short.last(where: \.isAvailable)?.afterFocusNumber, 3)
        XCTAssertEqual(short.last(where: \.isAvailable)?.startMinutes, 700)
        XCTAssertEqual(short.first { $0.afterFocusNumber == 4 }?.isAvailable, false)
        XCTAssertNil(short.first { $0.afterFocusNumber == 5 })
        let lunch = try options(duration: 80)
        XCTAssertEqual(lunch.first { $0.afterFocusNumber == 4 }?.startMinutes, 760)
        XCTAssertEqual(lunch.last(where: \.isAvailable)?.afterFocusNumber, 7)
        let afterLunch = try options(duration: 20, other: [.init(afterFocusNumber: 4, durationMinutes: 80)])
        XCTAssertEqual(afterLunch.last(where: \.isAvailable)?.afterFocusNumber, 7)
        XCTAssertEqual(afterLunch.last(where: \.isAvailable)?.startMinutes, 1000)
        XCTAssertEqual(afterLunch.last?.afterFocusNumber, 8)
        XCTAssertEqual(afterLunch.last?.startMinutes, 1060)
        XCTAssertEqual(afterLunch.last?.isAvailable, false)
    }

    func testShorteningDayRemovesTimesBeyondEndAndRequiresFollowingFocus() throws {
        let long = try options(hours: 8)
        let short = try options(hours: 4)
        XCTAssertGreaterThan(long.count, short.count)
        XCTAssertEqual(long.first { $0.afterFocusNumber == 7 }?.isAvailable, true)
        XCTAssertNil(short.first { $0.afterFocusNumber == 7 })
        XCTAssertTrue(short.allSatisfy { $0.startMinutes < 820 })
        XCTAssertTrue(short.filter(\.isAvailable).allSatisfy { $0.startMinutes + 60 + 40 <= 820 })
    }

    func testRejectsExternalExtremesAndMissingDefaults() {
        for value in [Int.min, Int.max, 0] {
            XCTAssertThrowsError(try options(focus: value))
            XCTAssertThrowsError(try options(duration: value))
        }
        XCTAssertThrowsError(
            try LongBreakProjection.options(
                for: .init(startMinutes: 540, dayHours: 8, defaults: [], durationMinutes: 60)))
    }

    func testFollowingFocusMayEndExactlyAtDayBoundary() throws {
        let projected = try LongBreakProjection.options(
            for: .init(
                startMinutes: 540, dayHours: 4,
                defaults: [.init(kind: .focus, durationMinutes: 45), .init(kind: .rest, durationMinutes: 20)],
                durationMinutes: 60))
        let last = projected.last(where: \.isAvailable)
        XCTAssertEqual(last?.startMinutes, 715)
        XCTAssertEqual(last.map { $0.startMinutes + 60 + 45 }, 820)
    }

    private func options(
        hours: Int = 8, focus: Int = 40, duration: Int = 60,
        other: [RestDurationOverride] = []
    ) throws -> [LongBreakProjection.Option] {
        try LongBreakProjection.options(
            for: .init(
                startMinutes: 540, dayHours: hours,
                defaults: [.init(kind: .focus, durationMinutes: focus), .init(kind: .rest, durationMinutes: 20)],
                durationMinutes: duration, otherOverrides: other))
    }
}
