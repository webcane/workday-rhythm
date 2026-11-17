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

    private let tickSpacing: CGFloat = 32
    private var error: String? { scale.contains(value) ? nil : scale.errorMessage }
    private var selectedValue: Int {
        scale.value(afterDragging: value, translation: Double(translation), tickSpacing: Double(tickSpacing))
    }
    private var surface: Color {
        isHovered ? DesignTokens.Palette.surfaceRaised : DesignTokens.Palette.surface
    }

    var body: some View {
        ZStack(alignment: .top) {
            ruler
            HStack {
                stepButton(direction: -1)
                Spacer(minLength: 0)
                stepButton(direction: 1)
            }
            .frame(height: 35, alignment: .center)
            .padding(.horizontal, DesignTokens.Space.small)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                .stroke(borderColor, lineWidth: isFocused ? 3 : 1)
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
    }

    private var ruler: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                let anchor = scale.values[scale.nearestIndex(to: value)]
                let ticks = scale.displayValues(
                    around: selectedValue, visibleSteps: Int(ceil(geometry.size.width / tickSpacing)))
                ZStack(alignment: .topLeading) {
                    ForEach(ticks, id: \.self) { tick in
                        let x =
                            geometry.size.width / 2 + CGFloat(tick - anchor) / CGFloat(scale.step) * tickSpacing
                            + translation
                        Rectangle().fill(DesignTokens.Palette.textSecondary)
                            .frame(width: 1, height: 14)
                            .position(x: x, y: 7)
                            .opacity(scale.contains(tick) ? 1 : 0.3)
                        if scale.hasLabel(at: tick) {
                            Text(scale.formatted(tick))
                                .font(DesignTokens.Typography.scaleLabel)
                                .foregroundStyle(DesignTokens.Palette.textSecondary)
                                .fixedSize()
                                .position(x: x, y: 25)
                                .opacity(
                                    x < 28 || x > geometry.size.width - 28
                                        || abs(x - geometry.size.width / 2) < 56
                                        ? 0 : (scale.contains(tick) ? 1 : 0.3))
                        }
                    }
                    Rectangle().fill(DesignTokens.Palette.selection)
                        .frame(width: 3, height: 14)
                        .position(x: geometry.size.width / 2, y: 7)
                    Text(scale.formatted(translation == 0 ? value : selectedValue))
                        .font(DesignTokens.Typography.metric.weight(.semibold))
                        .fixedSize()
                        .padding(.horizontal, DesignTokens.Space.tiny)
                        .background(surface)
                        .position(x: geometry.size.width / 2, y: 25)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .allowsHitTesting(false)
            }
            .frame(height: 35)
            if let error {
                Label(error, systemImage: "exclamationmark.circle")
                    .font(DesignTokens.Typography.caption)
                    .foregroundStyle(DesignTokens.Palette.danger)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.horizontal, DesignTokens.Space.small)
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 2)
                .updating($translation) { gesture, state, _ in
                    guard isEnabled else { return }
                    state = CGFloat(
                        scale.clampedTranslation(
                            from: value, translation: Double(gesture.translation.width),
                            tickSpacing: Double(tickSpacing)))
                }
                .onEnded { gesture in
                    guard isEnabled else { return }
                    isFocused = true
                    value = scale.value(
                        afterDragging: value, translation: Double(gesture.translation.width),
                        tickSpacing: Double(tickSpacing))
                }
        )
        .help("Потяните шкалу влево или вправо. Для точного выбора используйте шевроны или клавиши со стрелками.")
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.controlRadius))
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

    private func stepButton(direction: Int) -> some View {
        let decrease = direction < 0
        let label = decrease ? "Уменьшить" : "Увеличить"
        return Button {
            adjust(by: direction)
        } label: {
            Image(systemName: decrease ? "chevron.left" : "chevron.right")
                .font(DesignTokens.Typography.caption.weight(.semibold))
        }
        .buttonStyle(RulerChevronButtonStyle())
        .controlSize(.mini)
        .disabled(!isEnabled || translation != 0 || scale.steppedValue(from: value, by: direction) == value)
        .help("\(label) на \(scale.step) мин")
        .accessibilityLabel("\(title): \(label.lowercased())")
        .accessibilityValue(scale.formatted(value))
    }

    private var borderColor: Color {
        if error != nil { return DesignTokens.Palette.danger }
        if isFocused { return DesignTokens.Palette.accent }
        return isHovered ? DesignTokens.Palette.textSecondary : DesignTokens.Palette.separator
    }

    private func adjust(by delta: Int) {
        guard isEnabled else { return }
        value = scale.steppedValue(from: value, by: delta)
    }
}
