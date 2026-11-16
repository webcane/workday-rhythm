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
        if value == range.lowerBound || value == range.upperBound { return true }
        switch self {
        case .startTime, .longBreak: return value.isMultiple(of: 60)
        case .focus: return value.isMultiple(of: 30)
        case .rest: return (value - range.lowerBound).isMultiple(of: 10)
        }
    }

    var errorMessage: String {
        "Выберите от \(formatted(range.lowerBound)) до \(formatted(range.upperBound)), шаг \(step) мин."
    }
}
