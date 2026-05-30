import SwiftUI

/// Quiet caption shown directly beneath the generation card (per spec):
/// e.g. "Generation time: 1:45pm" with a trailing info button that explains
/// where the figures come from.
struct GenerationCaption: View {
    let label: String
    let value: String
    var info: String? = nil

    @State private var showInfo = false

    var body: some View {
        HStack(spacing: 6) {
            Text("\(label): ")
                .foregroundStyle(.secondary)
            + Text(value)
                .foregroundStyle(.secondary)

            Spacer(minLength: 8)

            if let info {
                Button { showInfo = true } label: {
                    Image(systemName: "info.circle")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("About this data")
                .popover(isPresented: $showInfo) {
                    Text(info)
                        .font(.callout)
                        .padding()
                        .frame(maxWidth: 280)
                        .presentationCompactAdaptation(.popover)
                }
            }
        }
        .font(.footnote)
        .padding(.horizontal, 4)
        .padding(.top, 2)
    }
}

#Preview {
    GenerationCaption(
        label: "Generation time",
        value: "1:45pm",
        info: "Figures are the most recent half-hourly settlement period published by Elexon BMRS."
    )
    .padding()
    .background(Palette.pageBackground)
}
