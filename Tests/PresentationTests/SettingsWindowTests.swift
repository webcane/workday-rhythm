import AppKit
import SwiftUI
import XCTest

@testable import Presentation

final class SettingsWindowTests: XCTestCase {
    @MainActor
    func testSettingsWindowHostsInteractiveFormAndPreservesCompactMinimumSize() {
        _ = NSApplication.shared
        let window = AppShell.makeSettingsWindow()

        XCTAssertTrue(window.contentView is NSHostingView<SettingsPreviewView>)
        XCTAssertTrue(window.styleMask.contains(.resizable))
        XCTAssertEqual(window.contentMinSize.width, 720)
        XCTAssertFalse(window.isReleasedWhenClosed)
        XCTAssertEqual((window.contentView as? NSHostingView<SettingsPreviewView>)?.sizingOptions, [])
    }
    @MainActor
    func testWindowHeightIncludingTitleBarIsLimitedToThirdOfScreen() {
        _ = NSApplication.shared
        let window = AppShell.makeSettingsWindow()
        // 3456 × 2234 физических пикселей при Retina 2x — 1728 × 1117 pt.
        for screenHeight: CGFloat in [1117, 900, 600] {
            window.updateSizeLimits(screenFrame: NSRect(x: 0, y: 0, width: 1728, height: screenHeight))
            XCTAssertLessThanOrEqual(window.frame.height, screenHeight / 3)
            XCTAssertLessThanOrEqual(window.maxSize.height, screenHeight / 3)
            XCTAssertEqual(window.minSize.height, window.maxSize.height, accuracy: 1)
        }
    }

    @MainActor
    func testSmallResizeIsRejectedEvenIfHostingResetsWindowMinimum() throws {
        _ = NSApplication.shared
        let window = AppShell.makeSettingsWindow()
        window.updateSizeLimits(screenFrame: NSRect(x: 0, y: 0, width: 1728, height: 1050))
        let originalSize = window.frame.size
        window.contentView?.layoutSubtreeIfNeeded()

        // Auto Layout/hosting могут пересчитать свойства NSWindow после показа.
        window.contentMinSize = .zero
        window.minSize = .zero
        let delegateSize = try XCTUnwrap(window.delegate?.windowWillResize?(window, to: NSSize(width: 100, height: 60)))
        XCTAssertEqual(delegateSize, originalSize)

        window.setFrame(NSRect(x: 0, y: 0, width: 100, height: 60), display: false)
        XCTAssertEqual(window.frame.size, originalSize)
        XCTAssertGreaterThanOrEqual(window.frame.width, 720)
    }

}
