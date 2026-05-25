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

    static let cardCornerRadius: CGFloat = 14
}
