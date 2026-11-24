/// Доменные ограничения и начальные значения программы рабочего дня.
public struct DailyProgramRules: Equatable, Sendable {
    public struct SteppedRange: Equatable, Sendable {
        public let range: ClosedRange<Int>
        public let step: Int

        public init(range: ClosedRange<Int>, step: Int) {
            self.range = range
            self.step = step
        }

        public func contains(_ value: Int) -> Bool {
            range.contains(value) && (value - range.lowerBound).isMultiple(of: step)
        }
    }

    public static let standard = DailyProgramRules(
        startMinutes: .init(range: 480...780, step: 30),
        allowedDayHours: [4, 6, 8, 10],
        focusDurationMinutes: 10...120,
        restDurationMinutes: 5...35,
        restOverrideDurationMinutes: 20...240,
        maximumRestOverrides: 2,
        initialStartMinutes: 540,
        initialDayHours: 8,
        initialFocusDurationMinutes: 40,
        initialRestDurationMinutes: 20
    )

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

    public init(
        startMinutes: SteppedRange,
        allowedDayHours: [Int],
        focusDurationMinutes: ClosedRange<Int>,
        restDurationMinutes: ClosedRange<Int>,
        restOverrideDurationMinutes: ClosedRange<Int>,
        maximumRestOverrides: Int,
        initialStartMinutes: Int,
        initialDayHours: Int,
        initialFocusDurationMinutes: Int,
        initialRestDurationMinutes: Int
    ) {
        self.startMinutes = startMinutes
        self.allowedDayHours = allowedDayHours
        self.focusDurationMinutes = focusDurationMinutes
        self.restDurationMinutes = restDurationMinutes
        self.restOverrideDurationMinutes = restOverrideDurationMinutes
        self.maximumRestOverrides = maximumRestOverrides
        self.initialStartMinutes = initialStartMinutes
        self.initialDayHours = initialDayHours
        self.initialFocusDurationMinutes = initialFocusDurationMinutes
        self.initialRestDurationMinutes = initialRestDurationMinutes
    }

    public func durationRange(for kind: WorkdayIntervalKind) -> ClosedRange<Int> {
        switch kind {
        case .focus: focusDurationMinutes
        case .rest: restDurationMinutes
        }
    }
}
