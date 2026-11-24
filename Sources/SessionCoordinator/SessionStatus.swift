import Foundation

public enum SessionStage: Equatable, Sendable {
    case ready
    case focus
    case paused
    case rest
    case awaitingConfirmation
    case finished
}

public struct SessionStatus: Equatable, Sendable {
    public let stage: SessionStage
    public let focusNumber: Int?
    public let restNumber: Int?
    public let pauseCount: Int
    public let remainingSeconds: TimeInterval?
    public let dayEnd: Date?

    public init(
        stage: SessionStage,
        focusNumber: Int?,
        restNumber: Int?,
        pauseCount: Int,
        remainingSeconds: TimeInterval?,
        dayEnd: Date?
    ) {
        self.stage = stage
        self.focusNumber = focusNumber
        self.restNumber = restNumber
        self.pauseCount = pauseCount
        self.remainingSeconds = remainingSeconds
        self.dayEnd = dayEnd
    }
}
