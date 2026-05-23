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
    var background: Color = Palette.headingBackground
    var foreground: Color = Palette.headingText

    var body: some View {
        Text(title)
            .font(.appSerif(.headline, weight: .semibold))
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(background)
    }
}

struct UnitText: View {
    let value: String
    let unit: String
    var valueFont: Font = .title3
    var unitFont: Font = .title3

    var body: some View {
        HStack(spacing: 0) {
            Text(value).font(valueFont)
            Text(unit).font(unitFont).foregroundStyle(.secondary)
        }
    }
}
