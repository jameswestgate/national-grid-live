import SwiftUI

/// The lower half of the About screen: a "Data" card (sources/attribution for
/// the live + historical feeds) and an "Original design" card. Split into two
/// inline-titled cards so neither needs a redundant "About" header.
struct AboutSection: View {
    let sources: Snapshot.SourceAttributions?

    var body: some View {
        VStack(spacing: 16) {
            dataCard
            designCard
        }
    }

    private var dataCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: "Data")
                VStack(alignment: .leading, spacing: 12) {
                    Text("Live data is fetched directly from three public APIs. Historical aggregates are served by an open backfill snapshot.")
                        .font(.body)
                    sourceLines
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 16)
            }
        }
    }

    private var designCard: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                CardHeader(title: "Original design")
                Text("Inspired by *National Grid: Live* by Kate Morley (grid.iamkate.com), released under CC0 1.0 Universal.")
                    .font(.body)
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
