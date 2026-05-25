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
