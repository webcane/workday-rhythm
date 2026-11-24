/// Варианты и ошибка номинального расчёта для интерфейса.
public struct LongBreakOptionsSnapshot: Equatable {
    public struct Option: Equatable, Identifiable {
        public let afterFocusNumber: Int
        public let startMinutes: Int
        public let isAvailable: Bool
        public var id: Int { afterFocusNumber }

        public init(afterFocusNumber: Int, startMinutes: Int, isAvailable: Bool = true) {
            self.afterFocusNumber = afterFocusNumber
            self.startMinutes = startMinutes
            self.isAvailable = isAvailable
        }
    }

    public let options: [Option]
    public let errorMessage: String?

    public init(options: [Option], errorMessage: String? = nil) {
        self.options = options
        self.errorMessage = errorMessage
    }
}
