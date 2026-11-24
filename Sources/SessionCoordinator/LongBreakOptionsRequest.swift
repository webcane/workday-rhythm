/// Редактируемые параметры формы, не связанные с хранением или активной сессией.
public struct LongBreakOptionsRequest: Equatable {
    public struct AssignedRest: Equatable {
        public let afterFocusNumber: Int
        public let durationMinutes: Int

        public init(afterFocusNumber: Int, durationMinutes: Int) {
            self.afterFocusNumber = afterFocusNumber
            self.durationMinutes = durationMinutes
        }
    }

    public let otherOverrides: [AssignedRest]
    public let startMinutes: Int
    public let dayHours: Int
    public let focusMinutes: Int
    public let restMinutes: Int
    public let durationMinutes: Int

    public init(
        startMinutes: Int, dayHours: Int, focusMinutes: Int, restMinutes: Int, durationMinutes: Int,
        otherOverrides: [AssignedRest] = []
    ) {
        self.startMinutes = startMinutes
        self.dayHours = dayHours
        self.focusMinutes = focusMinutes
        self.restMinutes = restMinutes
        self.durationMinutes = durationMinutes
        self.otherOverrides = otherOverrides
    }
}
