/// Виды настраиваемых интервалов; пауза относится к состоянию сессии.
public enum WorkdayIntervalKind: String, CaseIterable, Codable, Hashable, Sendable {
    case focus
    case rest
}
