import SwiftUI

enum CategoryStyle {
    case fossil
    case renewable
    case other
    case interconnectors
    case storage

    var systemImage: String {
        switch self {
        case .fossil:          "flame.fill"
        case .renewable:       "leaf.fill"
        case .other:           "bolt.fill"
        case .interconnectors: "arrow.left.arrow.right"
        case .storage:         "battery.100"
        }
    }

    var tint: Color {
        switch self {
        case .fossil:          FuelCategory.fossil.bannerColor
        case .renewable:       FuelCategory.renewable.bannerColor
        case .other:           FuelCategory.other.bannerColor
        case .interconnectors: Color(.secondaryLabel)
        case .storage:         Color(.secondaryLabel)
        }
    }

    /// Primary categories (fossil/renewable/other) get a vivid filled badge and
    /// a tint-coloured percentage. Subordinate ones (interconnectors/storage)
    /// use a muted badge and plain text so they read below the Generation tier.
    var isPrimary: Bool {
        switch self {
        case .fossil, .renewable, .other: true
        case .interconnectors, .storage: false
        }
    }
}
