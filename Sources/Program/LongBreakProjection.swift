/// Чистая проекция черновика в номинальные позиции редактируемого отдыха.
public struct LongBreakProjection {
    public struct Input {
        public let startMinutes: Int
        public let dayHours: Int
        public let defaults: [WorkdayDefaults]
        public let durationMinutes: Int
        public let otherOverrides: [RestDurationOverride]

        public init(
            startMinutes: Int, dayHours: Int, defaults: [WorkdayDefaults],
            durationMinutes: Int, otherOverrides: [RestDurationOverride] = []
        ) {
            self.startMinutes = startMinutes
            self.dayHours = dayHours
            self.defaults = defaults
            self.durationMinutes = durationMinutes
            self.otherOverrides = otherOverrides
        }
    }

    public struct Option: Equatable {
        public let afterFocusNumber: Int
        public let startMinutes: Int
        public let isAvailable: Bool
    }

    public enum ValidationError: Error {
        case invalidParameters
    }

    public static func options(for input: Input) throws -> [Option] {
        let rules = DailyProgramRules.standard
        guard rules.startMinutes.contains(input.startMinutes),
            rules.allowedDayHours.contains(input.dayHours),
            rules.restOverrideDurationMinutes.contains(input.durationMinutes),
            input.otherOverrides.count < rules.maximumRestOverrides,
            input.defaults.count == WorkdayIntervalKind.allCases.count
        else { throw ValidationError.invalidParameters }
        var durations: [WorkdayIntervalKind: Int] = [:]
        for setting in input.defaults {
            guard durations.updateValue(setting.durationMinutes, forKey: setting.kind) == nil else {
                throw ValidationError.invalidParameters
            }
        }
        guard let focus = durations[.focus], rules.durationRange(for: .focus).contains(focus),
            let rest = durations[.rest], rules.durationRange(for: .rest).contains(rest)
        else { throw ValidationError.invalidParameters }
        for override in input.otherOverrides {
            guard override.afterFocusNumber > 0,
                rules.restOverrideDurationMinutes.contains(override.durationMinutes)
            else {
                throw ValidationError.invalidParameters
            }
        }
        let end =
            input.startMinutes + input.dayHours * 60 + input.durationMinutes - rest
            + input.otherOverrides.reduce(0) { $0 + $1.durationMinutes - rest }
        let limit = min(end, 1440)
        var time = input.startMinutes
        var number = 1
        var options: [Option] = []
        // Позиции за границей дня не входят в меню.
        while time + focus < limit {
            let breakStart = time + focus
            let assigned = input.otherOverrides.first { $0.afterFocusNumber == number }
            options.append(
                Option(
                    afterFocusNumber: number, startMinutes: breakStart,
                    isAvailable: assigned == nil && breakStart + input.durationMinutes + focus <= limit))
            time = breakStart + (assigned?.durationMinutes ?? rest)
            number += 1
        }
        return options
    }
}
