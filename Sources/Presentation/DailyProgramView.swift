import SwiftUI

/// Эталон формы: значения, вычисленный конец и прикладные действия поступают извне.
struct DailyProgramView: View {
    @Binding var draft: DailyProgramDraft
    let endTime: String
    let workNumbers: [Int]
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
        VStack(alignment: .leading, spacing: DesignTokens.Space.tiny) {
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
                    HorizontalRulerPicker(title: "Начало дня", scale: .startTime, value: $draft.startMinutes)
                    HStack(spacing: DesignTokens.Space.small) {
                        Picker("Длительность дня", selection: $draft.dayHours) {
                            ForEach(DailyProgramDraft.allowedDayHours, id: \.self) { hours in
                                Text("\(hours) ч").tag(hours)
                            }
                        }
                        .pickerStyle(.segmented)
                        .focusable()
                        .onMoveCommand { direction in
                            if let value = movedSelection(
                                from: draft.dayHours,
                                in: DailyProgramDraft.allowedDayHours,
                                direction: direction)
                            {
                                draft.dayHours = value
                            }
                        }
                        Label("Конец дня: \(endTime)", systemImage: "sunset")
                            .font(DesignTokens.Typography.caption)
                            .foregroundStyle(DesignTokens.Palette.textSecondary)
                    }
                    if !draft.hasAllowedDayHours {
                        error(
                            "Выберите длительность дня: \(DailyProgramDraft.allowedDayHoursDescription) часов.")
                    }

                }
            }
            SettingsSection(title: "Фокусирование", symbol: "scope") {
                HorizontalRulerPicker(title: "Фокусирование", scale: .focus, value: $draft.focusMinutes)
            }
            SettingsSection(title: "Отдых", symbol: "cup.and.saucer") {
                HorizontalRulerPicker(title: "Отдых", scale: .rest, value: $draft.restMinutes)
            }
            SettingsSection(title: "Длинные перерывы", symbol: "leaf") {
                VStack(alignment: .leading, spacing: DesignTokens.Space.tiny) {
                    HorizontalRulerPicker(
                        title: "Длинный перерыв", scale: .longBreak, value: $draft.longBreakMinutes)
                    Picker("После какой работы", selection: $draft.longBreakAfter) {
                        ForEach(workNumbers, id: \.self) { number in
                            Text("После работы №\(number)").tag(number)
                        }
                    }
                    .pickerStyle(.menu)
                    .focusable()
                    .onMoveCommand { direction in
                        if let value = movedSelection(
                            from: draft.longBreakAfter,
                            in: workNumbers,
                            direction: direction)
                        {
                            draft.longBreakAfter = value
                        }
                    }
                    if !workNumbers.contains(draft.longBreakAfter) {
                        error("Выберите номер работы из меню.")
                    }
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
                .disabled(hasInvalidValues || !isSaveAvailable)
            }
        }
        .padding(DesignTokens.Space.small)
        .frame(maxWidth: .infinity, alignment: .leading)
        .font(DesignTokens.Typography.body)
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(DesignTokens.Palette.surface)
    }

    private var hasInvalidValues: Bool {
        !RulerScale.startTime.contains(draft.startMinutes)
            || !RulerScale.focus.contains(draft.focusMinutes)
            || !RulerScale.rest.contains(draft.restMinutes)
            || !RulerScale.longBreak.contains(draft.longBreakMinutes)
            || !draft.hasAllowedDayHours
            || !workNumbers.contains(draft.longBreakAfter)
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
        guard let currentIndex = values.firstIndex(of: currentValue) else { return nil }
        let offset: Int
        switch direction {
        case .left, .down: offset = -1
        case .right, .up: offset = 1
        default: return nil
        }
        return values[min(max(currentIndex + offset, values.startIndex), values.index(before: values.endIndex))]
    }
}

struct DailyProgramViewPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            DailyProgramView(
                draft: .constant(.init()), endTime: "18:00",
                workNumbers: DailyProgramDraft.allowedWorkNumbers, save: {}, cancel: {}
            )
            .frame(width: 720, height: 850).preferredColorScheme(.light)
            DailyProgramView(
                draft: .constant(.init()), endTime: "18:00",
                workNumbers: DailyProgramDraft.allowedWorkNumbers, save: {}, cancel: {}
            )
            .frame(width: 720, height: 850).preferredColorScheme(.dark)
            DailyProgramView(
                draft: .constant(.init()), endTime: "18:00",
                workNumbers: DailyProgramDraft.allowedWorkNumbers, save: {}, cancel: {}
            )
            .frame(width: 380, height: 1000)
        }
    }
}
