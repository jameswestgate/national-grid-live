import SwiftUI

struct CategoryCard<Row: View>: View {
    let title: String
    let percent: Double
    let banner: Color
    @ViewBuilder var rows: Row

    var body: some View {
        Card {
            VStack(spacing: 0) {
                bannerView
                VStack(spacing: 0) {
                    rows
                }
                .padding(.vertical, 6)
            }
        }
    }

    private var bannerView: some View {
        HStack {
            Text(percentLabel + " " + title)
                .font(.appSerif(.headline, weight: .semibold))
                .foregroundStyle(Palette.headingText)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(banner)
    }

    private var percentLabel: String {
        String(format: "%.1f%%", percent * 100)
    }
}

#Preview {
    CategoryCard(
        title: "fossil fuels",
        percent: 0.464,
        banner: FuelCategory.fossil.bannerColor
    ) {
        SourceRow(label: "Gas",  swatch: FuelType.gas.swatch,  valueGW: 11.90, percent: 0.464)
        SourceRow(label: "Coal", swatch: FuelType.coal.swatch, valueGW: 0.0,   percent: 0)
    }
    .padding()
    .background(Palette.pageBackground)
    .preferredColorScheme(.dark)
}
