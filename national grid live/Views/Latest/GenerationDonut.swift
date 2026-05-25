import SwiftUI

struct GenerationDonut: View {
    let generation: Double
    let demand: Double
    let fuels: [FuelType: Double]
    var size: CGFloat = 280

    private static let categoryOrder: [FuelCategory] = [.fossil, .renewable, .other, .storage]

    private var outerSlices: [Slice] {
        Self.categoryOrder.flatMap { category in
            FuelType.allCases
                .filter { $0.category == category }
                .compactMap { fuel in
                    guard let gw = fuels[fuel], gw > 0 else { return nil }
                    return Slice(value: gw, color: fuel.swatch)
                }
        }
    }

    private var innerSlices: [Slice] {
        Self.categoryOrder.compactMap { category in
            let total = categoryTotal(category)
            guard total > 0 else { return nil }
            return Slice(value: total, color: category.bannerColor)
        }
    }

    private func categoryTotal(_ category: FuelCategory) -> Double {
        fuels.reduce(into: 0.0) { acc, kv in
            if kv.key.category == category { acc += kv.value }
        }
    }

    private var shareOfDemand: Double {
        guard demand > 0 else { return 0 }
        return generation / demand
    }

    var body: some View {
        ZStack {
            DonutRing(slices: outerSlices, innerRadiusRatio: 0.78, outerRadiusRatio: 1.0, angularInset: .degrees(0.6))
            DonutRing(slices: innerSlices, innerRadiusRatio: 0.54, outerRadiusRatio: 0.76, angularInset: .degrees(0.6))
            centerLabel
        }
        .frame(width: size, height: size)
    }

    private var centerLabel: some View {
        VStack(spacing: 2) {
            Text("Generation").font(.appSerif(.callout)).foregroundStyle(.secondary)
            HStack(spacing: 0) {
                Text(String(format: "%.1f", generation)).font(.appSerif(.title3))
                Text("GW").font(.appSerif(.footnote)).foregroundStyle(.tertiary)
            }
            Text(String(format: "%.1f%%", shareOfDemand * 100))
                .font(.appSerif(.callout))
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
    }

    struct Slice {
        let value: Double
        let color: Color
    }
}

private struct DonutRing: View {
    let slices: [GenerationDonut.Slice]
    let innerRadiusRatio: CGFloat
    let outerRadiusRatio: CGFloat
    let angularInset: Angle

    var body: some View {
        Canvas { ctx, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let outer = radius * outerRadiusRatio
            let inner = radius * innerRadiusRatio
            let total = slices.reduce(0) { $0 + $1.value }
            guard total > 0 else { return }

            var startAngle = Angle.degrees(-90)
            for slice in slices {
                let sweep = Angle.degrees(slice.value / total * 360)
                let endAngle = startAngle + sweep
                let insetStart = startAngle + angularInset / 2
                let insetEnd = endAngle - angularInset / 2
                guard insetEnd > insetStart else {
                    startAngle = endAngle
                    continue
                }

                var path = Path()
                path.addArc(center: center, radius: outer, startAngle: insetStart, endAngle: insetEnd, clockwise: false)
                path.addArc(center: center, radius: inner, startAngle: insetEnd, endAngle: insetStart, clockwise: true)
                path.closeSubpath()
                ctx.fill(path, with: .color(slice.color))

                startAngle = endAngle
            }
        }
    }
}

#Preview {
    GenerationDonut(generation: LiveGrid.sample.generation,
                    demand: LiveGrid.sample.demand,
                    fuels: LiveGrid.sample.fuels)
        .padding()
        .background(Palette.contentBackground)
        .preferredColorScheme(.dark)
}
