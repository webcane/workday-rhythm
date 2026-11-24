/// Общая длительность одного вида интервала.
public struct WorkdayDefaults: Codable, Equatable, Sendable {
    public let kind: WorkdayIntervalKind
    public let durationMinutes: Int

    public init(kind: WorkdayIntervalKind, durationMinutes: Int) {
        self.kind = kind
        self.durationMinutes = durationMinutes
    }
}
