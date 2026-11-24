public enum SessionSignal: Equatable, Sendable {
    case focusCompleted(number: Int)
    case restCompleted(number: Int)
    case dayFinished
}
