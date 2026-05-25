import SwiftUI

struct UpdatedAgoLabel: View {
    let asOf: Date

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            Text("Updated \(relative(at: context.date))")
                .font(.appSerif(.footnote))
                .foregroundStyle(.tertiary)
        }
    }

    private func relative(at now: Date) -> String {
        let interval = now.timeIntervalSince(asOf)
        if interval < 30 {
            return "just now"
        }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: asOf, relativeTo: now)
    }
}
