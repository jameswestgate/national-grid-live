import SwiftUI

/// A single source/category row used across the Generation, Interconnectors and
/// Storage cards: a tinted icon badge, the name with a proportional bar beneath
/// it, and the GW value stacked over its share-of-demand percentage. Optionally
/// shows a disclosure chevron for expandable groups.
struct SourceRow: View {
    enum Chevron { case right, down }

    let icon: String
    let tint: Color
    let name: String
    let gw: Double?
    let percent: Double?
    var chevron: Chevron? = nil
    var emphasised: Bool = false
    /// Reserve the trailing chevron gutter even when there's no chevron, so the
    /// GW/% column lines up with sibling rows that do have one (the disclosable
    /// group headers). Used by the generation card's expanded member rows.
    var reservesChevronSpace: Bool = false
    /// Optional explicit bar fill [0,1] that decouples the bar from `percent`.
    /// Interconnectors pass |flow| / Σ|flows| here so the bar shows share of
    /// total interconnector movement while the % text stays share-of-demand.
    var barOverride: Double? = nil

    private static let chevronWidth: CGFloat = 14

    var body: some View {
        HStack(spacing: 12) {
            IconBadge(systemImage: icon, tint: tint, size: emphasised ? 34 : 30)

            VStack(alignment: .leading, spacing: 7) {
                Text(name)
                    .font(emphasised ? .body.weight(.medium) : .subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                ProgressBar(color: tint, progress: barProgress)
                    .frame(height: 5)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 2) {
                // Number bold/primary with a smaller grey "GW" suffix — matches
                // the KPI strip and the card headers used everywhere else.
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(gwNumber)
                        .font((emphasised ? Font.body : .subheadline).weight(.semibold))
                        .foregroundStyle(.primary)
                    if gw != nil {
                        Text("GW")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                }
                Text(percentText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .layoutPriority(1)

            if let chevron {
                Image(systemName: chevron == .down ? "chevron.down" : "chevron.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    // Fixed width so chevron.down (wider) and chevron.right (narrower)
                    // occupy the same space — the GW/% column doesn't shift on toggle.
                    .frame(width: Self.chevronWidth, alignment: .trailing)
            } else if reservesChevronSpace {
                Color.clear.frame(width: Self.chevronWidth)
            }
        }
    }

    private var barProgress: Double {
        // An explicit override (interconnectors use share of total interconnector
        // movement) wins; otherwise the bar mirrors |percent| (share of demand).
        if let barOverride { return min(max(barOverride, 0), 1) }
        guard let percent else { return 0 }
        return min(max(abs(percent), 0), 1)
    }

    /// Just the figure (no unit) — the "GW" suffix is a separate, smaller Text.
    private var gwNumber: String {
        guard let gw else { return "—" }
        let sign = gw < 0 ? "−" : ""
        return sign + String(format: "%.2f", abs(gw))
    }

    private var percentText: String {
        guard let percent else { return "—" }
        let sign = percent < 0 ? "−" : ""
        return sign + String(format: "%.1f%%", abs(percent) * 100)
    }
}

/// Rounded, tinted icon badge — soft tint fill with a saturated symbol.
struct IconBadge: View {
    let systemImage: String
    let tint: Color
    var size: CGFloat = 34

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.46, weight: .semibold))
            .foregroundStyle(tint)
            .frame(width: size, height: size)
            .background(tint.opacity(0.16), in: Circle())
    }
}

/// Thin capsule bar with a faint track and a proportional coloured fill.
struct ProgressBar: View {
    let color: Color
    let progress: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color(.quaternarySystemFill))
                Capsule().fill(color)
                    .frame(width: max(0, min(1, progress)) * geo.size.width)
            }
        }
    }
}
