import SwiftUI

/// Подвижная шкала; жест, клавиатура и VoiceOver изменяют одну привязку значения.
struct HorizontalRulerPicker: View {
    private enum Metrics {
        static let tickSpacing: CGFloat = 32
        static let controlHeight: CGFloat = 35
        static let tickWidth: CGFloat = 1
        static let tickHeight: CGFloat = 14
        static let tickCenterY = tickHeight / 2
        static let labelCenterY: CGFloat = 25
        static let edgeLabelExclusionWidth: CGFloat = 28
        static let selectedValueExclusionRadius: CGFloat = 56
        static let selectionIndicatorWidth: CGFloat = 3
        static let borderWidth: CGFloat = 1
        static let focusedBorderWidth: CGFloat = 3
        static let dragMinimumDistance: CGFloat = 2
        static let contextOpacity = 0.3
        static let disabledOpacity = 0.5
        static let animationDuration = 0.15
    }

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
    private var selectedValue: Int {
        scale.value(
            afterDragging: value,
            translation: Double(translation),
            tickSpacing: Double(Metrics.tickSpacing))
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
            .frame(height: Metrics.controlHeight, alignment: .center)
            .padding(.horizontal, DesignTokens.Space.small)
        }
        .overlay {
            RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                .stroke(
                    borderColor,
                    lineWidth: isFocused ? Metrics.focusedBorderWidth : Metrics.borderWidth
                )
                .allowsHitTesting(false)
        }
        .accessibilityElement(children: .contain)
    }

    private var ruler: some View {
        VStack(alignment: .leading, spacing: 0) {
            GeometryReader { geometry in
                let anchor = scale.values[scale.nearestIndex(to: value)]
                let ticks = scale.displayValues(
                    around: selectedValue,
                    visibleSteps: Int(ceil(geometry.size.width / Metrics.tickSpacing)))
                ZStack(alignment: .topLeading) {
                    ForEach(ticks, id: \.self) { tick in
                        let x =
                            geometry.size.width / 2
                            + CGFloat(tick - anchor) / CGFloat(scale.step) * Metrics.tickSpacing
                            + translation
                        Rectangle().fill(DesignTokens.Palette.textSecondary)
                            .frame(width: Metrics.tickWidth, height: Metrics.tickHeight)
                            .position(x: x, y: Metrics.tickCenterY)
                            .opacity(scale.contains(tick) ? 1 : Metrics.contextOpacity)
                        if scale.hasLabel(at: tick) {
                            Text(scale.formatted(tick))
                                .font(DesignTokens.Typography.scaleLabel)
                                .foregroundStyle(DesignTokens.Palette.textSecondary)
                                .fixedSize()
                                .position(x: x, y: Metrics.labelCenterY)
                                .opacity(
                                    x < Metrics.edgeLabelExclusionWidth
                                        || x > geometry.size.width - Metrics.edgeLabelExclusionWidth
                                        || abs(x - geometry.size.width / 2)
                                            < Metrics.selectedValueExclusionRadius
                                        ? 0 : (scale.contains(tick) ? 1 : Metrics.contextOpacity))
                        }
                    }
                    Rectangle().fill(DesignTokens.Palette.selection)
                        .frame(width: Metrics.selectionIndicatorWidth, height: Metrics.tickHeight)
                        .position(x: geometry.size.width / 2, y: Metrics.tickCenterY)
                    Text(scale.formatted(translation == 0 ? value : selectedValue))
                        .font(DesignTokens.Typography.metric.weight(.semibold))
                        .fixedSize()
                        .padding(.horizontal, DesignTokens.Space.tiny)
                        .background(surface)
                        .position(x: geometry.size.width / 2, y: Metrics.labelCenterY)
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .clipped()
                .allowsHitTesting(false)
            }
            .frame(height: Metrics.controlHeight)
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
            DragGesture(minimumDistance: Metrics.dragMinimumDistance)
                .updating($translation) { gesture, state, _ in
                    guard isEnabled else { return }
                    state = CGFloat(
                        scale.clampedTranslation(
                            from: value, translation: Double(gesture.translation.width),
                            tickSpacing: Double(Metrics.tickSpacing)))
                }
                .onEnded { gesture in
                    guard isEnabled else { return }
                    isFocused = true
                    value = scale.value(
                        afterDragging: value, translation: Double(gesture.translation.width),
                        tickSpacing: Double(Metrics.tickSpacing))
                }
        )
        .help("Потяните шкалу влево или вправо. Для точного выбора используйте шевроны или клавиши со стрелками.")
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: DesignTokens.controlRadius))
        .opacity(isEnabled ? 1 : Metrics.disabledOpacity)
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
        .animation(reduceMotion ? nil : .easeOut(duration: Metrics.animationDuration), value: value)
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
