import Foundation

struct LiveData: Codable, Sendable, Equatable {
    let current: LiveGrid
    let day: TimeSeries
    let week: TimeSeries
}
