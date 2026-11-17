import SwiftUI

/// Состояния встроенной кнопки шкалы без собственной обработки клика или фокуса.
struct RulerChevronButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = isEnabled && configuration.isPressed
        let isHighlighted = isEnabled && isHovered
        configuration.label
            .frame(width: 24, height: 24)
            .foregroundStyle(
                isEnabled ? DesignTokens.Palette.selection : DesignTokens.Palette.textSecondary.opacity(0.4)
            )
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                    .fill(background(isPressed: isPressed, isHighlighted: isHighlighted))
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                    .stroke(DesignTokens.Palette.separator.opacity(isEnabled ? 1 : 0.5), lineWidth: 1)
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.controlRadius))
            .scaleEffect(isPressed ? 0.9 : 1)
            .onHover { isHovered = isEnabled && $0 }
            .onChange(of: isEnabled) { enabled in
                if !enabled { isHovered = false }
            }
            .animation(animation, value: isPressed)
            .animation(animation, value: isHighlighted)
    }

    private var animation: Animation? {
        isEnabled && !reduceMotion ? .easeOut(duration: 0.12) : nil
    }

    private func background(isPressed: Bool, isHighlighted: Bool) -> Color {
        if !isEnabled { return DesignTokens.Palette.separator.opacity(0.12) }
        if isPressed { return DesignTokens.Palette.selection.opacity(0.25) }
        if isHighlighted { return DesignTokens.Palette.selection.opacity(0.12) }
        return DesignTokens.Palette.surfaceRaised
    }
}
