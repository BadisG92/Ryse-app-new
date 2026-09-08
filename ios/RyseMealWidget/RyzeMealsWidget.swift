//
//  RyzeMealsWidget.swift
//  RyseMealWidget
//
//  The home in miniature: one thing to read, what is left of the goal, and
//  the five slots of the day in their three states. Sport is a pill, a meal
//  a square, as everywhere in the app. Its kind keeps the first widget's
//  name so the widgets already placed stay where they are.
//

import SwiftUI
import WidgetKit

struct RyzeMealsWidget: Widget {
    let kind = "RyseMealWidget"

    var body: some WidgetConfiguration {
        let snapshot = WidgetStore.load()
        let lang = WidgetStore.language()

        return StaticConfiguration(kind: kind, provider: RyzeProvider()) { entry in
            MealsWidgetView(entry: entry)
        }
        .configurationDisplayName(snapshot?.string("title_meals") ?? WidgetFallback.string("title_meals", lang: lang))
        .description(snapshot?.string("desc_meals") ?? WidgetFallback.string("desc_meals", lang: lang))
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}

// MARK: - View

struct MealsWidgetView: View {
    let entry: RyzeEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            MealsView(snapshot: snapshot)
        } else {
            MealsEmptyView()
        }
    }
}

struct MealsView: View {
    let snapshot: WidgetSnapshot

    private var p: RyzePalette { snapshot.palette }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(snapshot.string(snapshot.leadKey))
                        .font(RyzeFont.body(11, weight: 600))
                        .foregroundStyle(RyzeColor.mute)
                        .lineLimit(1)
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(snapshot.figure)
                            .font(RyzeFont.display(34))
                            .tracking(RyzeFont.tracking(34))
                            .monospacedDigit()
                            .foregroundStyle(p.ink)
                        Text(snapshot.string("unit"))
                            .font(RyzeFont.body(12, weight: 600))
                            .foregroundStyle(RyzeColor.mute)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 1) {
                    Text(snapshot.eatenText)
                    Text(snapshot.goalText)
                }
                .font(RyzeFont.body(10.5))
                .monospacedDigit()
                .foregroundStyle(RyzeColor.mute)
                .lineLimit(1)
                .padding(.top, 3)
            }

            AmberGauge(fraction: snapshot.fraction, color: p.acc)
                .padding(.top, 8)

            HStack(spacing: 5) {
                ForEach(snapshot.slots, id: \.id) { slot in
                    Link(destination: Self.destination(of: slot)) {
                        SlotTile(slot: slot, palette: p)
                    }
                }
            }
            .padding(.top, 12)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .containerBackground(for: .widget) { RyzeColor.paper }
        .widgetURL(URL(string: "ryse://dashboard"))
    }

    /// A meal opens its add sheet, the session opens Sport: what the home's
    /// row of the day does for the same tap.
    static func destination(of slot: WidgetSnapshot.Slot) -> URL {
        let raw = slot.id == "sport" ? "ryse://sport" : "ryse://add-food?meal=\(slot.id)"
        return URL(string: raw) ?? URL(string: "ryse://dashboard")!
    }
}

struct MealsEmptyView: View {
    var body: some View {
        let lang = WidgetFallback.deviceLanguage
        let p = WidgetStore.palette()
        VStack(alignment: .leading, spacing: 0) {
            Text(WidgetFallback.string("desc_meals", lang: lang))
                .font(RyzeFont.body(11, weight: 600))
                .foregroundStyle(RyzeColor.mute)
                .lineLimit(1)
            Text(WidgetFallback.string("open_app", lang: lang))
                .font(RyzeFont.display(28))
                .tracking(RyzeFont.tracking(28))
                .foregroundStyle(p.ink)
                .padding(.top, 2)
            AmberGauge(fraction: 0, color: p.acc)
                .padding(.top, 8)
            Spacer(minLength: 0)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 16))
        .containerBackground(for: .widget) { RyzeColor.paper }
        .widgetURL(URL(string: "ryse://dashboard"))
    }
}

// MARK: - Slot

/// One slot: free is a white tile with a light edge, planned an ink edge,
/// done an ink fill with a check. The session is a pill, a meal a tile.
struct SlotTile: View {
    let slot: WidgetSnapshot.Slot
    let palette: RyzePalette

    private var done: Bool { slot.state == .done }
    private var planned: Bool { slot.state == .planned }
    private var fg: Color { done ? RyzeColor.paper : (planned ? palette.ink : RyzeColor.mute) }
    private var fg2: Color { done ? RyzeColor.paper.opacity(0.72) : RyzeColor.mute2 }

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: slot.id == "sport" ? RyzeRadius.pill : 10, style: .continuous)
        VStack(spacing: 2) {
            SlotIcon(slot: slot, color: fg)
                .frame(width: 14, height: 14)
            Text(slot.label)
                .font(RyzeFont.body(9.5, weight: 600))
                .foregroundStyle(fg)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(slot.word)
                .font(RyzeFont.body(8.5))
                .foregroundStyle(fg2)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(.horizontal, 2)
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(shape.fill(done ? palette.ink : RyzeColor.surf))
        .overlay(shape.stroke(done || planned ? palette.ink : palette.line, lineWidth: planned && !done ? 1.4 : 1))
    }
}

/// The slot's glyph: the same subjects as the app's Lucide icons, in SF
/// Symbols where one exists and drawn where none does.
struct SlotIcon: View {
    let slot: WidgetSnapshot.Slot
    let color: Color

    var body: some View {
        if slot.state == .done {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(color)
        } else {
            switch slot.id {
            case "breakfast":
                Image(systemName: "sunrise.fill").font(.system(size: 12, weight: .medium)).foregroundStyle(color)
            case "lunch":
                Image(systemName: "sun.max.fill").font(.system(size: 12, weight: .medium)).foregroundStyle(color)
            case "dinner":
                Image(systemName: "sunset.fill").font(.system(size: 12, weight: .medium)).foregroundStyle(color)
            case "sport":
                Image(systemName: "dumbbell.fill").font(.system(size: 12, weight: .medium)).foregroundStyle(color)
            case "snack":
                CookieIcon(color: color)
            default:
                Image(systemName: "fork.knife").font(.system(size: 12, weight: .medium)).foregroundStyle(color)
            }
        }
    }
}

/// A cookie, as Lucide draws it: a disc with a bite out of the top right
/// and three crumbs. SF Symbols has no cookie.
struct CookieIcon: View {
    let color: Color

    var body: some View {
        ZStack {
            CookieShape()
                .stroke(color, style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
            CookieCrumbs()
                .fill(color)
        }
    }
}

struct CookieShape: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2 - 1
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        // from the top, round the left and the bottom to the right: in this
        // flipped coordinate space `clockwise` draws counterclockwise on screen
        path.move(to: CGPoint(x: c.x, y: c.y - r))
        path.addArc(center: c, radius: r, startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: true)
        // the bite, two curves pulled toward the centre
        let mid = CGPoint(x: c.x + 0.5 * r, y: c.y - 0.5 * r)
        path.addQuadCurve(to: mid, control: CGPoint(x: c.x + 0.55 * r, y: c.y - 0.12 * r))
        path.addQuadCurve(to: CGPoint(x: c.x, y: c.y - r), control: CGPoint(x: c.x + 0.12 * r, y: c.y - 0.55 * r))
        path.closeSubpath()
        return path
    }
}

struct CookieCrumbs: Shape {
    func path(in rect: CGRect) -> Path {
        let r = min(rect.width, rect.height) / 2 - 1
        let c = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()
        for (dx, dy) in [(-0.38, -0.22), (0.12, 0.36), (-0.4, 0.4)] {
            let dot = CGRect(x: c.x + dx * r - 1, y: c.y + dy * r - 1, width: 2, height: 2)
            path.addEllipse(in: dot)
        }
        return path
    }
}

// MARK: - Preview

#Preview("Meals", as: .systemMedium) {
    RyzeMealsWidget()
} timeline: {
    RyzeEntry(date: .now, snapshot: .sample(lang: "fr"))
    RyzeEntry(date: .now, snapshot: nil)
}
