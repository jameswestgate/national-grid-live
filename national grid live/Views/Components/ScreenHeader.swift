import SwiftUI
import UIKit

/// Large-title heading rendered inside the scroll content (not the navigation
/// bar) so it scrolls away with the page. Optional trailing action shows a plain
/// settings icon vertically centred on the title's lowercase letters.
struct ScreenHeader: View {
    let title: String
    var onSettings: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .center) {
            Text(title)
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.primary)
                .accessibilityAddTraits(.isHeader)
                // Align the trailing icon to the lowercase optical centre (middle
                // of the "e") rather than the taller cap-height box centre.
                .alignmentGuide(VerticalAlignment.center) { dims in
                    dims[.firstTextBaseline] - Self.titleXHeight / 2
                }

            Spacer(minLength: 12)

            if let onSettings {
                Button(action: onSettings) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.title2)
                        .foregroundStyle(.primary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Settings")
            }
        }
    }

    /// x-height of the large-title font — the icon's centre lands half this above
    /// the baseline, i.e. the middle of the lowercase glyphs.
    private static var titleXHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .largeTitle).xHeight
    }
}
