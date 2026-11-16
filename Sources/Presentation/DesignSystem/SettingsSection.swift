import SwiftUI

/// Перестраивает всю строку, сохраняя читаемую ширину шкалы и отдельный заголовок.
struct SettingsSection<Content: View>: View {
    let title: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: DesignTokens.Space.tiny) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: DesignTokens.Space.small) {
                    heading.frame(width: 160, alignment: .leading)
                    content().frame(minWidth: 300, maxWidth: .infinity)
                }
                VStack(alignment: .leading, spacing: DesignTokens.Space.tiny) {
                    heading
                    content().frame(maxWidth: .infinity)
                }
            }
            Rectangle().fill(DesignTokens.Palette.separator).frame(height: 1)
                .padding(.leading, DesignTokens.Space.section)
        }
    }

    private var heading: some View {
        Label(title, systemImage: symbol)
            .font(DesignTokens.Typography.sectionTitle)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}
