import AppKit
import SessionCoordinator
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
                    draft: .constant(.init()), endTime: "18:00",
                    breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest),
                    save: {}, cancel: {})
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
            draft: .constant(draft), endTime: "18:00",
            breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest), save: {},
            cancel: {})
        try render(
            settings.formContent.frame(width: 720, height: 1000).environment(\.dynamicTypeSize, .accessibility3),
            scheme: .light, name: "settings-invalid-large")
        try render(DesignButtonPreviews.previews, scheme: .light, name: "buttons")
    }

    @MainActor
    func testClearedBreakSelectionRendersInBothAppearances() throws {
        var draft = DailyProgramDraft()
        draft.dayHours = 4
        draft.longBreakAfter = nil
        let form = DailyProgramView(
            draft: .constant(draft), endTime: "—",
            breakOptions: SessionCoordinator.longBreakOptions(for: draft.optionsRequest),
            save: {}, cancel: {})
        for scheme in [ColorScheme.light, .dark] {
            try render(form.formContent.frame(width: 720), scheme: scheme, name: "settings-break-unselected")
        }
    }

    @MainActor
    func testBreakErrorDoesNotMoveButtonsOrRequireFixedHeight() throws {
        _ = NSApplication.shared
        var draft = DailyProgramDraft()
        draft.dayHours = 4
        draft.longBreakAfter = 3
        let snapshot = SessionCoordinator.longBreakOptions(for: draft.optionsRequest)
        let valid = DailyProgramView(
            draft: .constant(draft), endTime: "—", breakOptions: snapshot, save: {}, cancel: {})
        let validHost = NSHostingView(rootView: valid.formContent.frame(width: 720))
        draft.longBreakAfter = nil
        let invalid = DailyProgramView(
            draft: .constant(draft), endTime: "—", breakOptions: snapshot, save: {}, cancel: {})
        let invalidHost = NSHostingView(rootView: invalid.formContent.frame(width: 720))
        XCTAssertEqual(validHost.fittingSize.height, invalidHost.fittingSize.height, accuracy: 0.5)
        XCTAssertGreaterThan(invalidHost.fittingSize.height, 0)
        for scheme in [ColorScheme.light, .dark] {
            try render(valid.formContent.frame(width: 720), scheme: scheme, name: "settings-menu-valid")
            try render(invalid.formContent.frame(width: 720), scheme: scheme, name: "settings-menu-error")
        }
    }

    @MainActor
    func testAllSettingsHavePreferredContentHeight() throws {
        _ = NSApplication.shared
        let form = DailyProgramView(
            draft: .constant(.init()), endTime: "—",
            breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest),
            notice: "Предпросмотр · сохранение и расчёт программы ещё не подключены",
            isSaveAvailable: false, save: {}, cancel: {})
        let content = form.formContent.frame(width: 720)
        let host = NSHostingView(rootView: content)
        XCTAssertGreaterThan(host.fittingSize.height, 0)
        try render(content, scheme: .light, name: "settings-compact")
        try render(content, scheme: .dark, name: "settings-compact")
    }

    @MainActor
    func testRulersAtSelectionBoundsRenderWithContextBeyondAllowedRange() throws {
        let controls = VStack(spacing: DesignTokens.Space.small) {
            HorizontalRulerPicker(title: "Начало дня", scale: .startTime, value: .constant(480))
            HorizontalRulerPicker(title: "Начало дня", scale: .startTime, value: .constant(780))
            HorizontalRulerPicker(title: "Фокусирование", scale: .focus, value: .constant(10))
            HorizontalRulerPicker(title: "Отдых", scale: .rest, value: .constant(35))
        }
        .padding(DesignTokens.Space.small)
        .background(DesignTokens.Palette.surface)
        .frame(width: 536)
        try render(controls, scheme: .light, name: "ruler-bounds")
        try render(controls, scheme: .dark, name: "ruler-bounds")
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
