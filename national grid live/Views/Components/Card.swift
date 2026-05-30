import SwiftUI

struct Card<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(Palette.contentBackground)
            .clipShape(RoundedRectangle(cornerRadius: Palette.cardCornerRadius, style: .continuous))
    }
}

struct CardHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title3.weight(.semibold))
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 4)
    }
}

/// Inline card title used by the Generation / Interconnectors / Storage cards:
/// the section name on the left, with an optional headline GW value stacked over
/// a secondary caption (e.g. "79.3% of demand") on the right.
struct CardSectionHeader: View {
    let title: String
    var valueGW: Double? = nil
    var caption: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)
            Spacer(minLength: 12)
            if let valueGW {
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(valueGW < 0 ? "−" + String(format: "%.1f", abs(valueGW))
                                          : String(format: "%.1f", valueGW))
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.primary)
                        Text("GW")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }
                    if let caption {
                        Text(caption)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
}
