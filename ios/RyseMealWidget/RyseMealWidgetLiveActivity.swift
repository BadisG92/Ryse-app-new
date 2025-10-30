//
//  RyseMealWidgetLiveActivity.swift
//  RyseMealWidget
//
//  Created by Badis on 30/10/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct RyseMealWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct RyseMealWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RyseMealWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension RyseMealWidgetAttributes {
    fileprivate static var preview: RyseMealWidgetAttributes {
        RyseMealWidgetAttributes(name: "World")
    }
}

extension RyseMealWidgetAttributes.ContentState {
    fileprivate static var smiley: RyseMealWidgetAttributes.ContentState {
        RyseMealWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: RyseMealWidgetAttributes.ContentState {
         RyseMealWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: RyseMealWidgetAttributes.preview) {
   RyseMealWidgetLiveActivity()
} contentStates: {
    RyseMealWidgetAttributes.ContentState.smiley
    RyseMealWidgetAttributes.ContentState.starEyes
}
