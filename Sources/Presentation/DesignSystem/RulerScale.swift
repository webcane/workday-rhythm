import Foundation

/// Представление шкалы в минутах; не рассчитывает программу и не сохраняет настройки.
enum RulerScale: CaseIterable {
    case startTime
    case focus
    case rest
    case longBreak

    var range: ClosedRange<Int> {
        switch self {
        case .startTime: 480...780
        case .focus: 10...120
        case .rest: 5...35
        case .longBreak: 20...240
        }
    }

    var step: Int { self == .startTime ? 30 : 5 }

    var values: [Int] { Array(stride(from: range.lowerBound, through: range.upperBound, by: step)) }

    func contains(_ value: Int) -> Bool {
        range.contains(value) && (value - range.lowerBound).isMultiple(of: step)
    }

    func nearestIndex(to value: Int) -> Int {
        let clamped = min(max(value, range.lowerBound), range.upperBound)
        return Int((Double(clamped - range.lowerBound) / Double(step)).rounded())
    }

    func formatted(_ value: Int) -> String {
        if self == .startTime {
            return String(format: "%02d:%02d", value / 60, value % 60)
        }
        return "\(value) мин"
    }

    func hasLabel(at value: Int) -> Bool {
        guard value >= 0 else { return false }
        if value == range.lowerBound || value == range.upperBound { return true }
        switch self {
        case .startTime: return value.isMultiple(of: 60)
        case .longBreak: return value.isMultiple(of: 20)
        case .focus: return value.isMultiple(of: 30)
        case .rest: return (value - range.lowerBound).isMultiple(of: 10)
        }
    }

    func displayValues(around value: Int, visibleSteps: Int) -> [Int] {
        let center = values[nearestIndex(to: value)]
        let count = min(max(visibleSteps, 1), 200)
        let lower = self == .startTime ? max(0, center - count * step) : center - count * step
        let upper = self == .startTime ? min(1440, center + count * step) : center + count * step
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
