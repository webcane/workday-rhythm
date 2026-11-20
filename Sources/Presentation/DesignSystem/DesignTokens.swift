import SwiftUI

/// Семантические роли поверх динамической системной палитры macOS.
enum DesignTokens {
    enum Palette {
        static let surface = Color(nsColor: .windowBackgroundColor)
        static let surfaceRaised = Color(nsColor: .controlBackgroundColor)
        static let textPrimary = Color(nsColor: .labelColor)
        static let textSecondary = Color(nsColor: .secondaryLabelColor)
        static let separator = Color(nsColor: .separatorColor)
        static let accent = Color.accentColor
        static let selection = Color(nsColor: .systemBlue)
        static let success = Color(nsColor: .systemGreen)
        static let warning = Color(nsColor: .systemOrange)
        static let danger = Color(nsColor: .systemRed)
    }

    enum Typography {
        static let windowTitle = Font.title2.weight(.semibold)
        static let sectionTitle = Font.headline
        static let body = Font.body
        static let caption = Font.subheadline
        static let metric = Font.title3.monospacedDigit()
        static let scaleLabel = Font.caption2.monospacedDigit()
    }

    enum Space {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let regular: CGFloat = 16
        static let section: CGFloat = 24
        static let large: CGFloat = 32

        static let all = [tiny, small, medium, regular, section, large]
    }

    static let controlRadius: CGFloat = 8
    static let separatorThickness: CGFloat = 1
}
