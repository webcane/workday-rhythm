import AppKit
import MacIntegration
import Presentation
import SessionCoordinator
import SettingsStore

@main
@MainActor
struct WorkdayRhythmApp {
    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        let coordinator = SessionCoordinator(settings: SettingsStore(), integration: MacIntegration())
        let shell = AppShell(coordinator: coordinator)
        application.delegate = shell
        withExtendedLifetime(shell) {
            application.run()
        }
    }
}
