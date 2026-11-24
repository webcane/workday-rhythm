import AppKit

/// Окно удерживает ограничения независимо от перерасчёта minimum size hosting-представлением.
@MainActor
final class SettingsWindow: NSWindow, NSWindowDelegate {
    private enum Metrics {
        static let maximumHeightDivisor: CGFloat = 2
    }

    static let preferredContentWidth: CGFloat = 720

    private var minimumFrameSize: NSSize?
    private var maximumFrameHeight: CGFloat?

    func updateSizeLimits(screenFrame: NSRect) {
        let maximumHeight = floor(screenFrame.height / Metrics.maximumHeightDivisor)
        let minimumWidth = frameRect(
            forContentRect: NSRect(x: 0, y: 0, width: Self.preferredContentWidth, height: 0)
        ).width
        let preferredHeight = frameRect(
            forContentRect: NSRect(
                x: 0,
                y: 0,
                width: Self.preferredContentWidth,
                height: contentView?.fittingSize.height ?? 0
            )
        ).height
        let minimum = NSSize(width: minimumWidth, height: min(preferredHeight, maximumHeight))
        minimumFrameSize = minimum
        maximumFrameHeight = maximumHeight
        maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: maximumHeight)
        minSize = minimum
        var target = frame
        let height = min(max(preferredHeight, minimum.height), maximumHeight)
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
        guard let minimumFrameSize, let maximumFrameHeight else { return proposed }
        return NSSize(
            width: max(proposed.width, minimumFrameSize.width),
            height: min(max(proposed.height, minimumFrameSize.height), maximumFrameHeight))
    }
}
