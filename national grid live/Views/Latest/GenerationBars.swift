import SwiftUI
import UIKit

/// The generation mix as two stacked proportional bars — the double-donut's two
/// rings "unrolled" into straight lines. The top bar is the three category totals
/// (`FuelCategory.bannerColor`), the bottom bar the individual fuels
/// (`FuelType.swatch`). Both bars span the same width over the same grand total,
/// so each fuel segment sits directly under its category segment. Each segment
/// carries its name inside it; tapping one expands+scrolls to that group/fuel.
struct GenerationBars: View {
    let fuels: [FuelType: Double]
    var onSelect: (Selection) -> Void = { _ in }

    enum Selection: Equatable {
        case fuel(FuelType)
        case category(FuelCategory)
    }

    /// Only the three generation groups — matches the card's rows.
    private static let categoryOrder: [FuelCategory] = [.fossil, .renewable, .other]

    private let barHeight: CGFloat = 30
    private let spacing: CGFloat = 4          // "closely vertically aligned"
    private let labelMinWidth: CGFloat = 38   // hide the label below this segment width

    private struct Segment<Payload> {
        let value: Double
        let color: Color
        let label: String
        let payload: Payload
    }

    var body: some View {
        VStack(spacing: spacing) {
            bar(categorySegments) { onSelect(.category($0)) }
            bar(fuelSegments) { onSelect(.fuel($0)) }
        }
        .accessibilityHidden(true) // figures + colours are exposed by the rows below
    }

    // MARK: Bar

    private func bar<P>(_ segments: [Segment<P>], onTap: @escaping (P) -> Void) -> some View {
        let total = segments.reduce(0) { $0 + max(0, $1.value) }
        return GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(Array(segments.enumerated()), id: \.offset) { _, segment in
                    let width = total > 0 ? CGFloat(max(0, segment.value) / total) * geo.size.width : 0
                    ZStack {
                        Rectangle().fill(segment.color)
                        if width >= labelMinWidth {
                            Text(segment.label)
                                .font(.caption2.weight(.semibold))
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                                .foregroundStyle(textColor(on: segment.color))
                                .padding(.horizontal, 3)
                        }
                    }
                    .frame(width: width)
                    .contentShape(Rectangle())
                    .onTapGesture { onTap(segment.payload) }
                }
            }
        }
        .frame(height: barHeight)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    // MARK: Segments

    private var categorySegments: [Segment<FuelCategory>] {
        Self.categoryOrder.compactMap { category in
            let total = categoryTotal(category)
            return total > 0 ? Segment(value: total, color: category.bannerColor,
                                       label: label(for: category), payload: category) : nil
        }
    }

    private var fuelSegments: [Segment<FuelType>] {
        Self.categoryOrder.flatMap { category in
            FuelType.allCases
                .filter { $0.category == category }
                .compactMap { fuel -> Segment<FuelType>? in
                    let gw = fuels[fuel] ?? 0
                    return gw > 0 ? Segment(value: gw, color: fuel.swatch,
                                            label: label(for: fuel), payload: fuel) : nil
                }
        }
    }

    private func categoryTotal(_ category: FuelCategory) -> Double {
        FuelType.allCases
            .filter { $0.category == category }
            .reduce(0) { $0 + (fuels[$1] ?? 0) }
    }

    // MARK: Labels

    private func label(for category: FuelCategory) -> String {
        switch category {
        case .fossil:    "Fossil"
        case .renewable: "Renewables"
        case .other:     "Other"
        case .storage:   "Storage"
        }
    }

    private func label(for fuel: FuelType) -> String {
        fuel == .hydro ? "Hydro" : fuel.displayName
    }

    /// Pick black or white text for legibility against the segment's fill.
    private func textColor(on color: Color) -> Color {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a) else { return .white }
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        return luminance > 0.62 ? .black : .white
    }
}

#Preview {
    GenerationBars(fuels: LiveGrid.sample.fuels)
        .padding()
        .background(Palette.contentBackground)
}
