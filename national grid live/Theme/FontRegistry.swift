import CoreText
import Foundation
import os

enum FontRegistry {
    private static let log = Logger(subsystem: "org.crainiate.national-grid-live", category: "fonts")

    static let serifLight    = "SourceSerif4-Light"
    static let serifRegular  = "SourceSerif4-Regular"
    static let serifSemibold = "SourceSerif4-Semibold"
    static let serifBold     = "SourceSerif4-Bold"

    static func registerBundledFonts() {
        for name in [serifLight, serifRegular, serifSemibold, serifBold] {
            register(name)
        }
    }

    private static func register(_ name: String) {
        guard let url = Bundle.main.url(forResource: name, withExtension: "ttf") else {
            log.error("Font file missing from bundle: \(name)")
            return
        }
        var error: Unmanaged<CFError>?
        if !CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error) {
            let cfErr = error?.takeRetainedValue()
            log.error("Failed to register \(name): \(String(describing: cfErr))")
        }
    }
}
