import SwiftUI

/// Эталон popover; этап, отсчёт и команды предоставляет будущий владелец сессии.
struct SessionPopoverView: View {
    let stage: String
    let remainingTime: String
    let commandTitle: String
    let command: () -> Void
    let settings: () -> Void
    let quit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.regular) {
            Label(stage, systemImage: "timer")
                .font(DesignTokens.Typography.sectionTitle)
            Text(remainingTime)
                .font(DesignTokens.Typography.metric)
                .accessibilityLabel("Осталось \(remainingTime)")
            DesignButton(title: commandTitle, role: .primary, action: command)
            Rectangle().fill(DesignTokens.Palette.separator).frame(height: DesignTokens.separatorThickness)
            HStack(spacing: DesignTokens.Space.small) {
                DesignButton(title: "Настройки", action: settings)
                Spacer(minLength: 0)
                DesignButton(title: "Выход", action: quit)
            }
        }
        .padding(DesignTokens.Space.regular)
        .font(DesignTokens.Typography.body)
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(DesignTokens.Palette.surface)
    }
}

struct SessionPopoverViewPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            SessionPopoverView(
                stage: "Работа", remainingTime: "39:42", commandTitle: "Пауза",
                command: {}, settings: {}, quit: {}
            ).frame(width: 300).preferredColorScheme(.light)
            SessionPopoverView(
                stage: "Отдых", remainingTime: "04:15", commandTitle: "Продолжить",
                command: {}, settings: {}, quit: {}
            ).frame(width: 300).preferredColorScheme(.dark)
        }
    }
}
