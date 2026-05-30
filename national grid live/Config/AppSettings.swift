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

enum AppSettings {
    /// `@AppStorage` key for the generation visualisation choice. Default: `.bar`.
    static let generationVisualisationKey = "generationVisualisation"
}

/// A tap on the generation graphic (bar segment or donut slice). Shared by
/// `GenerationBars` and `GenerationDonut` so the card handles both identically.
enum GenerationSelection: Equatable {
    case fuel(FuelType)
    case category(FuelCategory)
}
