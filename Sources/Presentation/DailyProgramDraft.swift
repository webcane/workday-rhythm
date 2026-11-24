import SessionCoordinator

/// Только редактируемые значения эталонного интерфейса, без хранения и правил сессии.
struct DailyProgramDraft: Equatable {
    static let allowedDayHours = [4, 6, 8, 10]

    var startMinutes = 540
    var dayHours = 8
    var focusMinutes = 40
    var restMinutes = 20
    var longBreakMinutes = 60
    var longBreakAfter: Int? = 4

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

    var hasAllowedDayHours: Bool {
        Self.allowedDayHours.contains(dayHours)
    }

    static var allowedDayHoursDescription: String {
        let initialHours = allowedDayHours.dropLast().map(String.init).joined(separator: ", ")
        guard let finalHours = allowedDayHours.last else { return "" }
        return "\(initialHours) или \(finalHours)"
    }
}
