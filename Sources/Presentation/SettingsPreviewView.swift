import SessionCoordinator
import SwiftUI

/// Живой эталон в окне оболочки до подключения модели и хранения настроек.
struct SettingsPreviewView: View {
    @State private var draft = DailyProgramDraft()
    var projectOptions: @MainActor (LongBreakOptionsRequest) -> LongBreakOptionsSnapshot = SessionCoordinator
        .longBreakOptions
    let cancel: () -> Void

    var body: some View {
        let options = projectOptions(draft.optionsRequest)
        return DailyProgramView(
            draft: $draft, endTime: "—",
            breakOptions: options,
            notice: "Предпросмотр · сохранение и расчёт программы ещё не подключены",
            isSaveAvailable: false, save: {},
            cancel: {
                draft = .init()
                cancel()
            }
        )
        .onAppear { draft.reconcileBreakSelection(with: options) }
        .onChange(of: options) { snapshot in
            draft.reconcileBreakSelection(with: snapshot)
        }
    }
}
