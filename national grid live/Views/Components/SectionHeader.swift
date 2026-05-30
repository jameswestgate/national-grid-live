import SwiftUI

/// Subtle grouped-list-style section label sitting above a group of cards
/// (e.g. "Trends"). Quiet by design — the cards carry their own inline titles.
struct SectionHeader: View {
    let title: String
    var topSpacing: CGFloat = 8

    var body: some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, topSpacing)
            .padding(.horizontal, 4)
    }
}
