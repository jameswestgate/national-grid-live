import SwiftUI

struct AboutSection: View {
    let sources: Snapshot.SourceAttributions?

    var body: some View {
        Card {
            VStack(spacing: 0) {
                CardHeader(title: "About")
                VStack(alignment: .leading, spacing: 14) {
                    subhead("Data")
                    Text("Live data is fetched directly from three public APIs. Historical aggregates are served by an open backfill snapshot.")
                        .font(.body)

                    sourceLines

                    subhead("Original design")
                    Text("Inspired by *National Grid: Live* by Kate Morley (grid.iamkate.com), released under CC0 1.0 Universal.")
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
        }
    }

    private func subhead(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .padding(.top, 6)
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
    AboutSection(sources: Snapshot.sample.sources)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}

#Preview("No snapshot") {
    AboutSection(sources: nil)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
