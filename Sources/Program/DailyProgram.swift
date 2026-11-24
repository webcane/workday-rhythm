import Foundation

/// Проверенные настройки одного рабочего дня.
public struct DailyProgram: Codable, Equatable, Sendable {
    public enum ValidationError: Error, Equatable {
        case invalidStartMinutes
        case invalidDayHours
        case missingDefault(WorkdayIntervalKind)
        case duplicateDefault(WorkdayIntervalKind)
        case invalidDuration(WorkdayIntervalKind)
        case tooManyRestOverrides
        case invalidRestOverride
        case duplicateRestOverride(Int)
    }

    public static let initial = DailyProgram(
        validatedStartMinutes: DailyProgramRules.standard.initialStartMinutes,
        dayHours: DailyProgramRules.standard.initialDayHours,
        defaults: [
            WorkdayDefaults(kind: .focus, durationMinutes: DailyProgramRules.standard.initialFocusDurationMinutes),
            WorkdayDefaults(kind: .rest, durationMinutes: DailyProgramRules.standard.initialRestDurationMinutes),
        ],
        restDurationOverrides: []
    )

    public let startMinutes: Int
    public let dayHours: Int
    public let defaults: [WorkdayDefaults]
    public let restDurationOverrides: [RestDurationOverride]

    public init(
        startMinutes: Int,
        dayHours: Int,
        defaults: [WorkdayDefaults],
        restDurationOverrides: [RestDurationOverride] = []
    ) throws {
        let rules = DailyProgramRules.standard
        guard rules.startMinutes.contains(startMinutes) else {
            throw ValidationError.invalidStartMinutes
        }
        guard rules.allowedDayHours.contains(dayHours) else {
            throw ValidationError.invalidDayHours
        }
        guard restDurationOverrides.count <= rules.maximumRestOverrides else {
            throw ValidationError.tooManyRestOverrides
        }

        var durations: [WorkdayIntervalKind: Int] = [:]
        for setting in defaults {
            guard durations.updateValue(setting.durationMinutes, forKey: setting.kind) == nil else {
                throw ValidationError.duplicateDefault(setting.kind)
            }
        }
        for kind in WorkdayIntervalKind.allCases where durations[kind] == nil {
            throw ValidationError.missingDefault(kind)
        }
        guard let focusDuration = durations[.focus], rules.durationRange(for: .focus).contains(focusDuration) else {
            throw ValidationError.invalidDuration(.focus)
        }
        guard let restDuration = durations[.rest], rules.durationRange(for: .rest).contains(restDuration) else {
            throw ValidationError.invalidDuration(.rest)
        }

        var assignedFocusNumbers = Set<Int>()
        for restOverride in restDurationOverrides {
            guard restOverride.afterFocusNumber > 0,
                rules.restOverrideDurationMinutes.contains(restOverride.durationMinutes)
            else {
                throw ValidationError.invalidRestOverride
            }
            guard assignedFocusNumbers.insert(restOverride.afterFocusNumber).inserted else {
                throw ValidationError.duplicateRestOverride(restOverride.afterFocusNumber)
            }
        }

        self.init(
            validatedStartMinutes: startMinutes,
            dayHours: dayHours,
            defaults: defaults,
            restDurationOverrides: restDurationOverrides
        )
    }

    public func duration(for kind: WorkdayIntervalKind) -> Int {
        defaults.first { $0.kind == kind }?.durationMinutes ?? 0
    }

    public func restDuration(afterFocusNumber number: Int) -> Int {
        restDurationOverrides.first { $0.afterFocusNumber == number }?.durationMinutes
            ?? duration(for: .rest)
    }

    public var endMinutes: Int {
        let defaultRest = duration(for: .rest)
        let overrideDelta = restDurationOverrides.reduce(0) {
            $0 + $1.durationMinutes - defaultRest
        }
        return startMinutes + dayHours * 60 + overrideDelta
    }

    private init(
        validatedStartMinutes startMinutes: Int,
        dayHours: Int,
        defaults: [WorkdayDefaults],
        restDurationOverrides: [RestDurationOverride]
    ) {
        self.startMinutes = startMinutes
        self.dayHours = dayHours
        self.defaults = defaults
        self.restDurationOverrides = restDurationOverrides
    }

    private enum CodingKeys: String, CodingKey {
        case startMinutes
        case dayHours
        case defaults
        case restDurationOverrides
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            startMinutes: container.decode(Int.self, forKey: .startMinutes),
            dayHours: container.decode(Int.self, forKey: .dayHours),
            defaults: container.decode([WorkdayDefaults].self, forKey: .defaults),
            restDurationOverrides: container.decode([RestDurationOverride].self, forKey: .restDurationOverrides)
        )
    }
}
