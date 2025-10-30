//
//  RyseMealWidgetBundle.swift
//  RyseMealWidget
//
//  Created by Badis on 30/10/2025.
//

import WidgetKit
import SwiftUI

@main
struct RyseMealWidgetBundle: WidgetBundle {
    var body: some Widget {
        RyseMealWidget()
        RyseMealWidgetControl()
        RyseMealWidgetLiveActivity()
    }
}
