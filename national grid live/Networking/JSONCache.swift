import Foundation
import os

struct JSONCache<Value: Codable> {
    private let url: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private static var log: Logger {
        Logger(subsystem: "org.crainiate.national-grid-live", category: "cache")
    }

    /// - Parameter appGroup: when set, the cache lives in that App Group's
    ///   shared container (so the app and the widget read/write the same file).
    ///   If the group isn't entitled yet, falls back to this process's private
    ///   Application Support — the app still works, it just isn't shared.
    init(filename: String,
         appGroup: String? = nil,
         decoder: JSONDecoder = .init(),
         encoder: JSONEncoder = .init()) throws {
        let fm = FileManager.default
        let dir: URL
        if let appGroup, let container = fm.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            dir = container
        } else {
            dir = try fm.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        }
        try fm.createDirectory(at: dir, withIntermediateDirectories: true)
        self.url = dir.appendingPathComponent(filename, isDirectory: false)
        self.decoder = decoder
        self.encoder = encoder
    }

    func read() -> Value? {
        guard FileManager.default.fileExists(atPath: url.path) else { return nil }
        do {
            let data = try Data(contentsOf: url)
            return try decoder.decode(Value.self, from: data)
        } catch {
            Self.log.warning("cache read failed for \(url.lastPathComponent): \(error.localizedDescription)")
            return nil
        }
    }

    func write(_ value: Value) {
        do {
            let data = try encoder.encode(value)
            let tmp = url.deletingPathExtension().appendingPathExtension("tmp")
            try data.write(to: tmp, options: [.atomic])
            _ = try FileManager.default.replaceItemAt(url, withItemAt: tmp)
        } catch {
            Self.log.warning("cache write failed for \(url.lastPathComponent): \(error.localizedDescription)")
        }
    }

    func clear() {
        try? FileManager.default.removeItem(at: url)
    }
}

/// Shared container identifier linking the app and its widget extension.
///
/// Requires the **App Groups** capability with this exact identifier enabled on
/// BOTH targets (Signing & Capabilities). Until then,
/// `containerURL(forSecurityApplicationGroupIdentifier:)` returns nil and
/// `JSONCache` falls back to each process's private Application Support — the
/// app still runs, the widget just fetches its own data instead of sharing.
enum AppGroup {
    static let identifier = "group.org.crainiate.national-grid-live"

    /// Filename (in the shared container) for the latest `LiveGrid` the app
    /// fetched. The widget prefers this so its numbers match the app exactly.
    static let snapshotFilename = "widget-current.json"
}
