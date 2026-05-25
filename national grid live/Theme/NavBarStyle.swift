import UIKit

enum NavBarStyle {
    static func configure() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()

        let largeFont = UIFont(name: FontRegistry.serifRegular, size: 34) ??
            UIFont.systemFont(ofSize: 34, weight: .regular)
        let inlineFont = UIFont(name: FontRegistry.serifSemibold, size: 17) ??
            UIFont.systemFont(ofSize: 17, weight: .semibold)

        appearance.largeTitleTextAttributes = [.font: largeFont]
        appearance.titleTextAttributes = [.font: inlineFont]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
    }
}
