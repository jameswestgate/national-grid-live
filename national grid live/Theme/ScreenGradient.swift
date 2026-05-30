import SwiftUI

/// Health-style colour wash: a soft gradient that fades to transparent, laid
/// over the neutral grouped background. Used as a top wash on the data screens.
struct ScreenGradient: View {
    let colors: [Color]

    var body: some View {
        LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    private var stops: [Gradient.Stop] {
        [
            .init(color: colors[0].opacity(0.55), location: 0.00),
            .init(color: colors[1].opacity(0.42), location: 0.20),
            .init(color: colors[2].opacity(0.30), location: 0.40),
            .init(color: colors[2].opacity(0.00), location: 0.62)
        ]
    }

    /// Cool, fresh, on-brand wash used across the app — also the app-icon gradient.
    static let live = ScreenGradient(
        colors: [Color(.systemGreen), Color(.systemTeal), Color(.systemBlue)]
    )
}

extension View {
    /// Fixed Health-style top wash: the colour gradient over the neutral grouped
    /// background, pinned to the screen. As the scroll view scrolls, the wash
    /// fades out via alpha (uniformly), so the neutral background comes through
    /// evenly rather than sliding in from the top. Apply to the scroll view.
    func washBackground(_ gradient: ScreenGradient = .live) -> some View {
        modifier(WashBackgroundModifier(gradient: gradient))
    }
}

private struct WashBackgroundModifier: ViewModifier {
    let gradient: ScreenGradient
    /// Distance (pt) over which the wash fully fades as you scroll.
    private let fadeDistance: CGFloat = 260
    @State private var washOpacity: Double = 1

    func body(content: Content) -> some View {
        content
            .background {
                ZStack {
                    Palette.pageBackground
                    gradient.opacity(washOpacity)
                }
                .ignoresSafeArea()
            }
            .onScrollGeometryChange(for: CGFloat.self) { geo in
                geo.contentOffset.y + geo.contentInsets.top
            } action: { _, scrolled in
                washOpacity = Double(max(0, min(1, 1 - scrolled / fadeDistance)))
            }
    }
}
