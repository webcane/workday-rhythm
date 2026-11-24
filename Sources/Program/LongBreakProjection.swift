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
        guard (480...780).contains(input.startMinutes), input.startMinutes.isMultiple(of: 30),
            [4, 6, 8, 10].contains(input.dayHours),
            (20...240).contains(input.durationMinutes), input.otherOverrides.count <= 1,
            input.defaults.count == WorkdayIntervalKind.allCases.count
        else { throw ValidationError.invalidParameters }
        var durations: [WorkdayIntervalKind: Int] = [:]
        for setting in input.defaults {
            guard durations.updateValue(setting.durationMinutes, forKey: setting.kind) == nil else {
                throw ValidationError.invalidParameters
            }
        }
        guard let focus = durations[.focus], (10...120).contains(focus),
            let rest = durations[.rest], (5...35).contains(rest)
        else { throw ValidationError.invalidParameters }
        for override in input.otherOverrides {
            guard override.afterFocusNumber > 0, (20...240).contains(override.durationMinutes) else {
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
