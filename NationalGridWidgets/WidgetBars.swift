//
//  WidgetBars.swift
//  NationalGridWidgets
//
//  Bar + legend building blocks for the Home Screen widgets. Deliberately
//  widget-specific rather than sharing the app's GenerationBars /
//  InterconnectorBars: those are interactive (tap-to-scroll) with fit-tested
//  in-segment labels sized for the app, while these are static, thinner, and
//  pair with an external legend. Colour parity comes for free — both read
//  FuelType.swatch / Interconnector.swatch backed by the shared Palette.
//

import SwiftUI

/// A single proportional stacked bar (no labels, no taps). Segment order is
/// the caller's; values ≤ 0 collapse to zero width.
struct WidgetSegmentBar: View {
    let segments: [(color: Color, value: Double)]
    var height: CGFloat
    var corner: CGFloat = 5

    var body: some View {
        let total = segments.reduce(0) { $0 + max(0, $1.value) }
        GeometryReader { geo in
            if total > 0 {
                HStack(spacing: 0) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                        Rectangle()
                            .fill(segment.color)
                            .frame(width: CGFloat(max(0, segment.value) / total) * geo.size.width)
                    }
                }
            } else {
                Capsule().fill(Color(.tertiarySystemFill))
            }
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner, style: .continuous))
    }
}

/// The diverging imports/exports bar, mirroring the app's InterconnectorBars
/// semantics: exports (negative) on the left sorted |gw| ascending, imports
/// (positive) on the right sorted descending — largest magnitudes flank the
/// central gap — with only the outer corners rounded on each half.
struct WidgetDivergingBar: View {
    /// Net flow per segment (GW); negative = exporting.
    let flows: [(color: Color, gw: Double)]
    var height: CGFloat
    var gap: CGFloat = 6
    var corner: CGFloat = 5

    var body: some View {
        let negatives = flows.filter { $0.gw < 0 }.sorted { abs($0.gw) < abs($1.gw) }
        let positives = flows.filter { $0.gw > 0 }.sorted { abs($0.gw) > abs($1.gw) }
        let total = flows.reduce(0) { $0 + abs($1.gw) }
        let bothSides = !negatives.isEmpty && !positives.isEmpty

        GeometryReader { geo in
            if total >= 0.05 {
                let unit = (geo.size.width - (bothSides ? gap : 0)) / total
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
            } else {
                Capsule().fill(Color(.tertiarySystemFill))
            }
        }
        .frame(height: height)
    }

    private func half(
        _ items: [(color: Color, gw: Double)],
        unit: CGFloat,
        leadingRounded: Bool,
        trailingRounded: Bool
    ) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                Rectangle()
                    .fill(item.color)
                    .frame(width: CGFloat(abs(item.gw)) * unit)
            }
        }
        .frame(height: height)
        .clipShape(
            .rect(
                topLeadingRadius: leadingRounded ? corner : 0,
                bottomLeadingRadius: leadingRounded ? corner : 0,
                bottomTrailingRadius: trailingRounded ? corner : 0,
                topTrailingRadius: trailingRounded ? corner : 0
            )
        )
    }
}

/// One legend entry: colour dot + name (+ optional value). `dimmed` marks
/// zero-flow entries that are kept for a stable layout.
struct WidgetLegendItem: Identifiable {
    let id: String
    let color: Color
    let name: String
    var value: String?
    var dimmed: Bool = false
}

/// A compact left-aligned legend. Entries FLOW onto as many rows as they need
/// (rather than aligning into columns), so names render in full at full font
/// size instead of truncating or scaling to fit a column.
struct WidgetLegend: View {
    let items: [WidgetLegendItem]

    var body: some View {
        FlowLayout(horizontalSpacing: 8, verticalSpacing: 3) {
            ForEach(items) { item in
                cell(item)
            }
        }
    }

    private func cell(_ item: WidgetLegendItem) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(item.color)
                .frame(width: 7, height: 7)
            Text(item.name)
                .font(.caption2)
            if let value = item.value {
                Text(value)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .opacity(item.dimmed ? 0.45 : 1)
    }
}

/// Minimal leading-aligned wrap layout: subviews keep their natural size and
/// flow left-to-right, wrapping to a new row when the width runs out.
struct FlowLayout: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 3

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        let rows = arrange(subviews, width: width)
        let height = rows.reduce(0) { $0 + $1.height } +
            CGFloat(max(0, rows.count - 1)) * verticalSpacing
        let maxRowWidth = rows.map(\.width).max() ?? 0
        return CGSize(width: width.isFinite ? width : maxRowWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for entry in row.entries {
                subviews[entry.index].place(
                    at: CGPoint(x: x, y: y + (row.height - entry.size.height) / 2),
                    proposal: .unspecified)
                x += entry.size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Row {
        var entries: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows: [Row] = [Row()]
        var x: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                rows.append(Row())
                x = 0
            }
            rows[rows.count - 1].entries.append((index, size))
            rows[rows.count - 1].height = max(rows[rows.count - 1].height, size.height)
            x += size.width + horizontalSpacing
            rows[rows.count - 1].width = x - horizontalSpacing
        }
        return rows
    }
}
