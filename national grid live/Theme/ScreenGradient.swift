import SwiftUI

/// Health-style colour wash: a soft gradient that fades to transparent, laid
/// over the neutral grouped background. Used as a top wash on the data screens.
struct ScreenGradient: View {
    /// Light-mode palette (cool, on-brand — also the app-icon gradient).
    let light: [Color]
    /// Dark-mode palette (warmer — the alternate wash).
    let dark: [Color]

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        LinearGradient(stops: stops, startPoint: .top, endPoint: .bottom)
    }

    private var palette: [Color] { scheme == .dark ? dark : light }

    private var stops: [Gradient.Stop] {
        [
            .init(color: palette[0].opacity(0.55), location: 0.00),
            .init(color: palette[1].opacity(0.42), location: 0.20),
            .init(color: palette[2].opacity(0.30), location: 0.40),
            .init(color: palette[2].opacity(0.00), location: 0.62)
        ]
    }

    /// Green→teal→blue in light mode. In dark mode, a hand-tuned "dusk" sweep —
    /// a deep violet that recedes behind the status bar, easing through orchid/rose
    /// into a warm coral — softer and more twilight-like than the raw accent hues.
    static let live = ScreenGradient(
        light: [Color(.systemGreen), Color(.systemTeal), Color(.systemBlue)],
        dark:  [
            Color(red: 0.45, green: 0.28, blue: 0.80),  // deep violet (top)
            Color(red: 0.82, green: 0.33, blue: 0.55),  // orchid / rose
            Color(red: 1.00, green: 0.56, blue: 0.35)   // warm coral / amber
        ]
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
