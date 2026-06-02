import SwiftUI

/// How the generation mix is visualised at the top of the Generation card.
/// Persisted in `UserDefaults` via `@AppStorage(AppSettings.generationVisualisationKey)`.
enum GenerationVisualisation: String, CaseIterable, Identifiable {
    case bar
    case donut
    case hidden   // "None" — show no graphic, just the header + groups

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bar:    "Bar"
        case .donut:  "Donut"
        case .hidden: "None"
        }
    }

    var systemImage: String {
        switch self {
        case .bar:    "chart.bar.xaxis"
        case .donut:  "chart.pie.fill"
        case .hidden: "slash.circle"
        }
    }
}

/// App appearance override. `.system` follows the device setting.
enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .system: "System"
        case .light:  "Light"
        case .dark:   "Dark"
        }
    }

    var systemImage: String {
        switch self {
        case .system: "circle.lefthalf.filled"
        case .light:  "sun.max"
        case .dark:   "moon"
        }
    }

    /// `nil` = follow the system; otherwise force the scheme.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light:  .light
        case .dark:   .dark
        }
    }
}

enum AppSettings {
    /// `@AppStorage` key for the generation visualisation choice. Default: `.bar`.
    static let generationVisualisationKey = "generationVisualisation"
    /// `@AppStorage` key for the appearance override. Default: `.system`.
    static let themeKey = "appTheme"
    /// `@AppStorage` key for showing legends under the Historic charts. Default: off.
    static let showGraphLegendsKey = "showGraphLegends"
}

/// A tap on the generation graphic (bar segment or donut slice). Shared by
/// `GenerationBars` and `GenerationDonut` so the card handles both identically.
enum GenerationSelection: Equatable {
    case fuel(FuelType)
    case category(FuelCategory)
}
