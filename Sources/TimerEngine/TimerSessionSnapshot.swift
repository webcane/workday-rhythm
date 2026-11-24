import Foundation

public enum TimerSessionPhase: Equatable, Sendable {
    case ready
    case focus
    case paused
    case rest
    case awaitingConfirmation
    case finished
}

/// Готовое для координатора состояние без внутренних деталей машины переходов.
public struct TimerSessionSnapshot: Equatable, Sendable {
    public let phase: TimerSessionPhase
    public let focusNumber: Int?
    public let restNumber: Int?
    public let pauseCount: Int
    public let remainingSeconds: TimeInterval?
    public let projectedIntervalEnd: Date?
    public let dayEnd: Date?

    public init(
        phase: TimerSessionPhase,
        focusNumber: Int? = nil,
        restNumber: Int? = nil,
        pauseCount: Int = 0,
        remainingSeconds: TimeInterval? = nil,
        projectedIntervalEnd: Date? = nil,
        dayEnd: Date? = nil
    ) {
        self.phase = phase
        self.focusNumber = focusNumber
        self.restNumber = restNumber
        self.pauseCount = pauseCount
        self.remainingSeconds = remainingSeconds
        self.projectedIntervalEnd = projectedIntervalEnd
        self.dayEnd = dayEnd
    }
}
