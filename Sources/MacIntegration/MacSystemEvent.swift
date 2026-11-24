public enum MacSystemEvent: Equatable, Sendable {
    case activity
    case wake
    case clockChanged
    case timeZoneChanged
    case dayChanged
}
