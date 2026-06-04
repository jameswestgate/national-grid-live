import SwiftUI
import UIKit

/// A single-row diverging proportional bar for interconnector flows. There is
/// no donut equivalent (unlike Generation).
///
/// The bar width represents the grand total of the ABSOLUTE flows
/// (Σ|export| + Σ|import|). Exports (negative) sit on the LEFT as their abs
/// value, imports (positive) on the RIGHT, separated by a small gap at the
/// zero-crossing. Each segment is one interconnector, coloured by its swatch,
/// sized by |flow| / total, and labelled with the country name where it fits.
/// Largest magnitudes flank the central gap; slivers fall to the outer edges.
struct InterconnectorBars: View {
    /// Per-interconnector net flow (GW); negative = exporting.
    let flows: [(interconnector: Interconnector, gw: Double)]
    /// Tapping a segment asks the card to scroll that country's row into view.
    var onSelect: ((Interconnector) -> Void)? = nil

    private let barHeight: CGFloat = 30
    private let corner: CGFloat = 6
    private let gap: CGFloat = 6

    var body: some View {
        // Largest nearest the central gap; smallest to the outer edges.
        let negatives = flows.filter { $0.gw < 0 }.sorted { abs($0.gw) < abs($1.gw) }
        let positives = flows.filter { $0.gw > 0 }.sorted { abs($0.gw) > abs($1.gw) }
        let total = flows.reduce(0) { $0 + abs($1.gw) }
        let bothSides = !negatives.isEmpty && !positives.isEmpty

        GeometryReader { geo in
            let usableGap = bothSides ? gap : 0
            let unit = total > 0 ? (geo.size.width - usableGap) / total : 0

            HStack(spacing: 0) {
                if !negatives.isEmpty {
                    half(negatives, unit: unit,
                         leadingRounded: true, trailingRounded: !bothSides)
                }
                if bothSides {
                    Color.clear.frame(width: gap)
                }
                if !positives.isEmpty {
                    half(positives, unit: unit,
                         leadingRounded: !bothSides, trailingRounded: true)
                }
            }
        }
        .frame(height: barHeight)
        .accessibilityHidden(true) // the rows below carry the figures + colours
    }

    private func half(
        _ items: [(interconnector: Interconnector, gw: Double)],
        unit: CGFloat,
        leadingRounded: Bool,
        trailingRounded: Bool
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(items, id: \.interconnector) { item in
                let w = CGFloat(abs(item.gw)) * unit
                Rectangle()
                    .fill(item.interconnector.swatch)
                    .frame(width: w)
                    .overlay {
                        if labelFits(item.interconnector.displayName, in: w) {
                            Text(item.interconnector.displayName)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .foregroundStyle(textColor(on: item.interconnector.swatch))
                                .padding(.horizontal, 3)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture { onSelect?(item.interconnector) }
            }
        }
        .frame(height: barHeight)
        .clipShape(
            .rect(
                topLeadingRadius: leadingRounded ? corner : 0,
                bottomLeadingRadius: leadingRounded ? corner : 0,
                bottomTrailingRadius: trailingRounded ? corner : 0,
                topTrailingRadius: trailingRounded ? corner : 0
            )
        )
    }

    /// True when the country name fits the segment at the bar's font.
    private func labelFits(_ text: String, in width: CGFloat) -> Bool {
        let base = UIFont.preferredFont(forTextStyle: .caption2)
        let font = UIFont.systemFont(ofSize: base.pointSize, weight: .semibold)
        let textWidth = (text as NSString).size(withAttributes: [.font: font]).width
        return textWidth + 8 <= width
    }

    /// Black or white text for legibility against the segment fill.
    private func textColor(on color: Color) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else { return .white }
        return (0.299 * r + 0.587 * g + 0.114 * b) > 0.62 ? .black : .white
    }
}

#Preview {
    VStack(spacing: 20) {
        InterconnectorBars(flows: [
            (.france, 2.49), (.netherlands, 0.71), (.norway, 0.77), (.belgium, 0.72),
            (.ireland, -1.10), (.denmark, -0.30)
        ])
        InterconnectorBars(flows: Interconnector.allCases.map { ($0, Double.random(in: 0...2)) })
    }
    .padding()
    .background(Palette.contentBackground)
}
