/// Только редактируемые значения эталонного интерфейса, без хранения и правил сессии.
struct DailyProgramDraft: Equatable {
    var startMinutes = 540
    var dayHours = 8
    var focusMinutes = 40
    var restMinutes = 20
    var longBreakMinutes = 60
    var longBreakAfter = 4
}
