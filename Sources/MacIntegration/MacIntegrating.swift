import Foundation

@MainActor
public protocol MacIntegrating: AnyObject {
    func startObserving(_ handler: @escaping (MacSystemEvent) -> Void)
    func stopObserving()
    func scheduleBoundary(after seconds: TimeInterval, handler: @escaping () -> Void)
    func cancelScheduledBoundary()
}
