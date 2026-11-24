/// Единственный актуальный пользовательский сигнал после перехода ядра.
public enum TimerEffect: Equatable, Sendable {
    case focusCompleted(number: Int)
    case restCompleted(number: Int)
    case dayFinished
}
