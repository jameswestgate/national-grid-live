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
        case .gas: Color(red: 0.93, green: 0.66, blue: 0.40)
        case .coal: Color(red: 0.76, green: 0.32, blue: 0.40)
        case .wind: Color(red: 0.56, green: 0.78, blue: 0.36)
        case .solar: Color(red: 0.93, green: 0.79, blue: 0.20)
        case .hydro: Color(red: 0.30, green: 0.74, blue: 0.66)
        case .nuclear: Color(red: 0.27, green: 0.56, blue: 0.78)
        case .biomass: Color(red: 0.31, green: 0.36, blue: 0.66)
        case .pumped: Color(red: 0.30, green: 0.50, blue: 0.78)
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
        case .fossil: Color(red: 0.80, green: 0.27, blue: 0.33)
        case .renewable: Color(red: 0.36, green: 0.71, blue: 0.36)
        case .other: Color(red: 0.13, green: 0.47, blue: 0.80)
        case .storage: Color(white: 0.40)
        }
    }
}

enum Interconnector: String, CaseIterable, Codable, Sendable, Hashable {
    case france, norway, belgium, denmark, ireland, netherlands

    var displayName: String { rawValue.capitalized }

    var swatch: Color {
        switch self {
        case .france: Color(red: 0.93, green: 0.66, blue: 0.40)
        case .norway: Color(red: 0.30, green: 0.74, blue: 0.66)
        case .belgium: Color(red: 0.78, green: 0.42, blue: 0.78)
        case .denmark: Color(red: 0.93, green: 0.58, blue: 0.58)
        case .ireland: Color(red: 0.93, green: 0.79, blue: 0.20)
        case .netherlands: Color(red: 0.56, green: 0.78, blue: 0.36)
        }
    }
}
