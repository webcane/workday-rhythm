import SwiftUI

/// Перестраивает всю строку, сохраняя читаемую ширину шкалы и отдельный заголовок.
struct SettingsSection<Content: View>: View {
    private enum Metrics {
        static var headingWidth: CGFloat { 160 }
        static var contentMinimumWidth: CGFloat { 300 }
    }

    let title: String
    let symbol: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: DesignTokens.Space.tiny) {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .top, spacing: DesignTokens.Space.small) {
                    heading.frame(width: Metrics.headingWidth, alignment: .leading)
                    content().frame(minWidth: Metrics.contentMinimumWidth, maxWidth: .infinity)
                }
                VStack(alignment: .leading, spacing: DesignTokens.Space.tiny) {
                    heading
                    content().frame(maxWidth: .infinity)
                }
            }
            Rectangle().fill(DesignTokens.Palette.separator).frame(height: DesignTokens.separatorThickness)
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
