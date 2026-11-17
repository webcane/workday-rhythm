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

    func testDisplayExtendsBeyondSelectionBoundsWithoutMakingThemSelectable() {
        let scale = RulerScale.startTime
        let ticks = scale.displayValues(around: 480, visibleSteps: 20)
        XCTAssertTrue(ticks.contains(0))
        XCTAssertEqual(scale.formatted(0), "00:00")
        XCTAssertTrue(ticks.contains(810))
        XCTAssertFalse(scale.contains(0))
        XCTAssertFalse(scale.contains(810))
        XCTAssertTrue(RulerScale.rest.displayValues(around: 5, visibleSteps: 20).contains(-5))
        XCTAssertFalse(RulerScale.rest.hasLabel(at: -5))
        XCTAssertTrue(scale.displayValues(around: 780, visibleSteps: 20).allSatisfy { (0...1440).contains($0) })
    }

    func testDraggingMovesByStepsAndStopsAtBothSelectionBounds() {
        let scale = RulerScale.startTime
        XCTAssertEqual(scale.value(afterDragging: 540, translation: -32, tickSpacing: 32), 570)
        XCTAssertEqual(scale.value(afterDragging: 540, translation: 32, tickSpacing: 32), 510)
        XCTAssertEqual(scale.value(afterDragging: 480, translation: 1000, tickSpacing: 32), 480)
        XCTAssertEqual(scale.value(afterDragging: 780, translation: -1000, tickSpacing: 32), 780)
        XCTAssertEqual(scale.clampedTranslation(from: 480, translation: 1000, tickSpacing: 32), 0)
        XCTAssertEqual(scale.clampedTranslation(from: 780, translation: -1000, tickSpacing: 32), 0)
    }

    func testInvalidDragGeometryPreservesNearestValidSelection() {
        let scale = RulerScale.focus
        XCTAssertEqual(scale.value(afterDragging: 42, translation: .nan, tickSpacing: 32), 40)
        XCTAssertEqual(scale.value(afterDragging: 42, translation: 32, tickSpacing: 0), 40)
        XCTAssertEqual(scale.value(afterDragging: 42, translation: 32, tickSpacing: .infinity), 40)
    }

    func testChevronStepsUseScaleStepAndStopAtBounds() {
        XCTAssertEqual(RulerScale.startTime.steppedValue(from: 540, by: -1), 510)
        XCTAssertEqual(RulerScale.startTime.steppedValue(from: 540, by: 1), 570)
        for scale in RulerScale.allCases {
            let minimum = scale.range.lowerBound
            let maximum = scale.range.upperBound
            XCTAssertEqual(scale.steppedValue(from: minimum, by: -1), minimum)
            XCTAssertEqual(scale.steppedValue(from: maximum, by: 1), maximum)
            XCTAssertEqual(scale.steppedValue(from: minimum, by: 1), minimum + scale.step)
            XCTAssertEqual(scale.steppedValue(from: maximum, by: -1), maximum - scale.step)
        }
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
