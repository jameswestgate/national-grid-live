import SwiftUI

enum Palette {
    // Surfaces
    static let pageBackground    = Color(.systemGroupedBackground)
    static let contentBackground = Color(.secondarySystemGroupedBackground)
    static let tableStripe       = Color(.tertiarySystemGroupedBackground)

    // Text
    static let contentText = Color(.label)
    /// Calmer than `.label` but darker than `.secondaryLabel` — used for data
    /// numerics and subordinate card values where pure black would shout.
    static let dataText = Color.primary.opacity(0.78)

    // Charts
    static let graphLine = Color(.separator)

    // Legacy heading slot (PeriodSelector / CardHeader during transition).
    // Both will be replaced by native components — this just keeps call sites compiling.
    static let headingBackground = Color(.tertiarySystemFill)
    static let headingText       = Color(.label)

    // Brand tint sourced from AccentColor asset.
    static let accent = Color.accentColor

    /// Generation-mix palette, taken verbatim from grid.iamkate.com's `grid.css`
    /// (CC0). Fixed hues (not semantic system colours) so the chart reads exactly
    /// like the reference site in both light and dark mode. Renewables/wind and
    /// the "other sources" blues are intentionally distinct shades within a hue.
    enum Fuel {
        static let coal    = hex(0xa35)  // dark crimson
        static let gas     = hex(0xe94)  // orange
        static let solar   = hex(0xed0)  // yellow
        static let wind    = hex(0x9d5)  // lime / yellow-green
        static let hydro   = hex(0x2cb)  // teal
        static let nuclear = hex(0x09c)  // cyan-blue
        static let biomass = hex(0x36b)  // blue

        static let fossilCategory    = hex(0xc45)  // red
        static let renewableCategory = hex(0x5b5)  // green
        static let otherCategory     = hex(0x27c)  // blue
    }

    /// Expand a 3-digit (`0xRGB`) CSS-style hex into a Color.
    private static func hex(_ rgb: Int) -> Color {
        let r = (rgb >> 8) & 0xF, g = (rgb >> 4) & 0xF, b = rgb & 0xF
        return Color(red: Double(r * 17) / 255, green: Double(g * 17) / 255, blue: Double(b * 17) / 255)
    }

    static let cardCornerRadius: CGFloat = 14
}
