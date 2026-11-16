import AppKit
import SessionCoordinator

/// Оболочка приложения; правила сессии остаются за границей координатора.
@MainActor
public final class AppShell: NSObject, NSApplicationDelegate {
    private let coordinator: SessionCoordinator
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

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
        let settings = menu.addItem(withTitle: "Настройки", action: #selector(showSettings), keyEquivalent: ",")
        settings.target = self
        menu.addItem(.separator())
        let quit = menu.addItem(withTitle: "Выход", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
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

    @objc private func showSettings() {
        if settingsWindow == nil {
            settingsWindow = makeSettingsWindow()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    @objc private func quit() {
        NSApplication.shared.terminate(nil)
    }

    private func makeSettingsWindow() -> NSWindow {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 200),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Настройки — Workday Rhythm"
        window.isReleasedWhenClosed = false
        let title = NSTextField(labelWithString: "Дневная программа")
        title.font = .preferredFont(forTextStyle: .headline)
        let message = NSTextField(wrappingLabelWithString:
            "Параметры дневной программы появятся на следующем этапе реализации.")
        message.textColor = .secondaryLabelColor
        let content = NSStackView(views: [title, message])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 12
        content.translatesAutoresizingMaskIntoConstraints = false
        if let view = window.contentView {
            view.addSubview(content)
            NSLayoutConstraint.activate([
                content.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
                content.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
                content.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
        }
        window.center()
        return window
    }
}
