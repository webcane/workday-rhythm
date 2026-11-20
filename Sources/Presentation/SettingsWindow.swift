import AppKit

/// Окно удерживает ограничения независимо от перерасчёта minimum size hosting-представлением.
@MainActor
final class SettingsWindow: NSWindow, NSWindowDelegate {
    private enum Metrics {
        static let maximumHeightDivisor: CGFloat = 3
        static let minimumContentWidth: CGFloat = 720
    }

    private var minimumFrameSize: NSSize?

    func updateSizeLimits(screenFrame: NSRect) {
        let height = floor(screenFrame.height / Metrics.maximumHeightDivisor)
        let minimumWidth = frameRect(
            forContentRect: NSRect(x: 0, y: 0, width: Metrics.minimumContentWidth, height: 0)
        ).width
        let minimum = NSSize(width: minimumWidth, height: height)
        minimumFrameSize = minimum
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        minSize = minimum
        var target = frame
        target.origin.y += target.height - height
        target.size.height = height
        setFrame(target, display: false)
    }

    func windowWillResize(_ sender: NSWindow, to frameSize: NSSize) -> NSSize {
        constrainedSize(frameSize)
    }

    func windowDidChangeScreen(_ notification: Notification) {
        guard let screen else { return }
        updateSizeLimits(screenFrame: screen.visibleFrame)
    }

    override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        var target = frameRect
        let size = constrainedSize(target.size)
        target.origin.y += target.height - size.height
        target.size = size
        super.setFrame(target, display: flag)
    }

    private func constrainedSize(_ proposed: NSSize) -> NSSize {
        guard let minimumFrameSize else { return proposed }
        return NSSize(
            width: max(proposed.width, minimumFrameSize.width),
            height: minimumFrameSize.height)
    }
}
