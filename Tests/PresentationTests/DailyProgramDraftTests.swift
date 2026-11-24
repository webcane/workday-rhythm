import SessionCoordinator
import XCTest

@testable import Presentation

final class DailyProgramDraftTests: XCTestCase {
    func testAllowedDayHoursHaveExpectedOptions() {
        XCTAssertEqual(DailyProgramDraft.allowedDayHours, [4, 6, 8, 10])
    }

    func testDraftAndRulersUseCoordinatorRulesSnapshot() {
        let rules = SessionCoordinator.defaultDailyProgramRules
        let draft = DailyProgramDraft(rules: rules)

        XCTAssertEqual(draft.startMinutes, rules.initialStartMinutes)
        XCTAssertEqual(draft.dayHours, rules.initialDayHours)
        XCTAssertEqual(RulerScale.startTime(for: rules).range, rules.startMinutes.range)
        XCTAssertEqual(RulerScale.startTime(for: rules).step, rules.startMinutes.step)
        XCTAssertEqual(RulerScale.focus(for: rules).range, rules.focusDurationMinutes)
        XCTAssertEqual(RulerScale.rest(for: rules).range, rules.restDurationMinutes)
        XCTAssertEqual(RulerScale.longBreak(for: rules).range, rules.restOverrideDurationMinutes)
    }

    func testInitialDayHoursAreAllowed() {
        XCTAssertTrue(DailyProgramDraft().hasAllowedDayHours)
    }

    func testDayHoursOutsideAllowedOptionsAreRejected() {
        var draft = DailyProgramDraft()

        draft.dayHours = 12

        XCTAssertFalse(draft.hasAllowedDayHours)
    }

    @MainActor
    func testSaveIsEnabledOnlyForValidIdleAvailableDraft() {
        var draft = DailyProgramDraft()
        let view = DailyProgramView(
            draft: .constant(draft), endTime: "18:00",
            breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest),
            isSaveAvailable: true, save: {}, cancel: {})
        XCTAssertTrue(view.isSaveEnabled)

        draft.focusMinutes = 42
        let invalidView = DailyProgramView(
            draft: .constant(draft), endTime: "18:00",
            breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest),
            isSaveAvailable: true, save: {}, cancel: {})
        XCTAssertFalse(invalidView.isSaveEnabled)

        let unavailableView = DailyProgramView(
            draft: .constant(.init()), endTime: "18:00",
            breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest),
            isSaveAvailable: false, save: {}, cancel: {})
        XCTAssertFalse(unavailableView.isSaveEnabled)

        let savingView = DailyProgramView(
            draft: .constant(.init()), endTime: "18:00",
            breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest),
            isSaving: true, save: {}, cancel: {})
        XCTAssertFalse(savingView.isSaveEnabled)
    }
}
