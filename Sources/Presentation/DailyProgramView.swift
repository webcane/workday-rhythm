import SessionCoordinator
import SwiftUI

/// Эталон формы: значения, вычисленный конец и прикладные действия поступают извне.
struct DailyProgramView: View {
    @Binding var draft: DailyProgramDraft
    let endTime: String
    let breakOptions: LongBreakOptionsSnapshot
    var rules = SessionCoordinator.defaultDailyProgramRules
    var notice: String?
    var isSaving = false
    var isSaveAvailable = true
    var saveError: String?
    let save: () -> Void
    let cancel: () -> Void

    var body: some View {
        ScrollView { formContent }
            .font(DesignTokens.Typography.body)
            .foregroundStyle(DesignTokens.Palette.textPrimary)
            .background(DesignTokens.Palette.surface)
    }

    var formContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: DesignTokens.Space.small) {
                Text("Дневная программа").font(DesignTokens.Typography.windowTitle).fixedSize()
                Text(notice ?? "Настройте ритм работы и отдыха на весь день.")
                    .font(DesignTokens.Typography.caption)
                    .lineLimit(1)
                    .help(notice ?? "Настройте ритм работы и отдыха на весь день.")
                    .foregroundStyle(DesignTokens.Palette.textSecondary)
            }
            SettingsSection(title: "Рабочий день", symbol: "sun.max") {
                VStack(alignment: .leading, spacing: DesignTokens.Space.tiny) {
                    HorizontalRulerPicker(
                        title: "Начало дня", scale: .startTime(for: rules), value: $draft.startMinutes)
                    HStack(spacing: DesignTokens.Space.small) {
                        Picker("Длительность дня", selection: $draft.dayHours) {
                            ForEach(rules.allowedDayHours, id: \.self) { hours in
                                Text("\(hours) ч").tag(hours)
                            }
                        }
                        .pickerStyle(.segmented)
                        .focusable()
                        .onMoveCommand { direction in
                            if let value = movedSelection(
                                from: draft.dayHours,
                                in: rules.allowedDayHours,
                                direction: direction)
                            {
                                draft.dayHours = value
                            }
                        }
                        Label("Конец дня: \(endTime)", systemImage: "sunset")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Palette.textSecondary)
                    }
                    if !draft.hasAllowedDayHours(in: rules) {
                        error(
                            "Выберите длительность дня: \(draft.allowedDayHoursDescription(in: rules)) часов.")
                    }

                }
            }
            SettingsSection(title: "Фокусирование", symbol: "scope") {
                HorizontalRulerPicker(
                    title: "Фокусирование", scale: .focus(for: rules), value: $draft.focusMinutes)
            }
            SettingsSection(title: "Отдых", symbol: "cup.and.saucer") {
                HorizontalRulerPicker(title: "Отдых", scale: .rest(for: rules), value: $draft.restMinutes)
            }
            SettingsSection(title: "Длинные перерывы", symbol: "leaf") {
                VStack(alignment: .leading, spacing: DesignTokens.Space.tiny) {
                    HorizontalRulerPicker(
                        title: "Длинный перерыв", scale: .longBreak(for: rules), value: $draft.longBreakMinutes)
                    HStack(spacing: DesignTokens.Space.small) {
                        Text("Начало перерыва")
                        Menu {
                            ForEach(breakOptions.options) { option in
                                Button(option.timeLabel) {
                                    selectBreak(after: option.afterFocusNumber)
                                }
                                .accessibilityLabel(option.accessibilityDescription)
                                .disabled(!option.isAvailable)
                            }
                        } label: {
                            Text(breakMenuTitle)
                        }
                        .fixedSize()
                        .focusable()
                        .accessibilityLabel("Начало перерыва")
                        .accessibilityValue(breakMenuTitle)
                        .help("Номинальное время от начала дня, без фактических пауз и ожиданий подтверждения.")
                    }
                    error(breakErrorMessage ?? " ")
                        .opacity(breakErrorMessage == nil ? 0 : 1)
                        .accessibilityHidden(breakErrorMessage == nil)
                }
            }
            HStack(spacing: DesignTokens.Space.small) {
                Spacer(minLength: 0)
                DesignButton(title: "Отменить", action: cancel)
                    .disabled(isSaving)
                DesignButton(
                    title: "Сохранить изменения", role: .primary,
                    isLoading: isSaving, error: saveError, action: save
                )
                .disabled(!isSaveEnabled)
            }
        }
        .padding(DesignTokens.Space.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(DesignTokens.Typography.body)
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(DesignTokens.Palette.surface)
    }

    private var hasInvalidValues: Bool {
        !RulerScale.startTime(for: rules).contains(draft.startMinutes)
            || !RulerScale.focus(for: rules).contains(draft.focusMinutes)
            || !RulerScale.rest(for: rules).contains(draft.restMinutes)
            || !RulerScale.longBreak(for: rules).contains(draft.longBreakMinutes)
            || !draft.hasAllowedDayHours(in: rules)
            || selectedBreakNumber == nil
    }

    private var workNumbers: [Int] {
        breakOptions.options.filter(\.isAvailable).map(\.afterFocusNumber)
    }

    var selectedBreakNumber: Int? {
        guard let number = draft.longBreakAfter, workNumbers.contains(number) else { return nil }
        return number
    }

    var breakMenuTitle: String {
        breakOptions.options.first {
            $0.isAvailable && $0.afterFocusNumber == draft.longBreakAfter
        }?.timeLabel ?? "Выберите время"
    }

    var breakErrorMessage: String? {
        if let message = breakOptions.errorMessage { return message }
        if workNumbers.isEmpty { return "До конца дня не помещаются перерыв и следующий фокус." }
        if selectedBreakNumber == nil { return "Выберите допустимое время начала перерыва." }
        return nil
    }

    func selectBreak(after number: Int) {
        draft.selectBreak(after: number, in: breakOptions)
    }

    var isSaveEnabled: Bool {
        !isSaving && isSaveAvailable && !hasInvalidValues
    }

    private func error(_ message: String) -> some View {
        Label(message, systemImage: "exclamationmark.circle")
            .font(DesignTokens.Typography.caption)
            .foregroundStyle(DesignTokens.Palette.danger)
    }

    private func movedSelection(
        from currentValue: Int,
        in values: [Int],
        direction: MoveCommandDirection
    ) -> Int? {
        let offset: Int
        switch direction {
        case .left, .down: offset = -1
        case .right, .up: offset = 1
        default: return nil
        }
        guard let currentIndex = values.firstIndex(of: currentValue) else {
            return offset > 0 ? values.first : values.last
        }
        return values[min(max(currentIndex + offset, values.startIndex), values.index(before: values.endIndex))]
    }
}

struct DailyProgramViewPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            DailyProgramView(
                draft: .constant(.init()), endTime: "18:00",
                breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest), save: {},
                cancel: {}
            )
            .frame(width: 720, height: 850).preferredColorScheme(.light)
            DailyProgramView(
                draft: .constant(.init()), endTime: "18:00",
                breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest), save: {},
                cancel: {}
            )
            .frame(width: 720, height: 850).preferredColorScheme(.dark)
            DailyProgramView(
                draft: .constant(.init()), endTime: "18:00",
                breakOptions: SessionCoordinator.longBreakOptions(for: DailyProgramDraft().optionsRequest), save: {},
                cancel: {}
            )
            .frame(width: 480, height: 1000)
        }
    }
}
