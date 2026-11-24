import Foundation
import SessionCoordinator

/// Представление шкалы в минутах; не рассчитывает программу и не сохраняет настройки.
struct RulerScale: Equatable {
    private enum Kind: CaseIterable {
        case startTime
        case focus
        case rest
        case longBreak
    }

    private enum Metrics {
        static let durationStep = 5
    }

    let range: ClosedRange<Int>
    let step: Int
    private let kind: Kind

    static var startTime: Self { startTime(for: SessionCoordinator.defaultDailyProgramRules) }
    static var focus: Self { focus(for: SessionCoordinator.defaultDailyProgramRules) }
    static var rest: Self { rest(for: SessionCoordinator.defaultDailyProgramRules) }
    static var longBreak: Self { longBreak(for: SessionCoordinator.defaultDailyProgramRules) }
    static var allCases: [Self] { all(for: SessionCoordinator.defaultDailyProgramRules) }

    static func startTime(for rules: DailyProgramRulesSnapshot) -> Self {
        Self(kind: .startTime, range: rules.startMinutes.range, step: rules.startMinutes.step)
    }

    static func focus(for rules: DailyProgramRulesSnapshot) -> Self {
        Self(kind: .focus, range: rules.focusDurationMinutes, step: Metrics.durationStep)
    }

    static func rest(for rules: DailyProgramRulesSnapshot) -> Self {
        Self(kind: .rest, range: rules.restDurationMinutes, step: Metrics.durationStep)
    }

    static func longBreak(for rules: DailyProgramRulesSnapshot) -> Self {
        Self(kind: .longBreak, range: rules.restOverrideDurationMinutes, step: Metrics.durationStep)
    }

    static func all(for rules: DailyProgramRulesSnapshot) -> [Self] {
        [startTime(for: rules), focus(for: rules), rest(for: rules), longBreak(for: rules)]
    }

    private init(kind: Kind, range: ClosedRange<Int>, step: Int) {
        self.kind = kind
        self.range = range
        self.step = step
    }

    var values: [Int] { Array(stride(from: range.lowerBound, through: range.upperBound, by: step)) }

    func contains(_ value: Int) -> Bool {
        range.contains(value) && (value - range.lowerBound).isMultiple(of: step)
    }

    func nearestIndex(to value: Int) -> Int {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return Int((Double(clamped - range.lowerBound) / Double(step)).rounded())
    }

    func formatted(_ value: Int) -> String {
        if kind == .startTime {
            return String(format: "%02d:%02d", value / 60, value % 60)
        }
        return "\(value) мин"
    }

    func hasLabel(at value: Int) -> Bool {
        guard value >= 0 else { return false }
        if value == range.lowerBound || value == range.upperBound { return true }
        switch kind {
        case .startTime: return value.isMultiple(of: 60)
        case .longBreak: return value.isMultiple(of: 20)
        case .focus: return value.isMultiple(of: 30)
        case .rest: return (value - range.lowerBound).isMultiple(of: 10)
        }
    }

    func displayValues(around value: Int, visibleSteps: Int) -> [Int] {
        let center = values[nearestIndex(to: value)]
        let count = min(max(visibleSteps, 1), 200)
        let lower = kind == .startTime ? max(0, center - count * step) : center - count * step
        let upper = kind == .startTime ? min(1440, center + count * step) : center + count * step
        // Привязка к рискам сохраняет исходный шаг и за пределами допустимого интервала.
        let first = lower + (step - (lower - range.lowerBound) % step) % step
        return Array(stride(from: first, through: upper, by: step))
    }

    func clampedTranslation(from value: Int, translation: Double, tickSpacing: Double) -> Double {
        guard translation.isFinite, tickSpacing.isFinite, tickSpacing > 0 else { return 0 }
        let index = Double(nearestIndex(to: value))
        return min(max(translation, (index - Double(values.count - 1)) * tickSpacing), index * tickSpacing)
    }

    func value(afterDragging value: Int, translation: Double, tickSpacing: Double) -> Int {
        let translation = clampedTranslation(from: value, translation: translation, tickSpacing: tickSpacing)
        guard tickSpacing.isFinite, tickSpacing > 0 else { return values[nearestIndex(to: value)] }
        let index = Double(nearestIndex(to: value)) - translation / tickSpacing
        return values[min(max(Int(index.rounded()), 0), values.count - 1)]
    }

    func steppedValue(from value: Int, by direction: Int) -> Int {
        let index = min(max(nearestIndex(to: value) + direction.signum(), 0), values.count - 1)
        return values[index]
    }

    var errorMessage: String {
        "Выберите от \(formatted(range.lowerBound)) до \(formatted(range.upperBound)), шаг \(step) мин."
    }
}
