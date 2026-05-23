import Foundation

protocol LiveGridProvider: Sendable {
    func fetch() async throws -> LiveGrid
}

protocol SnapshotProvider: Sendable {
    func fetch() async throws -> Snapshot
}
