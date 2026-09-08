//
//  RyzeTodayWidget.swift
//  RyseMealWidget
//
//  The lock screen: what is left of the goal, its gauge, and the coach's
//  line for this hour, the same one the home would say. iOS renders these
//  widgets in vibrant monochrome, so the gauge is white here: the one place
//  amber cannot be, and the system decides it. Its kind keeps the first
//  lock-screen widget's name so nothing already placed is lost.
//

import SwiftUI
import WidgetKit

struct RyzeTodayWidget: Widget {
    let kind = "RyseCoachWidget"

    var body: some WidgetConfiguration {
        let snapshot = WidgetStore.load()
        let lang = WidgetStore.language()

        return StaticConfiguration(kind: kind, provider: RyzeProvider()) { entry in
            TodayWidgetView(entry: entry)
        }
        .configurationDisplayName(snapshot?.string("title_today") ?? WidgetFallback.string("title_today", lang: lang))
        .description(snapshot?.string("desc_today") ?? WidgetFallback.string("desc_today", lang: lang))
        .supportedFamilies([.accessoryRectangular, .accessoryCircular, .accessoryInline])
        // the system's margins took the second line of the coach's sentence;
        // the rectangular view pads itself instead
        .contentMarginsDisabled()
    }
}

// MARK: - View

struct TodayWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: RyzeEntry

    var body: some View {
        Group {
            switch family {
            case .accessoryCircular:
                TodayCircularView(entry: entry)
            case .accessoryInline:
                TodayInlineView(entry: entry)
            default:
                TodayRectangularView(entry: entry)
            }
        }
        .padding(family == .accessoryRectangular ? EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8) : EdgeInsets())
        .containerBackground(for: .widget) { AccessoryWidgetBackground() }
        .widgetURL(URL(string: "ryse://dashboard"))
    }
}

struct TodayRectangularView: View {
    let entry: RyzeEntry

    var body: some View {
        if let s = entry.snapshot {
            // The case is two of the four slots under the clock, about 160 by
            // 72 points, and iOS has nothing wider. The coach's sentence is
            // the one thing here the figure cannot say, so it gets its two
            // lines first: the figure and the gauge are kept short, and the
            // sentence wins the height when the layout is tight.
            VStack(alignment: .leading, spacing: 1) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(s.figure)
                        .font(RyzeFont.display(16))
                        .tracking(RyzeFont.tracking(16))
                        .monospacedDigit()
                    Text(s.string(s.shortKey))
                        .font(RyzeFont.body(10.5, weight: 600))
                        .opacity(0.85)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: false, vertical: true)

                LockGauge(fraction: s.fraction, height: 4)
                    .padding(.vertical, 1)

                if let caption = s.caption(at: entry.date) {
                    Text(caption)
                        .font(RyzeFont.body(10))
                        .lineSpacing(0)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                        .opacity(0.82)
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        } else {
            VStack(alignment: .leading, spacing: 2) {
                Text("Ryze")
                    .font(RyzeFont.display(16))
                    .tracking(RyzeFont.tracking(16))
                Text(WidgetFallback.string("open_app", lang: WidgetFallback.deviceLanguage))
                    .font(RyzeFont.body(11))
                    .opacity(0.82)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct TodayCircularView: View {
    let entry: RyzeEntry

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.25), lineWidth: 5)
            Circle()
                .trim(from: 0, to: entry.snapshot?.fraction ?? 0)
                .stroke(Color.white, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .rotationEffect(.degrees(-90))
            VStack(spacing: 1) {
                Text(entry.snapshot?.figure ?? "—")
                    .font(RyzeFont.display(15))
                    .tracking(RyzeFont.tracking(15))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(entry.snapshot?.string("unit") ?? "kcal")
                    .font(RyzeFont.body(8, weight: 600))
                    .opacity(0.85)
            }
            .padding(.horizontal, 9)
        }
        .padding(3)
    }
}

struct TodayInlineView: View {
    let entry: RyzeEntry

    var body: some View {
        if let s = entry.snapshot {
            Text("\(s.figure) \(s.string(s.shortKey)) · \(s.glassesOf)")
        } else {
            Text("Ryze")
        }
    }
}

/// The gauge of the lock screen, white on a quarter of white.
struct LockGauge: View {
    let fraction: Double
    var height: CGFloat = 5

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.25))
                Capsule()
                    .fill(Color.white)
                    .frame(width: max(0, geometry.size.width * min(max(fraction, 0), 1)))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Preview

#Preview("Today", as: .accessoryRectangular) {
    RyzeTodayWidget()
} timeline: {
    RyzeEntry(date: .now, snapshot: .sample(lang: "fr"))
    RyzeEntry(date: .now, snapshot: nil)
}
