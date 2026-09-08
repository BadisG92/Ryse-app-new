//
//  RyzeWaterWidget.swift
//  RyseMealWidget
//
//  The day's water, as glasses: the most repeated gesture of the day, and
//  the one widget that writes without opening the app.
//

import AppIntents
import SwiftUI
import WidgetKit

struct RyzeWaterWidget: Widget {
    let kind = "RyzeWaterWidget"

    var body: some WidgetConfiguration {
        let snapshot = WidgetStore.load()
        let lang = WidgetStore.language()

        return StaticConfiguration(kind: kind, provider: RyzeProvider()) { entry in
            WaterWidgetView(entry: entry)
        }
        .configurationDisplayName(snapshot?.string("title_water") ?? WidgetFallback.string("title_water", lang: lang))
        .description(snapshot?.string("desc_water") ?? WidgetFallback.string("desc_water", lang: lang))
        .supportedFamilies([.systemSmall])
        .contentMarginsDisabled()
    }
}

// MARK: - View

struct WaterWidgetView: View {
    let entry: RyzeEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            WaterView(snapshot: snapshot)
        } else {
            WaterEmptyView()
        }
    }
}

/// On the edition's paper, in its text and greys. Goal reached, the tile
/// turns to ink and everything on it to the card colour, exactly as the
/// water tile of the home does. No check, no green: the state is the ground.
struct WaterView: View {
    let snapshot: WidgetSnapshot

    private var p: RyzePalette { snapshot.palette }
    private var full: Bool { snapshot.waterFull }
    private var fg: Color { full ? p.onInk : p.text }
    private var fg2: Color { full ? p.onInk.opacity(0.72) : p.mute }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text(snapshot.string("water"))
                    .font(RyzeFont.body(11, weight: 600))
                    .foregroundStyle(fg2)
                Spacer(minLength: 4)
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(snapshot.waterText)
                        .font(RyzeFont.display(17))
                        .tracking(RyzeFont.tracking(17))
                        .monospacedDigit()
                        .foregroundStyle(fg)
                    Text(snapshot.waterGoalText)
                        .font(RyzeFont.body(12, weight: 600))
                        .foregroundStyle(fg2)
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            GlassRow(
                full: snapshot.glasses,
                goal: snapshot.goalGlasses,
                ink: full ? p.onInk : p.ink,
                nextEdge: full ? p.onInk.opacity(0.55) : p.mute2,
                emptyEdge: full ? p.onInk.opacity(0.3) : p.line
            )
            .frame(height: 34)

            Spacer(minLength: 8)

            HStack(spacing: 6) {
                Button(intent: AddWaterIntent(glasses: 1)) {
                    Text(snapshot.string("glass_one"))
                        .font(RyzeFont.body(11.5, weight: 600))
                        .foregroundStyle(full ? p.ink : p.onInk)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Capsule().fill(full ? p.surf : p.ink))
                }
                .buttonStyle(.plain)

                Button(intent: AddWaterIntent(glasses: 2)) {
                    Text(snapshot.string("glass_two"))
                        .font(RyzeFont.body(11.5, weight: 600))
                        .foregroundStyle(fg)
                        .frame(width: 44, height: 28)
                        .background(
                            Capsule().fill(full ? Color.clear : p.surf)
                        )
                        .overlay(
                            Capsule().stroke(full ? p.onInk.opacity(0.35) : p.line, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .containerBackground(for: .widget) {
            full ? p.ink : p.paper
        }
        .widgetURL(URL(string: "ryse://dashboard"))
    }
}

/// Before the app has written anything: the glasses, empty, and the one
/// thing to do.
struct WaterEmptyView: View {
    var body: some View {
        let lang = WidgetFallback.deviceLanguage
        let p = WidgetStore.palette()
        VStack(alignment: .leading, spacing: 0) {
            Text(WidgetFallback.string("water", lang: lang))
                .font(RyzeFont.body(11, weight: 600))
                .foregroundStyle(p.mute)
            Spacer(minLength: 8)
            GlassRow(full: 0, goal: 8, ink: p.ink, nextEdge: p.line, emptyEdge: p.line)
                .frame(height: 34)
            Spacer(minLength: 8)
            Text(WidgetFallback.string("open_app", lang: lang))
                .font(RyzeFont.display(15))
                .tracking(RyzeFont.tracking(15))
                .foregroundStyle(p.text)
        }
        .padding(14)
        .containerBackground(for: .widget) { p.paper }
        .widgetURL(URL(string: "ryse://dashboard"))
    }
}

// MARK: - Glasses

/// The glasses of the app's own row: filled in ink, the next one carrying
/// the plus, the rest an outline. The goal decides how many there are.
struct GlassRow: View {
    let full: Int
    let goal: Int
    let ink: Color
    let nextEdge: Color
    let emptyEdge: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(0 ..< max(goal, 1), id: \.self) { index in
                GlassView(
                    state: index < full ? .full : (index == full ? .next : .empty),
                    ink: ink,
                    nextEdge: nextEdge,
                    emptyEdge: emptyEdge
                )
            }
        }
    }
}

struct GlassView: View {
    enum Fill { case full, next, empty }

    let state: Fill
    let ink: Color
    let nextEdge: Color
    let emptyEdge: Color

    var body: some View {
        ZStack {
            if state == .full {
                // the water sits a little under the rim, which is what makes
                // it read as a liquid in a glass rather than a filled shape
                Rectangle()
                    .fill(ink)
                    .padding(.top, 3)
                    .clipShape(GlassShape())
            }
            GlassOutline()
                .stroke(
                    state == .full ? ink : (state == .next ? nextEdge : emptyEdge),
                    style: StrokeStyle(lineWidth: 1.4, lineJoin: .round)
                )
            if state == .next {
                Image(systemName: "plus")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(nextEdge)
                    .offset(y: 1)
            }
        }
        .aspectRatio(18 / 34, contentMode: .fit)
    }
}

/// A glass, drawn: a trunk of a cone, narrower at the foot than at the rim.
/// That taper is what makes a glass rather than a rectangle.
struct GlassShape: Shape {
    static let taper: CGFloat = 0.14

    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: 0.7, dy: 0.7)
        var path = Path()
        path.move(to: CGPoint(x: inset.minX, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.minX + inset.width * Self.taper, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.maxX - inset.width * Self.taper, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.minY))
        path.closeSubpath()
        return path
    }
}

/// The outline: two sides and a bottom, and nothing on top. A glass is open.
struct GlassOutline: Shape {
    func path(in rect: CGRect) -> Path {
        let inset = rect.insetBy(dx: 0.7, dy: 0.7)
        var path = Path()
        path.move(to: CGPoint(x: inset.minX, y: inset.minY))
        path.addLine(to: CGPoint(x: inset.minX + inset.width * GlassShape.taper, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.maxX - inset.width * GlassShape.taper, y: inset.maxY))
        path.addLine(to: CGPoint(x: inset.maxX, y: inset.minY))
        return path
    }
}

// MARK: - Preview

#Preview("Water", as: .systemSmall) {
    RyzeWaterWidget()
} timeline: {
    RyzeEntry(date: .now, snapshot: .sample(lang: "fr"))
    RyzeEntry(date: .now, snapshot: nil)
}
