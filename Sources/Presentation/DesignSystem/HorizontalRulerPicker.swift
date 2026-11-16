import SwiftUI

/// Подвижная шкала; жест, клавиатура и VoiceOver изменяют одну привязку значения.
struct HorizontalRulerPicker: View {
    let title: String
    let scale: RulerScale
    @Binding var value: Int
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @FocusState private var isFocused: Bool
    @AccessibilityFocusState private var isAccessibilityFocused: Bool
    @State private var isHovered = false
    @GestureState private var translation: CGFloat = 0

    private var error: String? { scale.contains(value) ? nil : scale.errorMessage }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                let index = scale.nearestIndex(to: value)
                let tickSpacing = min(32, max(1, (geometry.size.width / 2 - 24) / CGFloat(scale.values.count - 1)))
                ZStack(alignment: .topLeading) {
                    ForEach(Array(scale.values.enumerated()), id: \.element) { tickIndex, tick in
                        Rectangle().fill(DesignTokens.Palette.textSecondary)
                            .frame(width: 1, height: 5)
                            .position(
                                x: geometry.size.width / 2 + CGFloat(tickIndex - index) * tickSpacing + translation,
                                y: 2.5)
                        if scale.hasLabel(at: tick) {
                            Text(scale.formatted(tick))
                                .font(DesignTokens.Typography.scaleLabel)
                                .foregroundStyle(DesignTokens.Palette.textSecondary)
                                .fixedSize()
                                .position(
                                    x: geometry.size.width / 2 + CGFloat(tickIndex - index) * tickSpacing + translation,
                                    y: 11)
                        }
                    }
                    Rectangle().fill(DesignTokens.Palette.selection)
                        .frame(width: 3, height: 5)
                        .position(x: geometry.size.width / 2, y: 2.5)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .updating($translation) { gesture, state, _ in
                            if isEnabled { state = gesture.translation.width }
                        }
                        .onEnded { gesture in
                            guard isEnabled else { return }
                            isFocused = true
                            let delta = Int((-gesture.translation.width / tickSpacing).rounded())
                            select(index: index + delta)
                        }
                )
            }
            .frame(height: 16)
            Text(scale.formatted(value))
                .font(DesignTokens.Typography.metric.weight(.semibold))
                .frame(maxWidth: .infinity)
            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, DesignTokens.Space.small)
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(isHovered ? DesignTokens.Palette.surfaceRaised : DesignTokens.Palette.surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.controlRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                .stroke(borderColor, lineWidth: isFocused ? 3 : 1)
        }
        .opacity(isEnabled ? 1 : 0.5)
        .onHover { isHovered = $0 }
        .focusable(isEnabled)
        .focused($isFocused)
        .onMoveCommand { direction in
            guard isEnabled else { return }
            switch direction {
            case .left, .down: adjust(by: -1)
            case .right, .up: adjust(by: 1)
            default: break
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(title)
        .accessibilityValue(scale.formatted(value))
        .accessibilityHint(error ?? "Изменяйте значение по шагам или перетаскивайте шкалу.")
        .accessibilityAdjustableAction { direction in
            guard isEnabled else { return }
            switch direction {
            case .increment: adjust(by: 1)
            case .decrement: adjust(by: -1)
            @unknown default: break
            }
        }
        .accessibilityFocused($isAccessibilityFocused)
        .onChange(of: value) { newValue in
            if !scale.contains(newValue) {
                isFocused = true
                isAccessibilityFocused = true
            }
        }
        .onAppear {
            if error != nil {
                isFocused = true
                isAccessibilityFocused = true
            }
        }
        .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: value)
    }

    private var borderColor: Color {
        if error != nil { return DesignTokens.Palette.danger }
        if isFocused { return DesignTokens.Palette.accent }
        return isHovered ? DesignTokens.Palette.textSecondary : DesignTokens.Palette.separator
    }

    private func adjust(by delta: Int) {
        select(index: scale.nearestIndex(to: value) + delta)
    }

    private func select(index: Int) {
        let index = min(max(index, 0), scale.values.count - 1)
        value = scale.values[index]
    }

}
