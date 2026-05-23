import SwiftUI

struct GenerationCard: View {
    let live: LiveGrid

    var body: some View {
        Card {
            VStack(spacing: 0) {
                CardHeader(title: "Generation")
                GenerationDonut(
                    generation: live.generation,
                    demand: live.demand,
                    fuels: live.fuels
                )
                .padding(16)
                Text("Note: percentages are relative to demand, so will exceed 100% if power is being exported")
                    .font(.appSerif(.footnote))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 16)
            }
        }
    }
}

#Preview {
    GenerationCard(live: .sample)
        .frame(width: 360)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
