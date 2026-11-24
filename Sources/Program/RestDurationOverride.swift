/// Индивидуальная длительность отдыха после указанной работы.
public struct RestDurationOverride: Codable, Equatable, Sendable {
    public let afterFocusNumber: Int
    public let durationMinutes: Int

    public init(afterFocusNumber: Int, durationMinutes: Int) {
        self.afterFocusNumber = afterFocusNumber
        self.durationMinutes = durationMinutes
    }
}
