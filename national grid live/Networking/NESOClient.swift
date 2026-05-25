import Foundation

struct NESOClient: Sendable {
    let http: HTTPJSONClient
    var url = URL(string: "https://api.neso.energy/dataset/7a12172a-939c-404c-b581-a6128b74f588/resource/177f6fa4-ae49-4182-81ea-0c6b35f26ca6/download/demanddataupdate.csv")!

    init(http: HTTPJSONClient = HTTPJSONClient()) {
        self.http = http
    }

    struct EmbeddedRow: Sendable, Equatable {
        let timestamp: Date          // settlement bucket start, UTC
        let embeddedWindMW: Int      // megawatts
        let embeddedSolarMW: Int
    }

    /// Downloads the full CSV and returns rows in the half-open range
    /// `[from, to)`. The file covers ~60 days, so this is cheap.
    func fetchEmbedded(from: Date, to: Date) async throws -> [EmbeddedRow] {
        let csv = try await http.getText(url)
        return parse(csv: csv, from: from, to: to)
    }

    // MARK: - CSV parsing (minimal — only the columns we need)

    func parse(csv: String, from: Date, to: Date) -> [EmbeddedRow] {
        var lines = csv.split(omittingEmptySubsequences: true, whereSeparator: { $0 == "\n" || $0 == "\r\n" })
        guard let header = lines.first else { return [] }
        lines.removeFirst()

        let columns = splitCSVRow(String(header))
        guard
            let iDate = columns.firstIndex(of: "SETTLEMENT_DATE"),
            let iPeriod = columns.firstIndex(of: "SETTLEMENT_PERIOD"),
            let iWind = columns.firstIndex(of: "EMBEDDED_WIND_GENERATION"),
            let iSolar = columns.firstIndex(of: "EMBEDDED_SOLAR_GENERATION")
        else {
            return []
        }

        var result: [EmbeddedRow] = []
        result.reserveCapacity(lines.count)

        for line in lines {
            let cells = splitCSVRow(String(line))
            guard cells.count > max(iDate, iPeriod, iWind, iSolar) else { continue }
            let dateStr = cells[iDate]
            guard let period = Int(cells[iPeriod]),
                  let wind = Int(cells[iWind]),
                  let solar = Int(cells[iSolar]) else { continue }
            guard let ts = settlementTime(dateStr: dateStr, period: period) else { continue }
            guard ts >= from, ts < to else { continue }
            result.append(EmbeddedRow(timestamp: ts, embeddedWindMW: wind, embeddedSolarMW: solar))
        }
        return result
    }

    /// Combine SETTLEMENT_DATE (`YYYY-MM-DD`) and SETTLEMENT_PERIOD (1…48, or
    /// 46/50 on DST changeover days) into a UTC `Date`.
    ///
    /// **Important**: NESO settlement periods are numbered in **local UK time**
    /// (BST/GMT), not UTC. Period 1 starts at 00:00 *London time* on the
    /// settlement date — which is 23:00 UTC of the previous day in summer.
    /// Parsing the date in `Europe/London` makes the calendar boundary
    /// correct; `addingTimeInterval` then operates on absolute Date which is
    /// timezone-agnostic.
    private func settlementTime(dateStr: String, period: Int) -> Date? {
        guard let base = Self.dayFormatter.date(from: dateStr) else { return nil }
        return base.addingTimeInterval(TimeInterval(period - 1) * 30 * 60)
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .iso8601)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "Europe/London") ?? TimeZone(secondsFromGMT: 0)!
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    /// Splits a single CSV row respecting double-quoted fields (NESO quotes
    /// strings like `"2026-04-01"` but leaves bare integers unquoted).
    private func splitCSVRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        for ch in line {
            switch ch {
            case "\"":
                inQuotes.toggle()
            case "," where !inQuotes:
                fields.append(current)
                current = ""
            default:
                current.append(ch)
            }
        }
        fields.append(current)
        return fields
    }
}
