import AppKit
import MacIntegration
import SessionCoordinator
import SettingsStore
import SwiftUI
import XCTest

@testable import Presentation

final class SettingsWindowTests: XCTestCase {
    @MainActor
    func testSettingsWindowHostsInteractiveFormAndUsesContentHeight() {
        _ = NSApplication.shared
        let window = makeSettingsWindow()

        XCTAssertTrue(window.contentView is NSHostingView<SettingsPreviewView>)
        XCTAssertTrue(window.styleMask.contains(.resizable))
        XCTAssertEqual(window.contentMinSize.width, 720)
        XCTAssertGreaterThan(window.frame.height, 0)
        XCTAssertFalse(window.isReleasedWhenClosed)
        XCTAssertEqual(
            (window.contentView as? NSHostingView<SettingsPreviewView>)?.sizingOptions,
            [.intrinsicContentSize]
        )
    }
    @MainActor
    func testWindowHeightIncludingTitleBarIsLimitedToThirdOfScreen() {
        _ = NSApplication.shared
        let window = makeSettingsWindow()
        // 3456 × 2234 физических пикселей при Retina 2x — 1728 × 1117 pt.
        for screenHeight: CGFloat in [1117, 900, 600] {
            window.updateSizeLimits(screenFrame: NSRect(x: 0, y: 0, width: 1728, height: screenHeight))
            XCTAssertLessThanOrEqual(window.frame.height, screenHeight / 3)
            XCTAssertLessThanOrEqual(window.maxSize.height, screenHeight / 3)
            XCTAssertLessThanOrEqual(window.minSize.height, window.maxSize.height)
        }
    }

    @MainActor
    func testSmallResizeIsRejectedEvenIfHostingResetsWindowMinimum() throws {
        _ = NSApplication.shared
        let window = makeSettingsWindow()
        window.updateSizeLimits(screenFrame: NSRect(x: 0, y: 0, width: 1728, height: 1050))
        let originalSize = window.frame.size
        window.contentView?.layoutSubtreeIfNeeded()

        // Auto Layout/hosting могут пересчитать свойства NSWindow после показа.
        window.contentMinSize = .zero
        window.minSize = .zero
        let delegateSize = try XCTUnwrap(window.delegate?.windowWillResize?(window, to: NSSize(width: 100, height: 60)))
        XCTAssertEqual(delegateSize.width, originalSize.width, accuracy: 0.5)
        XCTAssertEqual(delegateSize.height, originalSize.height, accuracy: 0.5)

        window.setFrame(NSRect(x: 0, y: 0, width: 100, height: 60), display: false)
        XCTAssertEqual(window.frame.width, originalSize.width, accuracy: 0.5)
        XCTAssertEqual(window.frame.height, originalSize.height, accuracy: 0.5)
        XCTAssertGreaterThanOrEqual(window.frame.width, 720)
    }

    @MainActor
    private func makeSettingsWindow() -> SettingsWindow {
        AppShell.makeSettingsWindow(
            coordinator: SessionCoordinator(settings: SettingsStore(), integration: TestMacIntegration()))
    }

}

@MainActor
private final class TestMacIntegration: MacIntegrating {
    func startObserving(_ handler: @escaping (MacSystemEvent) -> Void) {}
    func stopObserving() {}
    func scheduleBoundary(after seconds: TimeInterval, handler: @escaping () -> Void) {}
    func cancelScheduledBoundary() {}
}
