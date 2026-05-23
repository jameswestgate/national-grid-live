import SwiftUI

extension Font {
    static func appSerif(_ style: Font.TextStyle, weight: Font.Weight? = nil) -> Font {
        let resolvedWeight = weight ?? defaultSerifWeight(for: style)
        return .custom(serifName(for: resolvedWeight), size: serifSize(for: style), relativeTo: style)
    }

    private static func defaultSerifWeight(for style: Font.TextStyle) -> Font.Weight {
        .regular
    }

    private static func serifName(for weight: Font.Weight) -> String {
        switch weight {
        case .ultraLight, .thin, .light:
            FontRegistry.serifLight
        case .regular, .medium:
            FontRegistry.serifRegular
        case .semibold:
            FontRegistry.serifSemibold
        default:
            FontRegistry.serifBold
        }
    }

    private static func serifSize(for style: Font.TextStyle) -> CGFloat {
        switch style {
        case .largeTitle:  34
        case .title:       28
        case .title2:      22
        case .title3:      20
        case .headline:    17
        case .body:        17
        case .callout:     16
        case .subheadline: 15
        case .footnote:    13
        case .caption:     12
        case .caption2:    11
        @unknown default:  17
        }
    }
}
