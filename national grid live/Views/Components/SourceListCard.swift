import SwiftUI

struct SourceListItem: Identifiable {
    let id: String
    let icon: String
    let tint: Color
    let name: String
    let gw: Double?
    let percent: Double?
}

/// A flat card of source rows under an inline title — used for the
/// Interconnectors and Storage sections so they share the Generation card's
/// look (heading inside the card, headline value on the right, rows below).
struct SourceListCard: View {
    let title: String
    var totalGW: Double? = nil
    var caption: String? = nil
    let items: [SourceListItem]

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardSectionHeader(title: title, valueGW: totalGW, caption: caption)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                ForEach(items) { item in
                    Divider().padding(.leading, 16)
                    SourceRow(
                        icon: item.icon,
                        tint: item.tint,
                        name: item.name,
                        gw: item.gw,
                        percent: item.percent,
                        emphasised: true
                    )
                    .padding(16)
                }
            }
        }
    }
}
