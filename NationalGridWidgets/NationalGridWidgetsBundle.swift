//
//  NationalGridWidgetsBundle.swift
//  NationalGridWidgets
//
//  Lock Screen widgets for National Grid: Live.
//

import WidgetKit
import SwiftUI

@main
struct NationalGridWidgetsBundle: WidgetBundle {
    var body: some Widget {
        DemandWidget()
        GenerationMixWidget()
        LiveMinimalWidget()
    }
}
