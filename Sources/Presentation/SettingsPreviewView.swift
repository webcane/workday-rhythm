import SessionCoordinator
import SwiftUI

/// Редактируемая панель параметров рабочего дня.
struct SettingsPreviewView: View {
    @State private var draft: DailyProgramDraft
    @State private var saveError: String?
    private let coordinator: SessionCoordinator
    let cancel: () -> Void

    init(coordinator: SessionCoordinator, cancel: @escaping () -> Void) {
        self.coordinator = coordinator
        self.cancel = cancel
        _draft = State(initialValue: DailyProgramDraft(settings: coordinator.programSettings))
    }

    var body: some View {
        let options = coordinator.projectLongBreakOptions(draft.optionsRequest)
        return DailyProgramView(
            draft: $draft, endTime: endTime,
            breakOptions: options,
            rules: coordinator.dailyProgramRules,
            saveError: saveError, save: save,
            cancel: {
                draft = DailyProgramDraft(settings: coordinator.programSettings)
                saveError = nil
                cancel()
            }
        )
        .onAppear { draft.reconcileBreakSelection(with: options) }
        .onChange(of: options) { snapshot in
            draft.reconcileBreakSelection(with: snapshot)
        }
    }

    private var endTime: String {
        let minutes =
            draft.startMinutes + draft.dayHours * 60
            + (draft.longBreakAfter == nil ? 0 : draft.longBreakMinutes - draft.restMinutes)
        return String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }

    private func save() {
        do {
            try coordinator.saveProgram(draft.settings)
            saveError = nil
        } catch {
            saveError = "Не удалось сохранить программу. Проверьте значения полей."
        }
    }
}
