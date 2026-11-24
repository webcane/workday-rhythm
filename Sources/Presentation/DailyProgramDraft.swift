import SessionCoordinator

/// Только редактируемые значения эталонного интерфейса, без хранения и правил сессии.
struct DailyProgramDraft: Equatable {
    var startMinutes: Int
    var dayHours: Int
    var focusMinutes: Int
    var restMinutes: Int
    var longBreakMinutes = 60
    var longBreakAfter: Int? = 4

    init(rules: DailyProgramRulesSnapshot = SessionCoordinator.defaultDailyProgramRules) {
        startMinutes = rules.initialStartMinutes
        dayHours = rules.initialDayHours
        focusMinutes = rules.initialFocusDurationMinutes
        restMinutes = rules.initialRestDurationMinutes
    }

    init(settings: DailyProgramSettings) {
        startMinutes = settings.startMinutes
        dayHours = settings.dayHours
        focusMinutes = settings.focusMinutes
        restMinutes = settings.restMinutes
        longBreakMinutes = settings.longBreakMinutes
        longBreakAfter = settings.longBreakAfter
    }

    mutating func reconcileBreakSelection(with snapshot: LongBreakOptionsSnapshot) {
        guard snapshot.options.contains(where: { $0.isAvailable && $0.afterFocusNumber == longBreakAfter }) else {
            longBreakAfter = nil
            return
        }
    }

    mutating func selectBreak(after number: Int?, in snapshot: LongBreakOptionsSnapshot) {
        guard let number else {
            longBreakAfter = nil
            return
        }
        guard snapshot.options.contains(where: { $0.isAvailable && $0.afterFocusNumber == number }) else { return }
        longBreakAfter = number
    }

    var optionsRequest: LongBreakOptionsRequest {
        .init(
            startMinutes: startMinutes, dayHours: dayHours, focusMinutes: focusMinutes,
            restMinutes: restMinutes, durationMinutes: longBreakMinutes)
    }

    var settings: DailyProgramSettings {
        .init(
            startMinutes: startMinutes,
            dayHours: dayHours,
            focusMinutes: focusMinutes,
            restMinutes: restMinutes,
            longBreakMinutes: longBreakMinutes,
            longBreakAfter: longBreakAfter
        )
    }

    func hasAllowedDayHours(in rules: DailyProgramRulesSnapshot) -> Bool {
        rules.allowedDayHours.contains(dayHours)
    }

    var hasAllowedDayHours: Bool {
        hasAllowedDayHours(in: SessionCoordinator.defaultDailyProgramRules)
    }

    static var allowedDayHours: [Int] {
        SessionCoordinator.defaultDailyProgramRules.allowedDayHours
    }

    func allowedDayHoursDescription(in rules: DailyProgramRulesSnapshot) -> String {
        let initialHours = rules.allowedDayHours.dropLast().map(String.init).joined(separator: ", ")
        guard let finalHours = rules.allowedDayHours.last else { return "" }
        return "\(initialHours) или \(finalHours)"
    }
}
