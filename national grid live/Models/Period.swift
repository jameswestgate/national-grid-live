import Foundation

enum Period: String, CaseIterable, Identifiable, Sendable, Hashable {
    case day, week, year, allTime

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .day: "Past day"
        case .week: "Past week"
        case .year: "Past year"
        case .allTime: "All time"
        }
    }

    var shortName: String {
        switch self {
        case .day: "day"
        case .week: "week"
        case .year: "year"
        case .allTime: "All"
        }
    }
}
