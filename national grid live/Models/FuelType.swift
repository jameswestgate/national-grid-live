import SwiftUI

enum FuelType: String, CaseIterable, Codable, Sendable, Hashable {
    case gas, coal, wind, solar, hydro, nuclear, biomass, pumped

    var displayName: String {
        switch self {
        case .gas: "Gas"
        case .coal: "Coal"
        case .wind: "Wind"
        case .solar: "Solar"
        case .hydro: "Hydroelectric"
        case .nuclear: "Nuclear"
        case .biomass: "Biomass"
        case .pumped: "Pumped storage"
        }
    }

    var category: FuelCategory {
        switch self {
        case .gas, .coal: .fossil
        case .wind, .solar, .hydro: .renewable
        case .nuclear, .biomass: .other
        case .pumped: .storage
        }
    }

    var swatch: Color {
        switch self {
        case .coal:    Color(.systemRed)
        case .gas:     Color(.systemOrange)
        case .solar:   Color(.systemYellow)
        case .wind:    Color(.systemGreen)
        case .hydro:   Color(.systemBlue)
        case .nuclear: Color(.systemCyan)
        case .biomass: Color(.systemIndigo)
        case .pumped:  Color(.systemGray)
        }
    }

    /// SF Symbol shown in the source-row icon badge.
    var systemImage: String {
        switch self {
        case .gas:     "flame.fill"
        case .coal:    "mountain.2.fill"
        case .wind:    "wind"
        case .solar:   "sun.max.fill"
        case .hydro:   "drop.fill"
        case .nuclear: "atom"
        case .biomass: "leaf.fill"
        case .pumped:  "arrow.up.arrow.down"
        }
    }
}

enum FuelCategory: String, CaseIterable, Sendable, Hashable {
    case fossil, renewable, other, storage

    var displayName: String {
        switch self {
        case .fossil: "fossil fuels"
        case .renewable: "renewables"
        case .other: "other sources"
        case .storage: "storage"
        }
    }

    var bannerColor: Color {
        switch self {
        case .fossil: Color(.systemRed)
        case .renewable: Color(.systemGreen)
        case .other: Palette.navy
        case .storage: Color(.systemGray)
        }
    }
}

enum Interconnector: String, CaseIterable, Codable, Sendable, Hashable {
    case france, norway, belgium, denmark, ireland, netherlands

    var displayName: String { rawValue.capitalized }

    var systemImage: String { "arrow.left.arrow.right" }

    var swatch: Color {
        switch self {
        case .france:      Color(.systemOrange)
        case .norway:      Color(.systemTeal)
        case .belgium:     Color(.systemPurple)
        case .denmark:     Color(.systemPink)
        case .ireland:     Color(.systemYellow)
        case .netherlands: Color(.systemGreen)
        }
    }
}
