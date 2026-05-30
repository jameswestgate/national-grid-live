import SwiftUI

/// Compact double-donut for the Generation card: the outer ring is the
/// individual fuels (`FuelType.swatch`), the inner ring the three category
/// totals (`FuelCategory.bannerColor`). Both rings share the same grand total,
/// so each fuel arc nests exactly inside its category arc.
///
/// Label-free — the rows beneath the card name every source and give its colour
/// and figures. Tapping a slice reports the fuel (outer) or category (inner).
struct GenerationDonut: View {
    let fuels: [FuelType: Double]
    var size: CGFloat = 198
    var onSelect: (GenerationSelection) -> Void = { _ in }

    /// Only the three generation groups — matches the card's rows.
    private static let categoryOrder: [FuelCategory] = [.fossil, .renewable, .other]

    // Ring extents as fractions of the radius (outer edge = 1.0). The two bands
    // sit close together so only a thin hairline separates the rings.
    private static let outerBand: ClosedRange<CGFloat> = 0.72...1.0
    private static let innerBand: ClosedRange<CGFloat> = 0.44...0.705

    private struct Arc<Payload> {
        let start: Angle
        let end: Angle
        let color: Color
        let payload: Payload
    }

    var body: some View {
        let radius = size / 2
        let outer = outerArcs
        let inner = innerArcs
        ZStack {
            ring(outer, band: Self.outerBand, radius: radius)
            ring(inner, band: Self.innerBand, radius: radius)
        }
        .frame(width: size, height: size)
        .contentShape(Circle())
        .gesture(
            SpatialTapGesture()
                .onEnded { value in handleTap(at: value.location, radius: radius, outer: outer, inner: inner) }
        )
        .accessibilityHidden(true) // figures + colours are exposed by the rows below
    }

    // MARK: Slices → arcs

    private var outerArcs: [Arc<FuelType>] {
        arcs(from: Self.categoryOrder.flatMap { category in
            FuelType.allCases
                .filter { $0.category == category }
                .compactMap { fuel -> (Double, Color, FuelType)? in
                    let gw = fuels[fuel] ?? 0
                    return gw > 0 ? (gw, fuel.swatch, fuel) : nil
                }
        })
    }

    private var innerArcs: [Arc<FuelCategory>] {
        arcs(from: Self.categoryOrder.compactMap { category -> (Double, Color, FuelCategory)? in
            let total = categoryTotal(category)
            return total > 0 ? (total, category.bannerColor, category) : nil
        })
    }

    private func categoryTotal(_ category: FuelCategory) -> Double {
        FuelType.allCases
            .filter { $0.category == category }
            .reduce(0) { $0 + (fuels[$1] ?? 0) }
    }

    private func arcs<P>(from slices: [(value: Double, color: Color, payload: P)]) -> [Arc<P>] {
        let total = slices.reduce(0) { $0 + $1.value }
        guard total > 0 else { return [] }
        var start = Angle.degrees(-90) // 12 o'clock
        return slices.map { slice in
            let sweep = Angle.degrees(slice.value / total * 360)
            let arc = Arc(start: start, end: start + sweep, color: slice.color, payload: slice.payload)
            start = start + sweep
            return arc
        }
    }

    // MARK: Rendering

    private func ring<P>(_ arcs: [Arc<P>], band: ClosedRange<CGFloat>, radius: CGFloat) -> some View {
        Canvas { ctx, sz in
            let center = CGPoint(x: sz.width / 2, y: sz.height / 2)
            let outer = radius * band.upperBound
            let inner = radius * band.lowerBound
            let inset = Angle.degrees(0.8) // hairline gap between slices
            for arc in arcs {
                let s = arc.start + inset / 2
                let e = arc.end - inset / 2
                guard e > s else { continue }
                var path = Path()
                path.addArc(center: center, radius: outer, startAngle: s, endAngle: e, clockwise: false)
                path.addArc(center: center, radius: inner, startAngle: e, endAngle: s, clockwise: true)
                path.closeSubpath()
                ctx.fill(path, with: .color(arc.color))
            }
        }
    }

    // MARK: Hit-testing

    private func handleTap(at location: CGPoint, radius: CGFloat, outer: [Arc<FuelType>], inner: [Arc<FuelCategory>]) {
        let dx = location.x - radius
        let dy = location.y - radius
        let distance = hypot(dx, dy) / radius          // 0 (centre) … 1 (edge)
        let angle = tapAngle(dx: dx, dy: dy)            // degrees, same convention as the arcs

        if Self.innerBand.contains(distance) {
            if let hit = inner.first(where: { contains($0, angle) }) { onSelect(.category(hit.payload)) }
        } else if Self.outerBand.contains(distance) {
            if let hit = outer.first(where: { contains($0, angle) }) { onSelect(.fuel(hit.payload)) }
        }
    }

    /// atan2 in screen coordinates (y points down) increases clockwise, with 0°
    /// at 3 o'clock — the same frame the arcs are laid out in (start −90° = top).
    private func tapAngle(dx: CGFloat, dy: CGFloat) -> Double {
        var degrees = atan2(dy, dx) * 180 / .pi
        if degrees < 0 { degrees += 360 }
        return degrees
    }

    private func contains<P>(_ arc: Arc<P>, _ angle: Double) -> Bool {
        let start = normalize(arc.start.degrees)
        let end = normalize(arc.end.degrees)
        if start <= end { return angle >= start && angle < end }
        return angle >= start || angle < end // arc wraps past 360°
    }

    private func normalize(_ degrees: Double) -> Double {
        var d = degrees.truncatingRemainder(dividingBy: 360)
        if d < 0 { d += 360 }
        return d
    }
}

#Preview {
    GenerationDonut(fuels: LiveGrid.sample.fuels)
        .padding()
        .background(Palette.contentBackground)
}
