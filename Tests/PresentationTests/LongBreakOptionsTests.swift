import SessionCoordinator
import SwiftUI
import XCTest

@testable import Presentation

@MainActor
final class LongBreakOptionsTests: XCTestCase {
    func testDraftRecalculatesWithoutChangingSelection() {
        var draft = DailyProgramDraft()
        draft.longBreakAfter = 2
        let initial = SessionCoordinator.longBreakOptions(for: draft.optionsRequest)
        XCTAssertEqual(initial.options[1].timeLabel, "С 10:40")
        draft.focusMinutes = 45
        let changed = SessionCoordinator.longBreakOptions(for: draft.optionsRequest)
        XCTAssertEqual(changed.options[1].timeLabel, "С 10:50")
        XCTAssertEqual(draft.longBreakAfter, 2)
        draft.startMinutes = 570
        draft.restMinutes = 15
        XCTAssertEqual(
            SessionCoordinator.longBreakOptions(for: draft.optionsRequest).options[1].timeLabel, "С 11:15")
        draft.focusMinutes = Int.max
        let invalid = SessionCoordinator.longBreakOptions(for: draft.optionsRequest)
        XCTAssertTrue(invalid.options.isEmpty)
        XCTAssertNotNil(invalid.errorMessage)
    }

    func testUnavailableSelectionResetsAndDoesNotReturnWhenDayExpands() {
        var draft = DailyProgramDraft()
        draft.longBreakAfter = 7
        draft.dayHours = 4
        let snapshot = SessionCoordinator.longBreakOptions(for: draft.optionsRequest)
        draft.reconcileBreakSelection(with: snapshot)
        let view = DailyProgramView(
            draft: .constant(draft), endTime: "—", breakOptions: snapshot, save: {}, cancel: {})
        XCTAssertFalse(view.isSaveEnabled)
        XCTAssertNil(view.selectedBreakNumber)
        XCTAssertNil(draft.longBreakAfter)
        draft.dayHours = 8
        draft.reconcileBreakSelection(with: SessionCoordinator.longBreakOptions(for: draft.optionsRequest))
        XCTAssertNil(draft.longBreakAfter)
        XCTAssertEqual(snapshot.options[0].accessibilityDescription, "Длинный перерыв после работы №1, С 09:40")
    }

    func testDisabledSelectionIsRejectedUntilAnAvailableTimeIsChosen() {
        var draft = DailyProgramDraft()
        draft.longBreakAfter = nil
        draft.dayHours = 4
        let snapshot = SessionCoordinator.longBreakOptions(for: draft.optionsRequest)
        let view = DailyProgramView(
            draft: Binding(get: { draft }, set: { draft = $0 }), endTime: "—",
            breakOptions: snapshot, save: {}, cancel: {})
        XCTAssertNil(snapshot.options.first { $0.afterFocusNumber == 7 })
        XCTAssertEqual(snapshot.options.first { $0.afterFocusNumber == 4 }?.isAvailable, false)
        view.selectBreak(after: 4)
        XCTAssertNil(draft.longBreakAfter)
        view.selectBreak(after: 7)
        XCTAssertNil(draft.longBreakAfter)
        view.selectBreak(after: 2)
        XCTAssertEqual(draft.longBreakAfter, 2)
        let selected = DailyProgramView(
            draft: .constant(draft), endTime: "—", breakOptions: snapshot, save: {}, cancel: {})
        XCTAssertTrue(selected.isSaveEnabled)
    }

    func testThirteenFortyResetsToPlaceholderInsteadOfTwelveForty() {
        var draft = DailyProgramDraft()
        draft.longBreakAfter = 5
        let initial = DailyProgramView(
            draft: .constant(draft), endTime: "—",
            breakOptions: SessionCoordinator.longBreakOptions(for: draft.optionsRequest), save: {}, cancel: {})
        XCTAssertEqual(initial.breakMenuTitle, "С 13:40")
        draft.dayHours = 4
        let snapshot = SessionCoordinator.longBreakOptions(for: draft.optionsRequest)
        draft.reconcileBreakSelection(with: snapshot)
        let shortened = DailyProgramView(
            draft: .constant(draft), endTime: "—", breakOptions: snapshot, save: {}, cancel: {})
        XCTAssertNil(draft.longBreakAfter)
        XCTAssertEqual(shortened.breakMenuTitle, "Выберите время")
        XCTAssertNotNil(shortened.breakErrorMessage)
        XCTAssertNil(snapshot.options.first { $0.afterFocusNumber == 5 })
    }

    func testNoAvailableOptionsStillShowsDisabledTimes() {
        let snapshot = SessionCoordinator.longBreakOptions(
            for: .init(
                startMinutes: 780, dayHours: 10, focusMinutes: 120, restMinutes: 35, durationMinutes: 240,
                otherOverrides: [.init(afterFocusNumber: 1, durationMinutes: 240)]))
        XCTAssertFalse(snapshot.options.isEmpty)
        XCTAssertFalse(snapshot.options.contains(where: \.isAvailable))
        XCTAssertNil(snapshot.errorMessage)
    }
}
