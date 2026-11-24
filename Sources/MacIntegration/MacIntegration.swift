import AppKit
import Foundation

/// Системные события и одна отменяемая граница активного интервала.
@MainActor
public final class MacIntegration: NSObject, MacIntegrating {
    private final class ScheduledHandler: NSObject {
        let action: () -> Void

        init(action: @escaping () -> Void) {
            self.action = action
        }

        @objc func fire() {
            action()
        }
    }

    private var eventHandler: ((MacSystemEvent) -> Void)?
    private var timer: Timer?
    private var scheduledHandler: ScheduledHandler?

    public override init() {
        super.init()
    }

    public func startObserving(_ handler: @escaping (MacSystemEvent) -> Void) {
        stopObserving()
        eventHandler = handler
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(didWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(didBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clockChanged),
            name: .NSSystemClockDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(timeZoneChanged),
            name: .NSSystemTimeZoneDidChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dayChanged),
            name: .NSCalendarDayChanged,
            object: nil
        )
    }

    public func stopObserving() {
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        NotificationCenter.default.removeObserver(self)
        eventHandler = nil
        cancelScheduledBoundary()
    }

    public func scheduleBoundary(after seconds: TimeInterval, handler: @escaping () -> Void) {
        cancelScheduledBoundary()
        let scheduledHandler = ScheduledHandler(action: handler)
        let timer = Timer(
            timeInterval: max(0.05, seconds),
            target: scheduledHandler,
            selector: #selector(ScheduledHandler.fire),
            userInfo: nil,
            repeats: false
        )
        self.scheduledHandler = scheduledHandler
        self.timer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    public func cancelScheduledBoundary() {
        timer?.invalidate()
        timer = nil
        scheduledHandler = nil
    }

    @objc private func didWake() {
        eventHandler?(.wake)
    }

    @objc private func didBecomeActive() {
        eventHandler?(.activity)
    }

    @objc private func clockChanged() {
        eventHandler?(.clockChanged)
    }

    @objc private func timeZoneChanged() {
        eventHandler?(.timeZoneChanged)
    }

    @objc private func dayChanged() {
        eventHandler?(.dayChanged)
    }
}
