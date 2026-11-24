import SessionCoordinator

extension LongBreakOptionsSnapshot.Option {
    var timeLabel: String {
        let hour = startMinutes / 60
        let minute = startMinutes % 60
        return "С \(hour < 10 ? "0" : "")\(hour):\(minute < 10 ? "0" : "")\(minute)"
    }

    var accessibilityDescription: String {
        "Длинный перерыв после работы №\(afterFocusNumber), \(timeLabel)"
    }
}
