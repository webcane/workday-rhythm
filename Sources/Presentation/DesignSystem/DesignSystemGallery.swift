import SwiftUI

/// Каталог ролей для визуальной проверки обеих тем и системного акцента.
struct DesignSystemGallery: View {
    var body: some View {
        VStack(alignment: .leading, spacing: DesignTokens.Space.section) {
            Text("Дизайн-система").font(DesignTokens.Typography.windowTitle)
            Text("Заголовок секции").font(DesignTokens.Typography.sectionTitle)
            Text("Основной текст").font(DesignTokens.Typography.body)
            Text("Подпись").font(DesignTokens.Typography.caption)
                .foregroundStyle(DesignTokens.Palette.textSecondary)
            Text("40:00").font(DesignTokens.Typography.metric)
            Text("08:00 · 13:00").font(DesignTokens.Typography.scaleLabel)
            HStack(spacing: DesignTokens.Space.small) {
                Text("Основная поверхность")
                Text("Приподнятая поверхность")
                    .padding(DesignTokens.Space.small)
                    .background(DesignTokens.Palette.surfaceRaised)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.controlRadius)
                            .stroke(DesignTokens.Palette.separator))
            }
            Rectangle().fill(DesignTokens.Palette.separator).frame(height: 1)
            Label("Системный акцент", systemImage: "cursorarrow.click")
                .foregroundStyle(DesignTokens.Palette.accent)
            Label("Выбранная риска", systemImage: "slider.horizontal.3")
                .foregroundStyle(DesignTokens.Palette.selection)
            Label("Готово", systemImage: "checkmark.circle")
                .foregroundStyle(DesignTokens.Palette.success)
            Label("Требует внимания", systemImage: "exclamationmark.triangle")
                .foregroundStyle(DesignTokens.Palette.warning)
            Label("Ошибка", systemImage: "exclamationmark.circle")
                .foregroundStyle(DesignTokens.Palette.danger)
            HStack(alignment: .bottom, spacing: DesignTokens.Space.small) {
                ForEach([4, 8, 12, 16, 24, 32], id: \.self) { space in
                    VStack {
                        Rectangle().fill(DesignTokens.Palette.accent)
                            .frame(width: CGFloat(space), height: CGFloat(space))
                        Text("\(space)")
                    }
                }
            }
        }
        .font(DesignTokens.Typography.body)
        .padding(DesignTokens.Space.section)
        .foregroundStyle(DesignTokens.Palette.textPrimary)
        .background(DesignTokens.Palette.surface)
    }
}

struct DesignSystemGalleryPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            DesignSystemGallery().preferredColorScheme(.light)
            DesignSystemGallery().preferredColorScheme(.dark)
        }
    }
}
