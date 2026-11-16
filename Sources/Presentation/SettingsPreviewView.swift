import SwiftUI

/// Живой эталон в окне оболочки до подключения модели и хранения настроек.
struct SettingsPreviewView: View {
    @State private var draft = DailyProgramDraft()
    let cancel: () -> Void

    var body: some View {
        DailyProgramView(
            draft: $draft, endTime: "—", workNumbers: Array(1...12),
            notice: "Предпросмотр · сохранение и расчёт программы ещё не подключены",
            isSaveAvailable: false, save: {},
            cancel: {
                draft = .init()
                cancel()
            })
    }
}
