//
//  NationalGridWidgetsBundle.swift
//  NationalGridWidgets
//
//  Home Screen and Lock Screen widgets for National Grid: Live.
//

import WidgetKit
import SwiftUI

@main
struct NationalGridWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HomeGenerationWidget()
        HomeInterconnectorsWidget()
        DemandWidget()
        GenerationMixWidget()
        LiveMinimalWidget()
    }
}
