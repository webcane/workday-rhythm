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
            AppShell.limitSettingsWindow(window, screenFrame: NSRect(x: 0, y: 0, width: 1728, height: screenHeight))
            XCTAssertLessThanOrEqual(window.frame.height, screenHeight / 3)
            XCTAssertLessThanOrEqual(window.maxSize.height, screenHeight / 3)
            XCTAssertEqual(window.minSize.height, window.maxSize.height, accuracy: 1)
        }
    }
}
