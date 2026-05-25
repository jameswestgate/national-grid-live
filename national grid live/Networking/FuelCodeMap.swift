import Foundation

/// Maps Elexon FUELINST `fuelType` codes to our app's `FuelType` / `Interconnector`
/// enums. The site groups multiple Elexon codes together (e.g. France has three
/// physical interconnector cables — IFA, IFA2 and ELECLINK — that we report as
/// a single `.france` total).
enum FuelCodeMap {
    static func fuel(for code: String) -> FuelType? {
        switch code {
        case "CCGT", "OCGT", "OIL": .gas        // all fossil-gas/oil grouped as gas
        case "COAL":     .coal
        case "WIND":     .wind
        case "NPSHYD":   .hydro
        case "NUCLEAR":  .nuclear
        case "BIOMASS":  .biomass
        case "PS":       .pumped                 // pumped storage
        case "BESS":     nil                     // battery — site groups separately under storage
        case "OTHER":    nil
        default:         nil
        }
    }

    static func interconnector(for code: String) -> Interconnector? {
        switch code {
        case "INTFR", "INTIFA2", "INTELEC":   .france   // IFA + IFA2 + ELECLINK
        case "INTIRL", "INTEW", "INTGRNL":    .ireland  // Moyle + East-West + Greenlink
        case "INTNED", "INTBRITNED":          .netherlands
        case "INTNEM":                        .belgium
        case "INTNSL":                        .norway   // North Sea Link
        case "INTVKL":                        .denmark  // Viking Link
        default:                              nil
        }
    }

    /// True when the code is "OTHER" or "BESS" — solely used to silence "unrecognised"
    /// errors for codes we know about but don't expose individually.
    static func isKnownButUngrouped(_ code: String) -> Bool {
        code == "OTHER" || code == "BESS"
    }
}
