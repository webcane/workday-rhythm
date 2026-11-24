import Program

/// Независимый от доменного target снимок ограничений для формы программы.
public struct DailyProgramRulesSnapshot: Equatable, Sendable {
    public struct SteppedRange: Equatable, Sendable {
        public let range: ClosedRange<Int>
        public let step: Int

        public init(range: ClosedRange<Int>, step: Int) {
            self.range = range
            self.step = step
        }
    }

    public let startMinutes: SteppedRange
    public let allowedDayHours: [Int]
    public let focusDurationMinutes: ClosedRange<Int>
    public let restDurationMinutes: ClosedRange<Int>
    public let restOverrideDurationMinutes: ClosedRange<Int>
    public let maximumRestOverrides: Int
    public let initialStartMinutes: Int
    public let initialDayHours: Int
    public let initialFocusDurationMinutes: Int
    public let initialRestDurationMinutes: Int

    public init(_ rules: DailyProgramRules) {
        startMinutes = .init(range: rules.startMinutes.range, step: rules.startMinutes.step)
        allowedDayHours = rules.allowedDayHours
        focusDurationMinutes = rules.focusDurationMinutes
        restDurationMinutes = rules.restDurationMinutes
        restOverrideDurationMinutes = rules.restOverrideDurationMinutes
        maximumRestOverrides = rules.maximumRestOverrides
        initialStartMinutes = rules.initialStartMinutes
        initialDayHours = rules.initialDayHours
        initialFocusDurationMinutes = rules.initialFocusDurationMinutes
        initialRestDurationMinutes = rules.initialRestDurationMinutes
    }
}
