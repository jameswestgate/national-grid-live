//
//  WidgetSampleData.swift
//  NationalGridWidgets
//
//  A single realistic snapshot used for the gallery placeholder / previews.
//  Kept self-contained so the widget never imports the app's Mocks.
//

import Foundation

enum WidgetSampleData {
    static let grid: LiveGrid = {
        // gen (excl. pumped) = 10.8 + 9.4 + 4.2 + 2.1 + 1.4 + 0.6 = 28.5
        // transfers = interconnectors (Σ = 4.3, both directions so the
        // diverging-bar preview shows imports AND exports) + pumped (-0.3) = 4.0
        // demand = 28.5 + 4.0 = 32.5
        let fuels: [FuelType: Double] = [
            .gas: 10.8, .wind: 9.4, .nuclear: 4.2, .biomass: 2.1,
            .solar: 1.4, .hydro: 0.6, .pumped: -0.3,
        ]
        let ics: [Interconnector: Double] = [
            .france: 2.1, .norway: 1.1, .netherlands: 0.9, .belgium: 0.6,
            .ireland: -0.3, .denmark: -0.1,
        ]
        return LiveGrid(
            asOf: Date(timeIntervalSinceReferenceDate: 802_000_800), // fixed
            price: 78,
            emissions: 142,
            demand: 32.5,
            generation: 28.5,
            transfers: 4.0,
            fuels: fuels,
            interconnectors: ics
        )
    }()
}
