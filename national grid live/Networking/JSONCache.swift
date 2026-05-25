import Foundation
import os

struct JSONCache<Value: Codable> {
    private let url: URL
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private static var log: Logger {
        Logger(subsystem: "org.crainiate.national-grid-live", category: "cache")
    }

    init(filename: String,
         decoder: JSONDecoder = .init(),
         encoder: JSONEncoder = .init()) throws {
        let fm = FileManager.default
        let dir = try fm.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
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
