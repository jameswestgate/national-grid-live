import SwiftUI

enum Palette {
    static let pageBackground = Color.dynamic(light: 0xEEEEEE, dark: 0x000000)
    static let contentBackground = Color.dynamic(light: 0xFFFFFF, dark: 0x222222)
    static let contentText = Color.dynamic(light: 0x000000, dark: 0xEEEEEE)
    static let headingBackground = Color.dynamic(light: 0xAAAAAA, dark: 0x444444)
    static let headingText = Color(white: 1)
    static let graphLine = Color.dynamic(light: 0xBBBBBB, dark: 0x444444)
    static let tableStripe = Color.dynamic(light: 0xF8F8F8, dark: 0x181818)
    static let accent = Color(red: 0x66 / 255, green: 0x99 / 255, blue: 0x66 / 255)
    static let unitOpacity: Double = 0.4
    static let unitOpacityDark: Double = 0.6
    static let cardCornerRadius: CGFloat = 4
}

extension Color {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        })
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        let r = CGFloat((hex >> 16) & 0xFF) / 255
        let g = CGFloat((hex >>  8) & 0xFF) / 255
        let b = CGFloat( hex        & 0xFF) / 255
        self.init(red: r, green: g, blue: b, alpha: 1)
    }
}
