import SwiftUI

/// Нативная кнопка: системные hover, press, focus и disabled, общий контракт загрузки.
struct DesignButton: View {
    enum Role {
        case primary
        case secondary
    }

    let title: String
    var role: Role = .secondary
    var isLoading = false
    var error: String?
    let action: () -> Void

    static func shouldPerformAction(isLoading: Bool) -> Bool {
        !isLoading
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.tiny) {
            if role == .primary {
                button.buttonStyle(.borderedProminent)
            } else {
                button.buttonStyle(.bordered)
            }
            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.danger)
            }
        }
    }

    private var button: some View {
        Button {
            guard Self.shouldPerformAction(isLoading: isLoading) else { return }
            action()
        } label: {
            HStack(spacing: DesignTokens.Space.small) {
                if isLoading {
                    ProgressView().controlSize(.small).accessibilityHidden(true)
                }
                Text(title)
            }
        }
        .font(DesignTokens.Typography.body)
        .controlSize(.regular)
        .disabled(isLoading)
        .accessibilityLabel(title)
        .accessibilityValue(isLoading ? "Выполняется" : "")
        .overlay {
            if error != nil {
                RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                    .stroke(DesignTokens.Palette.danger, lineWidth: 1)
                    .allowsHitTesting(false)
            }
        }
    }
}

struct DesignButtonPreviews: PreviewProvider {
    static var previews: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.regular) {
            DesignButton(title: "Сохранить изменения", role: .primary) {}
            DesignButton(title: "Отменить") {}
            DesignButton(title: "Сохраняем", role: .primary, isLoading: true) {}
            DesignButton(title: "Недоступно") {}.disabled(true)
            DesignButton(title: "Повторить", error: "Не удалось выполнить действие") {}
        }
        .padding(DesignTokens.Space.section)
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(DesignTokens.Palette.surface)
    }
}
