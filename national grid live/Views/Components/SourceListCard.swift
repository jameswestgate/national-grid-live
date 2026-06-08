import SwiftUI

struct SourceListItem: Identifiable {
    let id: String
    let icon: String
    let tint: Color
    let name: String
    let gw: Double?
    let percent: Double?
    /// Optional explicit bar fill, decoupled from `percent` (see SourceRow).
    var barFraction: Double? = nil
}

/// A flat card of source rows under an inline title — used for the
/// Interconnectors and Storage sections so they share the Generation card's
/// look (heading inside the card, headline value on the right, rows below).
struct SourceListCard: View {
    let title: String
    var totalGW: Double? = nil
    var caption: String? = nil
    let items: [SourceListItem]
    /// Optional graphic shown between the header and the rows (e.g. the
    /// Interconnectors diverging bar). The Storage card passes none.
    var headerGraphic: AnyView? = nil

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardSectionHeader(title: title, valueGW: totalGW, caption: caption)
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 14)

                if let headerGraphic {
                    headerGraphic
                        .padding(.horizontal, 16)
                        .padding(.bottom, 18)
                }

                ForEach(items) { item in
                    Divider().padding(.leading, 16)
                    SourceRow(
                        icon: item.icon,
                        tint: item.tint,
                        name: item.name,
                        gw: item.gw,
                        percent: item.percent,
                        emphasised: true,
                        barOverride: item.barFraction
                    )
                    .padding(16)
                    // Scroll target for the header graphic (e.g. an
                    // interconnector bar segment tapped above).
                    .id(item.id)
                }
            }
        }
    }
}
