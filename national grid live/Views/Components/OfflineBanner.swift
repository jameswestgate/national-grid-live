import SwiftUI

struct OfflineBanner: View {
    let message: String
    let onRetry: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("Couldn't refresh")
                    .font(.callout.weight(.semibold))
                Text(message)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 8)
            Button("Retry", action: onRetry)
                .font(.footnote.weight(.semibold))
                .buttonStyle(.borderedProminent)
                .tint(.orange)
                .controlSize(.small)
        }
        .padding(12)
        .background(Color.orange.opacity(0.15))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.orange.opacity(0.4), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    OfflineBanner(message: "The Internet connection appears to be offline.") {}
        .padding()
        .background(Palette.pageBackground)
        .preferredColorScheme(.dark)
}
