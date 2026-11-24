import SessionCoordinator
import SwiftUI

/// Редактируемая панель параметров рабочего дня.
struct SettingsPreviewView: View {
    @State private var draft: DailyProgramDraft
    @State private var saveError: String?
    private let coordinator: SessionCoordinator
    private let close: () -> Void
    private let log: (String) -> Void

    init(
        coordinator: SessionCoordinator,
        close: @escaping () -> Void,
        log: @escaping (String) -> Void = { print($0) }
    ) {
        self.coordinator = coordinator
        self.close = close
        self.log = log
        _draft = State(initialValue: DailyProgramDraft(settings: coordinator.programSettings))
    }

    var body: some View {
        let options = coordinator.projectLongBreakOptions(draft.optionsRequest)
        return DailyProgramView(
            draft: $draft, endTime: endTime,
            breakOptions: options,
            rules: coordinator.dailyProgramRules,
            saveError: saveError, save: { saveError = save(draft.settings) },
            cancel: {
                draft = DailyProgramDraft(settings: coordinator.programSettings)
                saveError = nil
                cancelEditing()
            }
        )
        .onAppear { draft.reconcileBreakSelection(with: options) }
        .onChange(of: options) { snapshot in
            draft.reconcileBreakSelection(with: snapshot)
        }
        .onChange(of: draft.startMinutes) { value in
            logChange("Начало дня", value: formattedTime(value))
        }
        .onChange(of: draft.dayHours) { value in
            logChange("Длительность дня", value: "\(value) ч")
        }
        .onChange(of: draft.focusMinutes) { value in
            logChange("Фокусирование", value: "\(value) мин")
        }
        .onChange(of: draft.restMinutes) { value in
            logChange("Отдых", value: "\(value) мин")
        }
        .onChange(of: draft.longBreakMinutes) { value in
            logChange("Длинный перерыв", value: "\(value) мин")
        }
        .onChange(of: draft.longBreakAfter) { value in
            let description = value.map { "после фокусирования №\($0)" } ?? "не выбран"
            logChange("Начало длинного перерыва", value: description)
        }
    }

    private var endTime: String {
        let minutes =
            draft.startMinutes + draft.dayHours * 60
            + (draft.longBreakAfter == nil ? 0 : draft.longBreakMinutes - draft.restMinutes)
        return String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }

    func save(_ settings: DailyProgramSettings) -> String? {
        do {
            try coordinator.saveProgram(settings)
            log("[Настройки] Сохранено: \(programDescription(settings))")
            close()
            return nil
        } catch {
            return "Не удалось сохранить программу. Проверьте значения полей."
        }
    }

    func cancelEditing() {
        log("[Настройки] Изменения отменены")
        close()
    }

    func logChange(_ name: String, value: String) {
        log("[Настройки] \(name): \(value)")
    }

    private func formattedTime(_ minutes: Int) -> String {
        String(format: "%02d:%02d", (minutes / 60) % 24, minutes % 60)
    }

    private func programDescription(_ settings: DailyProgramSettings) -> String {
        let longBreak =
            settings.longBreakAfter.map {
                "\(settings.longBreakMinutes) мин после фокусирования №\($0)"
            } ?? "не задан"
        return "начало \(formattedTime(settings.startMinutes)), день \(settings.dayHours) ч, "
            + "фокусирование \(settings.focusMinutes) мин, отдых \(settings.restMinutes) мин, "
            + "длинный перерыв \(longBreak)"
    }
}
