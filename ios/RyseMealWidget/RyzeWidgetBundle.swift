//
//  RyzeWidgetBundle.swift
//  RyseMealWidget
//
//  The widgets of Ryze: the water on the home screen, the meals on the home
//  screen, the day on the lock screen, and the Winter Arc on both. See
//  WIDGET.md and WINTER_ARC.md at the repo root.
//

import SwiftUI
import WidgetKit

@main
struct RyzeWidgetBundle: WidgetBundle {
    var body: some Widget {
        RyzeWaterWidget()
        RyzeMealsWidget()
        RyzeTodayWidget()
        RyzeArcWidget()
    }
}
