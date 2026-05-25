import SwiftUI

struct SectionHeader: View {
    let title: String
    var topSpacing: CGFloat = 8

    var body: some View {
        Text(title)
            .font(.title2.weight(.bold))
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, topSpacing)
            .padding(.horizontal, 4)
    }
}
