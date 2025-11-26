//
//  RyseMealWidgetBundle.swift
//  RyseMealWidget
//
//  Widget Bundle pour les widgets iOS Ryse
//

import WidgetKit
import SwiftUI

@main
struct RyseMealWidgetBundle: WidgetBundle {
    var body: some Widget {
        // Widget Home Screen - Repas et calories
        RyseMealWidget()

        // Widget Lock Screen - Coach avec calories, macros et message personnalisé
        RyseCoachWidget()

        // Note: RyseMealWidgetControl et RyseMealWidgetLiveActivity sont désactivés pour l'instant
        // Ils peuvent être réactivés plus tard si nécessaire
    }
}
