import SwiftUI

struct PeriodSelector: View {
    @Binding var selection: Period

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Period.allCases) { period in
                tab(period)
            }
        }
        .background(Palette.headingBackground.opacity(0.6))
    }

    private func tab(_ period: Period) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.15)) {
                selection = period
            }
        } label: {
            ViewThatFits(in: .horizontal) {
                Text(period.displayName)
                Text(period.shortName)
            }
            .font(.headline)
            .foregroundStyle(Palette.headingText)
            .lineLimit(1)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(selection == period ? Palette.contentBackground : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var sel: Period = .day
    return PeriodSelector(selection: $sel)
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
