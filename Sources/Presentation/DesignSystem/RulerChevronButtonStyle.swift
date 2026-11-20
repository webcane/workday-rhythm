import SwiftUI

/// Состояния встроенной кнопки шкалы без собственной обработки клика или фокуса.
struct RulerChevronButtonStyle: ButtonStyle {
    private enum Metrics {
        static let buttonSize: CGFloat = 24
        static let borderWidth: CGFloat = 1
        static let disabledForegroundOpacity = 0.4
        static let enabledBorderOpacity = 1.0
        static let disabledBorderOpacity = 0.5
        static let pressedScale = 0.9
        static let defaultScale = 1.0
        static let disabledBackgroundOpacity = 0.12
        static let pressedBackgroundOpacity = 0.25
        static let highlightedBackgroundOpacity = 0.12
        static let animationDuration = 0.12
    }

    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isHovered = false

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = isEnabled && configuration.isPressed
        let isHighlighted = isEnabled && isHovered
        configuration.label
            .frame(width: Metrics.buttonSize, height: Metrics.buttonSize)
            .foregroundStyle(
                isEnabled
                    ? DesignTokens.Palette.selection
                    : DesignTokens.Palette.textSecondary.opacity(Metrics.disabledForegroundOpacity)
            )
            .background {
                RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                    .fill(background(isPressed: isPressed, isHighlighted: isHighlighted))
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                    .stroke(
                        DesignTokens.Palette.separator.opacity(
                            isEnabled ? Metrics.enabledBorderOpacity : Metrics.disabledBorderOpacity),
                        lineWidth: Metrics.borderWidth)
            }
            .contentShape(RoundedRectangle(cornerRadius: DesignTokens.controlRadius))
            .scaleEffect(isPressed ? Metrics.pressedScale : Metrics.defaultScale)
            .onHover { isHovered = isEnabled && $0 }
            .onChange(of: isEnabled) { enabled in
                if !enabled { isHovered = false }
            }
            .animation(animation, value: isPressed)
            .animation(animation, value: isHighlighted)
    }

    private var animation: Animation? {
        isEnabled && !reduceMotion ? .easeOut(duration: Metrics.animationDuration) : nil
    }

    private func background(isPressed: Bool, isHighlighted: Bool) -> Color {
        if !isEnabled { return DesignTokens.Palette.separator.opacity(Metrics.disabledBackgroundOpacity) }
        if isPressed { return DesignTokens.Palette.selection.opacity(Metrics.pressedBackgroundOpacity) }
        if isHighlighted {
            return DesignTokens.Palette.selection.opacity(Metrics.highlightedBackgroundOpacity)
        }
        return DesignTokens.Palette.surfaceRaised
    }
}
