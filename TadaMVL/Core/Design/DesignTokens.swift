import SwiftUI

enum DesignTokens {

    enum Colors {
        static let surface = Color.white
        static let surfaceMuted = Color(white: 0.96)
        static let primary = Color(red: 1.0, green: 0.82, blue: 0.0) // Tada yellow
        static let onPrimary = Color.black
        static let textPrimary = Color.black
        static let textSecondary = Color(white: 0.55)
        static let divider = Color(white: 0.92)
        static let danger = Color(red: 0.85, green: 0.15, blue: 0.15)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
        static let xxl: CGFloat = 32
    }

    enum Radius {
        static let card: CGFloat = 12
        static let pill: CGFloat = 999
    }

    enum Typography {
        static let title = Font.title3.weight(.semibold)
        static let heading = Font.headline
        static let body = Font.body
        static let value = Font.body.weight(.semibold)
        static let label = Font.subheadline
        static let caption = Font.caption
    }

    enum Shadow {
        static let panel: (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) =
            (Color.black.opacity(0.08), 8, 0, -2)
    }
}
