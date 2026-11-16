import AppKit

/// Маршрут команд меню с подставляемыми системными действиями.
@MainActor
final class MenuCommands: NSObject {
    private let settingsHandler: () -> Void
    private let quitHandler: () -> Void

    init(showSettings: @escaping () -> Void, quit: @escaping () -> Void) {
        settingsHandler = showSettings
        quitHandler = quit
        super.init()
    }

    @objc func showSettings() {
        settingsHandler()
    }

    @objc func quit() {
        quitHandler()
    }
}
