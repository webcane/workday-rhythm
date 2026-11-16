import AppKit
import SessionCoordinator
import SwiftUI

/// Оболочка приложения; правила сессии остаются за границей координатора.
@MainActor
public final class AppShell: NSObject, NSApplicationDelegate, NSWindowDelegate {
    private let coordinator: SessionCoordinator
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private lazy var menuCommands = MenuCommands(
        showSettings: { [weak self] in self?.showSettings() },
        quit: { NSApplication.shared.terminate(nil) }
    )

    public init(coordinator: SessionCoordinator) {
        self.coordinator = coordinator
        super.init()
    }

    public func applicationDidFinishLaunching(_ notification: Notification) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Workday Rhythm") {
            image.isTemplate = true
            item.button?.image = image
        } else {
            item.button?.title = "WR"
        }
        item.button?.toolTip = "Workday Rhythm"

        let menu = NSMenu()
        let settings = menu.addItem(
            withTitle: "Настройки", action: #selector(MenuCommands.showSettings), keyEquivalent: ",")
        settings.target = menuCommands
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Выход", action: #selector(MenuCommands.quit), keyEquivalent: "q")
        quit.target = menuCommands
        item.menu = menu
        statusItem = item
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    public func applicationWillTerminate(_ notification: Notification) {
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }

    private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = Self.makeSettingsWindow()
            settingsWindow?.delegate = self
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    public func windowDidChangeScreen(_ notification: Notification) {
        guard let window = notification.object as? NSWindow, let screen = window.screen else { return }
        Self.limitSettingsWindow(window, screenFrame: screen.visibleFrame)
    }

    static func makeSettingsWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Настройки — Workday Rhythm"
        window.isReleasedWhenClosed = false
        let content = NSHostingView(
            rootView: SettingsPreviewView(cancel: { [weak window] in window?.close() }))
        // Размер окна задаёт оболочка; высота содержимого доступна через ScrollView.
        content.sizingOptions = []
        window.contentView = content
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        limitSettingsWindow(window, screenFrame: screenFrame)
        window.center()
        return window
    }

    static func limitSettingsWindow(_ window: NSWindow, screenFrame: NSRect) {
        let height = floor(screenFrame.height / 3)
        let titleBarHeight = window.frame.height - window.contentRect(forFrameRect: window.frame).height
        window.contentMinSize = NSSize(width: 720, height: max(0, height - titleBarHeight))
        window.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: height)
        var frame = window.frame
        frame.origin.y += frame.height - height
        frame.size.height = height
        window.setFrame(frame, display: false)
    }
}
