import AppKit
import SessionCoordinator
import SwiftUI

/// Оболочка приложения; правила сессии остаются за границей координатора.
@MainActor
public final class AppShell: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let coordinator: SessionCoordinator
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?
    private var menu: NSMenu?
    private lazy var menuCommands = MenuCommands(
        showSettings: { [weak self] in self?.showSettings() },
        quit: { NSApplication.shared.terminate(nil) },
        startDay: { [weak self] in self?.coordinator.startDay() },
        pause: { [weak self] in self?.coordinator.pause() },
        resume: { [weak self] in self?.coordinator.resume() },
        continueAfterRest: { [weak self] in self?.coordinator.continueAfterRest() }
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
        menu.delegate = self
        item.menu = menu
        statusItem = item
        self.menu = menu
        rebuildMenu()
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    public func applicationWillTerminate(_ notification: Notification) {
        coordinator.stopSession()
        if let statusItem {
            NSStatusBar.system.removeStatusItem(statusItem)
        }
        statusItem = nil
    }

    public func menuWillOpen(_ menu: NSMenu) {
        rebuildMenu()
    }

    private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = Self.makeSettingsWindow(coordinator: coordinator)
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    private func rebuildMenu() {
        guard let menu else { return }
        let status = coordinator.status
        menu.removeAllItems()
        menu.addItem(withTitle: statusDescription(for: status), action: nil, keyEquivalent: "").isEnabled = false

        if let command = command(for: status) {
            menu.addItem(.separator())
            let item = menu.addItem(withTitle: command.title, action: command.action, keyEquivalent: "")
            item.target = menuCommands
        }

        menu.addItem(.separator())
        let settings = menu.addItem(
            withTitle: "Настройки", action: #selector(MenuCommands.showSettings), keyEquivalent: ",")
        settings.target = menuCommands
        let quit = menu.addItem(withTitle: "Выход", action: #selector(MenuCommands.quit), keyEquivalent: "q")
        quit.target = menuCommands
        statusItem?.button?.toolTip = statusDescription(for: status)
    }

    private func command(for status: SessionStatus) -> (title: String, action: Selector)? {
        switch status.stage {
        case .ready, .finished:
            ("Начать день", #selector(MenuCommands.startDay))
        case .focus:
            ("Пауза", #selector(MenuCommands.pause))
        case .paused:
            ("Продолжить работу", #selector(MenuCommands.resume))
        case .awaitingConfirmation:
            ("Продолжить", #selector(MenuCommands.continueAfterRest))
        case .rest:
            nil
        }
    }

    private func statusDescription(for status: SessionStatus) -> String {
        switch status.stage {
        case .ready: "Готов к началу дня"
        case .focus: "Фокусирование №\(status.focusNumber ?? 1)"
        case .paused: "Пауза в фокусировании №\(status.focusNumber ?? 1)"
        case .rest: "Отдых №\(status.restNumber ?? 1)"
        case .awaitingConfirmation: "Ожидается продолжение перед фокусированием №\(status.focusNumber ?? 1)"
        case .finished: "Рабочий день завершён"
        }
    }

    static func makeSettingsWindow(coordinator: SessionCoordinator) -> SettingsWindow {
        let window = SettingsWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 300),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Настройки — Workday Rhythm"
        window.isReleasedWhenClosed = false
        window.delegate = window
        let content = NSHostingView(
            rootView: SettingsPreviewView(coordinator: coordinator, cancel: { [weak window] in window?.close() }))
        // Размер окна задаёт оболочка; высота содержимого доступна через ScrollView.
        content.sizingOptions = [.intrinsicContentSize]
        window.contentView = content
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        window.updateSizeLimits(screenFrame: screenFrame)
        window.center()
        return window
    }

}
