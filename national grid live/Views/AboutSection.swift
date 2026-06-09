import SwiftUI

/// The top card of the About screen. States what the app is and that it is an
/// independent project — not affiliated with National Grid or any government
/// body — then folds in the data sources/attribution and the original-design
/// credit (previously two separate "Data" and "Original design" cards).
struct AboutSection: View {
    let sources: Snapshot.SourceAttributions?

    var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: "About this app")
                VStack(alignment: .leading, spacing: 12) {
                    Text("National Grid: Live is an independent app that shows publicly available data about how Great Britain's electricity is generated. It is not affiliated with, endorsed by, or connected to National Grid plc, the National Energy System Operator (NESO), Elexon, or any government body, and it does not represent or provide any government service.")
                        .font(.body)
                    Text("All of the data shown is open and free to use. Live readings are fetched directly from three public APIs; historical aggregates are served by an open backfill snapshot.")
                        .font(.body)
                    sourceLines
                    Text("Inspired by *National Grid: Live* by Kate Morley (grid.iamkate.com), released under CC0 1.0 Universal.")
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        }
    }

    @ViewBuilder
    private var sourceLines: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let s = sources {
                bullet(s.elexon)
                bullet(s.carbonIntensity)
                bullet(s.neso)
            } else {
                bullet("Elexon BMRS Insights")
                bullet("Carbon Intensity API © National Grid ESO and University of Oxford (CC BY 4.0)")
                bullet("NESO Data Portal (NESO Open Licence)")
            }
        }
    }

    private func bullet(_ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("·")
                .font(.body.bold())
                .foregroundStyle(.secondary)
            Text(text)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview("With sources") {
    ScrollView {
        AboutSection(sources: Snapshot.sample.sources)
            .padding()
    }
    .background(Palette.pageBackground)
}

#Preview("No snapshot") {
    ScrollView {
        AboutSection(sources: nil)
            .padding()
    }
    .background(Palette.pageBackground)
}
