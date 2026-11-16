import AppKit
import SessionCoordinator

/// Оболочка приложения; правила сессии остаются за границей координатора.
@MainActor
public final class AppShell: NSObject, NSApplicationDelegate {
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
        let settings = menu.addItem(withTitle: "Настройки", action: #selector(MenuCommands.showSettings), keyEquivalent: ",")
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
            settingsWindow = makeSettingsWindow()
        }
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
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
