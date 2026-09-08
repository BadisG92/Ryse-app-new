//
//  RyzeWidgetBundle.swift
//  RyseMealWidget
//
//  The three widgets of Ryze: the water on the home screen, the meals on the
//  home screen, the day on the lock screen. See WIDGET.md at the repo root.
//

import SwiftUI
import WidgetKit

@main
struct RyzeWidgetBundle: WidgetBundle {
    var body: some Widget {
        RyzeWaterWidget()
        RyzeMealsWidget()
        RyzeTodayWidget()
    }
}
