import XCTest

@testable import Presentation

final class RulerScaleTests: XCTestCase {
    func testDurationStepsAndBoundaries() {
        for scale in [RulerScale.focus, .rest, .longBreak] {
            XCTAssertEqual(scale.step, 5)
            XCTAssertEqual(scale.values.first, scale.range.lowerBound)
            XCTAssertEqual(scale.values.last, scale.range.upperBound)
            XCTAssertFalse(scale.contains(scale.range.lowerBound + 1))
            XCTAssertFalse(scale.contains(scale.range.lowerBound - 5))
            XCTAssertFalse(scale.contains(scale.range.upperBound + 5))
        }
    }

    func testStartTimeSupportsEveryHalfHourFromEightToThirteen() {
        XCTAssertEqual(RulerScale.startTime.values, [480, 510, 540, 570, 600, 630, 660, 690, 720, 750, 780])
        XCTAssertEqual(RulerScale.startTime.formatted(480), "08:00")
        XCTAssertEqual(RulerScale.startTime.formatted(780), "13:00")
        XCTAssertFalse(RulerScale.startTime.contains(495))
    }

    func testLabelsIncludeBothBoundsAndWholeHoursForStartTime() {
        for scale in RulerScale.allCases {
            let labels = scale.values.filter { scale.hasLabel(at: $0) }
            XCTAssertEqual(labels.first, scale.range.lowerBound)
            XCTAssertEqual(labels.last, scale.range.upperBound)
        }
        XCTAssertEqual(
            RulerScale.startTime.values.filter { RulerScale.startTime.hasLabel(at: $0) },
            [480, 540, 600, 660, 720, 780])
    }

    func testSelectionSnapsAndClampsExternalValuesWithoutOverflow() {
        let scale = RulerScale.focus
        XCTAssertEqual(scale.values[scale.nearestIndex(to: 42)], 40)
        XCTAssertEqual(scale.values[scale.nearestIndex(to: 43)], 45)
        XCTAssertEqual(scale.values[scale.nearestIndex(to: Int.min)], 10)
        XCTAssertEqual(scale.values[scale.nearestIndex(to: Int.max)], 120)
        XCTAssertFalse(scale.contains(42))
    }
}
