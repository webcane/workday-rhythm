import Darwin
import Foundation

/// Календарное время и непрерывный счётчик, включающий сон macOS.
@MainActor
public final class MacSystemTimeSource: SystemTimeProviding {
    public init() {}

    public func snapshot() -> SystemTimeSnapshot {
        var timebase = mach_timebase_info_data_t()
        mach_timebase_info(&timebase)
        let nanoseconds =
            Double(mach_continuous_time()) * Double(timebase.numer) / Double(timebase.denom)
        return SystemTimeSnapshot(date: Date(), elapsedSeconds: nanoseconds / 1_000_000_000)
    }
}
