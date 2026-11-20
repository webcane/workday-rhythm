import XCTest

@testable import Presentation

final class DesignButtonTests: XCTestCase {
    @MainActor
    func testLoadingButtonRejectsRepeatedAction() {
        XCTAssertFalse(DesignButton.shouldPerformAction(isLoading: true))
        XCTAssertTrue(DesignButton.shouldPerformAction(isLoading: false))
    }
}
