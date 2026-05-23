import Foundation

struct LiveData: Sendable, Equatable {
    let current: LiveGrid
    let day: TimeSeries
    let week: TimeSeries
}
