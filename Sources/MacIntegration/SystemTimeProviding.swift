@MainActor
public protocol SystemTimeProviding: AnyObject {
    func snapshot() -> SystemTimeSnapshot
}
