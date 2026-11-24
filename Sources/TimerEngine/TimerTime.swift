import Foundation

/// Одновременный снимок календарного и монотонного времени.
public struct TimerTime: Equatable, Sendable {
    public let date: Date
    public let elapsedSeconds: TimeInterval

    public init(date: Date, elapsedSeconds: TimeInterval) {
        self.date = date
        self.elapsedSeconds = elapsedSeconds
    }
}
