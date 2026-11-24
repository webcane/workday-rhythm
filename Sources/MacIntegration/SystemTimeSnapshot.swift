import Foundation

public struct SystemTimeSnapshot: Equatable, Sendable {
    public let date: Date
    public let elapsedSeconds: TimeInterval

    public init(date: Date, elapsedSeconds: TimeInterval) {
        self.date = date
        self.elapsedSeconds = elapsedSeconds
    }
}
