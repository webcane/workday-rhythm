import Program
import TimerEngine
import SettingsStore
import MacIntegration

/// Владеет компонентами сессии; команды таймера пока отсутствуют.
@MainActor
public final class SessionCoordinator {
    private let engine: TimerEngine
    private let settings: SettingsStore
    private let integration: MacIntegration

    public init(settings: SettingsStore, integration: MacIntegration) {
        self.engine = TimerEngine()
        self.settings = settings
        self.integration = integration
    }
}
