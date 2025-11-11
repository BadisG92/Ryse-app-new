//
//  RyseMealWidgetBundle.swift
//  RyseMealWidget
//
//  Widget Bundle pour le widget iOS "Mes Repas"
//

import WidgetKit
import SwiftUI

@main
struct RyseMealWidgetBundle: WidgetBundle {
    var body: some Widget {
        RyseMealWidget()
        // Note: RyseMealWidgetControl et RyseMealWidgetLiveActivity sont désactivés pour l'instant
        // Ils peuvent être réactivés plus tard si nécessaire
    }
}
