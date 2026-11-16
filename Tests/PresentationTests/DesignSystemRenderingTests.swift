import AppKit
import SwiftUI
import XCTest

@testable import Presentation

final class DesignSystemRenderingTests: XCTestCase {
    @MainActor
    func testGalleryRendersInBothAppearances() throws {
        for scheme in [ColorScheme.light, .dark] {
            try render(DesignSystemGallery().frame(width: 560), scheme: scheme, name: "gallery")
        }
    }

    @MainActor
    func testReferenceScreensRenderAtBothWidthsAndAccents() throws {
        for scheme in [ColorScheme.light, .dark] {
            for alternativeAccent in [false, true] {
                let accent: Color? = alternativeAccent ? .purple : nil
                let suffix = alternativeAccent ? "purple" : "system"
                let settings = DailyProgramView(
                    draft: .constant(.init()), endTime: "18:00", workNumbers: Array(1...12), save: {}, cancel: {})
                try render(
                    settings.formContent.frame(width: 720, height: 900).accentColor(accent),
                    scheme: scheme, name: "settings-\(suffix)")
                try render(
                    settings.formContent.frame(width: 380, height: 1100).accentColor(accent),
                    scheme: scheme, name: "settings-narrow-\(suffix)")
                try render(
                    SessionPopoverView(
                        stage: "Работа", remainingTime: "39:42", commandTitle: "Пауза",
                        command: {}, settings: {}, quit: {}
                    ).frame(width: 300).accentColor(accent), scheme: scheme, name: "popover-\(suffix)")
            }
        }
    }

    @MainActor
    func testExternalInvalidValueAndLargeTextRender() throws {
        var draft = DailyProgramDraft()
        draft.focusMinutes = 42
        let settings = DailyProgramView(
            draft: .constant(draft), endTime: "18:00", workNumbers: Array(1...12), save: {}, cancel: {})
        try render(
            settings.formContent.frame(width: 720, height: 1000).environment(\.dynamicTypeSize, .accessibility3),
            scheme: .light, name: "settings-invalid-large")
        try render(DesignButtonPreviews.previews, scheme: .light, name: "buttons")
    }

    @MainActor
    func testAllSettingsFitInCompactWindowWithoutScrolling() throws {
        _ = NSApplication.shared
        let form = DailyProgramView(
            draft: .constant(.init()), endTime: "—", workNumbers: Array(1...12),
            notice: "Предпросмотр · сохранение и расчёт программы ещё не подключены",
            isSaveAvailable: false, save: {}, cancel: {})
        let content = form.formContent.frame(width: 720)
        let host = NSHostingView(rootView: content)
        XCTAssertLessThanOrEqual(host.fittingSize.height, 300)
        try render(content, scheme: .light, name: "settings-compact")
        try render(content, scheme: .dark, name: "settings-compact")
    }

    @MainActor
    private func render<Content: View>(_ content: Content, scheme: ColorScheme, name: String) throws {
        _ = NSApplication.shared
        let appearance = try XCTUnwrap(NSAppearance(named: scheme == .light ? .aqua : .darkAqua))
        let host = NSHostingView(
            rootView: content.environment(\.colorScheme, scheme).environment(\.controlActiveState, .key))
        host.appearance = appearance
        host.frame = NSRect(origin: .zero, size: host.fittingSize)
        let window = NSWindow(contentRect: host.frame, styleMask: [], backing: .buffered, defer: false)
        window.contentView = host
        host.layoutSubtreeIfNeeded()
        host.displayIfNeeded()
        let bitmap = try XCTUnwrap(host.bitmapImageRepForCachingDisplay(in: host.bounds))
        host.cacheDisplay(in: host.bounds, to: bitmap)
        XCTAssertGreaterThan(bitmap.pixelsHigh, 100)
        let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
        try png.write(to: URL(fileURLWithPath: "/tmp/workday-\(name)-\(scheme).png"))
    }
}
