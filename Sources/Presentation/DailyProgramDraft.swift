/// Только редактируемые значения эталонного интерфейса, без хранения и правил сессии.
struct DailyProgramDraft: Equatable {
    static let allowedDayHours = [4, 6, 8, 10]
    static let allowedWorkNumbers = Array(1...12)

    var startMinutes = 540
    var dayHours = 8
    var focusMinutes = 40
    var restMinutes = 20
    var longBreakMinutes = 60
    var longBreakAfter = 4

    var hasAllowedDayHours: Bool {
        Self.allowedDayHours.contains(dayHours)
    }

    static var allowedDayHoursDescription: String {
        let initialHours = allowedDayHours.dropLast().map(String.init).joined(separator: ", ")
        guard let finalHours = allowedDayHours.last else { return "" }
        return "\(initialHours) или \(finalHours)"
    }
}
