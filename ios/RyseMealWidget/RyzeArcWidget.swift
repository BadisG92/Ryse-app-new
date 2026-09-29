//
//  RyzeArcWidget.swift
//  RyseMealWidget
//
//  The Winter Arc: the day of the series out of 90, the word of the day in
//  thick letters, the ice flame and the snow. Every word comes from the
//  app's `arc` block (lib/arc/arc_widget_data.dart); the widget only lays it
//  out on the season's night. The snow falls and the flame drifts with
//  WidgetKit's clock-hand rotation (see ClockHand).
//

import SwiftUI
import WidgetKit

struct RyzeArcWidget: Widget {
    let kind = "RyzeArcWidget"

    var body: some WidgetConfiguration {
        let json = WidgetStore.raw()
        let strings = json?["strings"] as? [String: String]
        let lang = WidgetStore.language()

        return StaticConfiguration(kind: kind, provider: ArcProvider()) { entry in
            ArcWidgetView(entry: entry)
        }
        .configurationDisplayName(strings?["title_arc"] ?? WidgetFallback.string("title_arc", lang: lang))
        .description(strings?["desc_arc"] ?? WidgetFallback.string("desc_arc", lang: lang))
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryRectangular])
        .contentMarginsDisabled()
    }
}

// MARK: - Snapshot

/// The `arc` block, read for one day.
struct ArcSnapshot {
    enum Cell {
        case held, trained, joker, pending, idle
    }

    let soon: Bool
    let day: Int
    let held: Bool
    let cells: [Cell]
    let tag: String
    let status: String
    let lock: String

    /// The app wrote on an earlier day and has not been opened since: the
    /// widget cannot know whether yesterday was held, so it keeps the series
    /// as it was and asks for the app.
    let stale: Bool

    static let length = 90

    var fraction: Double { min(max(Double(day) / Double(Self.length), 0), 1) }

    static func parse(_ json: [String: Any], today: String) -> ArcSnapshot? {
        guard WidgetSnapshot.int(json["v"]) >= 2, let arc = json["arc"] as? [String: Any] else { return nil }
        let stale = (json["day"] as? String ?? "") != today
        let held = (arc["held"] as? Bool ?? false) && !stale
        let letters = Array((arc["cells"] as? String ?? "").prefix(length))
        let cells = (0..<length).map { i -> Cell in
            guard i < letters.count else { return .idle }
            switch letters[i] {
            case "h": return .held
            case "t": return .trained
            case "j": return .joker
            case "p": return .pending
            default: return .idle
            }
        }
        return ArcSnapshot(
            soon: arc["soon"] as? Bool ?? false,
            day: WidgetSnapshot.int(arc["day"]),
            held: held,
            cells: cells,
            tag: stale ? (arc["tag_open"] as? String ?? arc["tag"] as? String ?? "") : (arc["tag"] as? String ?? ""),
            status: stale ? (arc["stale"] as? String ?? "") : (arc["status"] as? String ?? ""),
            lock: arc["lock"] as? String ?? "",
            stale: stale
        )
    }

    static func load(now: Date = Date()) -> ArcSnapshot? {
        guard let json = WidgetStore.raw() else { return nil }
        return parse(json, today: WidgetStore.todayKey(now))
    }

    /// For the gallery only: day 34, thirty-three days held, one of them saved
    /// by a joker. Never drawn as the user's own series.
    static func sample(lang: String) -> ArcSnapshot {
        let cells = (0..<length).map { i -> Cell in
            if i < 33 { return i == 11 ? .joker : (i % 4 == 2 ? .trained : .held) }
            return i == 33 ? .pending : .idle
        }
        return ArcSnapshot(
            soon: false,
            day: 34,
            held: false,
            cells: cells,
            tag: WidgetFallback.string("arc_tag_open", lang: lang),
            status: WidgetFallback.string("arc_sample_status", lang: lang),
            lock: WidgetFallback.string("arc_sample_lock", lang: lang),
            stale: false
        )
    }
}

// MARK: - Timeline

struct ArcEntry: TimelineEntry {
    let date: Date

    /// Nil before the app has written an arc block.
    let arc: ArcSnapshot?
}

/// The data only changes when the app writes it; what changes on its own is
/// the day. One entry now, and a reload after midnight to mark the data stale.
struct ArcProvider: TimelineProvider {
    func placeholder(in context: Context) -> ArcEntry {
        ArcEntry(date: Date(), arc: .sample(lang: WidgetStore.language()))
    }

    func getSnapshot(in context: Context, completion: @escaping (ArcEntry) -> Void) {
        let real = ArcSnapshot.load()
        let arc = real ?? (context.isPreview ? ArcSnapshot.sample(lang: WidgetStore.language()) : nil)
        completion(ArcEntry(date: Date(), arc: arc))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ArcEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)
        completion(Timeline(entries: [ArcEntry(date: now, arc: ArcSnapshot.load(now: now))], policy: .after(tomorrow)))
    }
}

// MARK: - Colours

/// The season's night: the one place Ryze leaves its paper, as the arc
/// screen does in the app (ArcIce in lib/arc/winter_flame.dart).
enum ArcNight {
    static let top = Color(rgb: 0x0B132B)
    static let bottom = Color(rgb: 0x16224A)
    static let iceHi = Color(rgb: 0x9FE6FF)
    static let amber = Color(rgb: 0xF2A93B)
    static let amberDeep = Color(rgb: 0xD8891A)
    static let joker = Color(rgb: 0xCFE9F7)
    static let idle = Color.white.opacity(0.13)

    static var ground: LinearGradient {
        LinearGradient(colors: [top, bottom], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Views

struct ArcWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: ArcEntry

    var body: some View {
        switch family {
        case .accessoryRectangular:
            ArcLockView(arc: entry.arc)
                .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
                .containerBackground(for: .widget) { AccessoryWidgetBackground() }
                .widgetURL(URL(string: "ryse://arc"))
        default:
            ZStack {
                SnowLayer()
                Group {
                    if let arc = entry.arc {
                        if family == .systemMedium { ArcMediumView(arc: arc) } else { ArcSmallView(arc: arc) }
                    } else {
                        ArcEmptyView()
                    }
                }
                .padding(.vertical, 14)
                .padding(.horizontal, family == .systemMedium ? 16 : 14)
            }
            .containerBackground(for: .widget) { ArcNight.ground }
            .widgetURL(URL(string: "ryse://arc"))
        }
    }
}

private struct ArcLabel: View {
    var body: some View {
        Text("WINTER ARC")
            .font(RyzeFont.body(9.5, weight: 700))
            .tracking(1.33)
            .foregroundStyle(ArcNight.iceHi)
            .lineLimit(1)
    }
}

/// The word of the day, left of the flame: white while the day is still to
/// hold, amber once it is held.
///
/// One word to a line, never cut inside a word: the app marks where a long
/// word may break (a soft hyphen, as in GE-SCHAFFT.), and the whole word
/// shrinks, every line alike, until the longest one fits.
private struct ArcTag: View {
    let text: String
    let held: Bool
    let size: CGFloat

    private var lines: [String] {
        text.split(separator: " ").flatMap { word -> [String] in
            let parts = word.split(separator: "\u{00AD}").map(String.init)
            return parts.enumerated().map { i, part in i < parts.count - 1 ? part + "-" : part }
        }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            block(size)
            block(size * 0.87)
            block(size * 0.75)
            block(size * 0.64)
            block(size * 0.55)
        }
    }

    private func block(_ points: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: -0.12 * points) {
            ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
                Text(line)
                    .font(RyzeFont.display(points))
                    .tracking(-0.01 * points)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .foregroundStyle(held ? ArcNight.amber : .white)
    }
}

private struct ArcDay: View {
    let day: Int
    let size: CGFloat

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            Text("\(day)")
                .font(RyzeFont.display(size))
                .tracking(-0.03 * size)
                .monospacedDigit()
                .foregroundStyle(.white)
            Text("/\(ArcSnapshot.length)")
                .font(RyzeFont.display(14, weight: 600))
                .foregroundStyle(.white.opacity(0.55))
        }
        .lineLimit(1)
    }
}

private struct ArcStatus: View {
    let text: String
    let held: Bool

    var body: some View {
        Text(text)
            .font(RyzeFont.body(10.5, weight: 600))
            .foregroundStyle(held ? ArcNight.iceHi : ArcNight.amber)
            .lineLimit(2)
            .minimumScaleFactor(0.85)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct ArcSmallView: View {
    let arc: ArcSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 6) {
                VStack(alignment: .leading, spacing: 5) {
                    ArcLabel()
                    ArcTag(text: arc.tag, held: arc.held, size: 23)
                }
                Spacer(minLength: 0)
                IceFlame(size: 46)
                    .padding(.top, 2)
                    .padding(.trailing, -4)
            }
            Spacer(minLength: 4)
            VStack(alignment: .leading, spacing: 2) {
                ArcDay(day: arc.day, size: 30)
                ArcStatus(text: arc.status, held: arc.held)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

struct ArcMediumView: View {
    let arc: ArcSnapshot

    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 0) {
                ArcLabel()
                Spacer(minLength: 4)
                HStack(alignment: .center, spacing: 8) {
                    ArcTag(text: arc.tag, held: arc.held, size: 25)
                    IceFlame(size: 46)
                }
                Spacer(minLength: 4)
                VStack(alignment: .leading, spacing: 1) {
                    ArcDay(day: arc.day, size: 24)
                    ArcStatus(text: arc.status, held: arc.held)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)

            ArcGridView(cells: arc.cells)
        }
    }
}

/// Before the app has written the arc: the night, the flame, and the one
/// thing to do.
struct ArcEmptyView: View {
    var body: some View {
        let lang = WidgetStore.language()
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                ArcLabel()
                Spacer(minLength: 0)
                IceFlame(size: 46).padding(.trailing, -4)
            }
            Spacer(minLength: 4)
            Text(WidgetFallback.string("open_app", lang: lang))
                .font(RyzeFont.display(17))
                .tracking(RyzeFont.tracking(17))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}

/// The lock screen, which iOS draws in monochrome: no motion, no colour,
/// the day and how far it is along the 90.
struct ArcLockView: View {
    let arc: ArcSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("WINTER ARC")
                .font(RyzeFont.body(11, weight: 700))
                .tracking(0.66)
                .opacity(0.85)
            if let arc, !arc.soon {
                Text(arc.lock)
                    .font(RyzeFont.display(22))
                    .tracking(RyzeFont.tracking(22))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                AmberGauge(fraction: arc.fraction, color: .white, track: .white.opacity(0.25), height: 5)
                    .padding(.top, 3)
            } else {
                Text(arc?.status ?? WidgetFallback.string("open_app", lang: WidgetStore.language()))
                    .font(RyzeFont.body(13, weight: 600))
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}

// MARK: - Grid

/// The 90 days, ten to a row: held in amber, a session in deep amber, a
/// joker in frost, the day still to hold outlined, the rest waiting.
struct ArcGridView: View {
    let cells: [ArcSnapshot.Cell]

    private let side: CGFloat = 9.6
    private let gap: CGFloat = 2.5

    var body: some View {
        VStack(spacing: gap) {
            ForEach(0..<9, id: \.self) { row in
                HStack(spacing: gap) {
                    ForEach(0..<10, id: \.self) { column in
                        cell(cells[row * 10 + column])
                    }
                }
            }
        }
        .frame(maxHeight: .infinity)
    }

    @ViewBuilder
    private func cell(_ c: ArcSnapshot.Cell) -> some View {
        let shape = RoundedRectangle(cornerRadius: 2.4, style: .continuous)
        switch c {
        case .held: shape.fill(ArcNight.amber).frame(width: side, height: side)
        case .trained: shape.fill(ArcNight.amberDeep).frame(width: side, height: side)
        case .joker: shape.fill(ArcNight.joker).frame(width: side, height: side)
        case .pending: shape.strokeBorder(.white.opacity(0.9), lineWidth: 1.2).frame(width: side, height: side)
        case .idle: shape.fill(ArcNight.idle).frame(width: side, height: side)
        }
    }
}

// MARK: - Motion

/// WidgetKit's clock-hand rotation: the one continuous motion a widget can
/// have, drawn by the system itself as it draws the second hand of the clock
/// widget. No timeline entry is spent on it.
///
/// Apple keeps it private. Xcode 26 no longer exposes `_clockHandRotationEffect`
/// (build #118 failed on it), so the modifier is found at run time instead:
/// its type is looked up by name and built from its own Codable form, the
/// technique of ClockHandKit (MIT, github.com/giljihun/ClockHandKit). If iOS
/// ever renames it, the lookup fails and the widget simply stands still.
enum ClockHand {
    private struct Payload: Encodable {
        let period: TimeInterval
        let timeZone: TimeZone
        let anchor: UnitPoint

        private enum CodingKeys: String, CodingKey {
            case period, timeZone, anchor
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(period, forKey: .period)
            try container.encode(timeZone, forKey: .timeZone)
            // UnitPoint is only Codable from iOS 26: written as the pair WidgetKit reads
            var point = container.nestedUnkeyedContainer(forKey: .anchor)
            try point.encode(Double(anchor.x))
            try point.encode(Double(anchor.y))
        }
    }

    /// The modifier turning once every `period` seconds, or nil if iOS does not
    /// have it.
    static func modifier(period: TimeInterval) -> (any ViewModifier)? {
        guard let type = _typeByName("9WidgetKit24_ClockHandRotationEffectV") as? any Decodable.Type,
              let data = try? JSONEncoder().encode(Payload(period: period, timeZone: .current, anchor: .center)),
              let effect = try? JSONDecoder().decode(type, from: data) else { return nil }
        return effect as? any ViewModifier
    }

    /// Whether the rotation can run at all on this phone.
    static let available: Bool = modifier(period: 60) != nil

    static func apply<V: View>(to view: V, period: TimeInterval) -> AnyView {
        guard let effect = modifier(period: period) else { return AnyView(view) }
        return AnyView(applying(effect, to: view))
    }

    private static func applying<V: View, M: ViewModifier>(_ effect: M, to view: V) -> some View {
        view.modifier(effect)
    }
}

extension View {
    /// A full turn every `period` seconds, clockwise.
    fileprivate func clockSpin(_ period: TimeInterval) -> some View {
        ClockHand.apply(to: self, period: period)
    }

    /// The same turn, the other way round: mirrored, turned, mirrored back.
    fileprivate func clockSpinBack(_ period: TimeInterval) -> some View {
        scaleEffect(x: -1, y: 1).clockSpin(period).scaleEffect(x: -1, y: 1)
    }

    /// Travels on a circle of `radius` in `period` seconds without tilting:
    /// an arm turns, and the content turns back as much.
    fileprivate func orbit(radius: CGFloat, period: TimeInterval, moving: Bool) -> some View {
        Group {
            if moving {
                clockSpinBack(period).offset(x: radius).clockSpin(period)
            } else {
                self
            }
        }
    }
}

// MARK: - Snow and flame

/// Snow. Moving, each flake sits on the rim of a wheel centred far off to the
/// left, so only the part of the rim that falls crosses the widget: six flakes
/// to a wheel, about 35 points a second, the speed of real snow. Still (Reduce
/// Motion, or no rotation on this iOS), flakes scattered over the night, the
/// same places every time.
struct SnowLayer: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h = geometry.size.height
            if !reduceMotion && ClockHand.available {
                let n = max(1, Int((w / 26).rounded()))
                ZStack(alignment: .topLeading) {
                    ForEach(0..<n, id: \.self) { k in
                        wheel(k, x: 8 + (CGFloat(k) + 0.5) * (w - 16) / CGFloat(n), h: h)
                    }
                }
            } else {
                // About one flake per 50 x 50 points, evenly spread, never a grid.
                let n = max(6, Int((w * h / 2500).rounded()))
                ZStack(alignment: .topLeading) {
                    ForEach(0..<n, id: \.self) { k in
                        let fx = CGFloat((Double(k) * 0.618_034 + 0.13).truncatingRemainder(dividingBy: 1))
                        let fy = CGFloat((Double(k) * 0.754_878 + 0.37).truncatingRemainder(dividingBy: 1))
                        Circle()
                            .fill(.white.opacity(0.45 + Double((k * 3) % 4) * 0.12))
                            .frame(width: 1.6 + CGFloat(k % 3) * 0.7, height: 1.6 + CGFloat(k % 3) * 0.7)
                            .position(x: 4 + fx * (w - 8), y: 4 + fy * (h - 8))
                    }
                }
            }
        }
        .clipped()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func wheel(_ k: Int, x: CGFloat, h: CGFloat) -> some View {
        let radius = CGFloat(360 + (k * 97) % 180)
        let period = (2 * Double.pi * Double(radius) / 35).rounded()
        return ZStack {
            ForEach(0..<6, id: \.self) { j in
                let size = 1.6 + CGFloat((k + j) % 3) * 0.7
                let alpha = 0.45 + Double((k * 3 + j) % 4) * 0.12
                Circle()
                    .fill(.white.opacity(alpha))
                    .frame(width: size, height: size)
                    .position(x: 2 * radius, y: radius)
                    .rotationEffect(.degrees(Double(j * 60 + (k * 23) % 60)))
            }
        }
        .frame(width: 2 * radius, height: 2 * radius)
        .clockSpin(period)
        .position(x: x - radius, y: h / 2)
    }
}

/// The flame of the season, drawn in three layers as in the app: blue, cyan,
/// a white core. Each layer drifts on its own small circle at its own pace,
/// slow enough to read as a flame breathing rather than shaking.
struct IceFlame: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let size: CGFloat

    var body: some View {
        let s = size / 24
        let moving = !reduceMotion && ClockHand.available
        ZStack {
            ZStack {
                FlameShape().fill(gradient(0x3FA8FF, 0x1B3FB8))
                FlameHighlight().stroke(.white.opacity(0.55), style: StrokeStyle(lineWidth: 1.1 * s, lineCap: .round))
            }
            .orbit(radius: 0.18 * s, period: 5.2, moving: moving)

            FlameShape().fill(gradient(0x9FE6FF, 0x38A0FF))
                .scaleEffect(0.66, anchor: UnitPoint(x: 12.3 / 24, y: 21.6 / 24))
                .orbit(radius: 0.42 * s, period: 3.7, moving: moving)

            FlameShape().fill(gradient(0xFFFFFF, 0xE4F8FF))
                .scaleEffect(0.36, anchor: UnitPoint(x: 12.3 / 24, y: 21.2 / 24))
                .orbit(radius: 0.5 * s, period: 2.9, moving: moving)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    /// From the tip to the base, as the SVG's gradients run from y 2 to 22.
    private func gradient(_ top: UInt32, _ bottom: UInt32) -> LinearGradient {
        LinearGradient(
            colors: [Color(rgb: top), Color(rgb: bottom)],
            startPoint: UnitPoint(x: 0.5, y: 2.0 / 24),
            endPoint: UnitPoint(x: 0.5, y: 22.0 / 24)
        )
    }
}

/// The flame of the app (lib/arc/winter_flame.dart), on a 24-point grid.
struct FlameShape: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path()
        path.move(to: p(12, 22))
        path.addCurve(to: p(5, 15.3), control1: p(7.9, 22), control2: p(5, 19))
        path.addCurve(to: p(8.5, 8.1), control1: p(5, 12.2), control2: p(6.7, 10.2))
        path.addCurve(to: p(10.8, 11.3), control1: p(8.9, 9.7), control2: p(9.7, 10.8))
        path.addCurve(to: p(13.7, 2.2), control1: p(10.2, 7.9), control2: p(11.5, 4.7))
        path.addCurve(to: p(17.1, 8.1), control1: p(14.2, 4.6), control2: p(15.6, 6.4))
        path.addCurve(to: p(20, 15.3), control1: p(18.7, 9.9), control2: p(20, 11.9))
        path.addCurve(to: p(12, 22), control1: p(20, 19), control2: p(16.1, 22))
        path.closeSubpath()
        return path
    }
}

/// The light on the flame's left flank.
struct FlameHighlight: Shape {
    func path(in rect: CGRect) -> Path {
        let s = min(rect.width, rect.height) / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * s, y: rect.minY + y * s) }
        var path = Path()
        path.move(to: p(7.4, 12.6))
        path.addCurve(to: p(6.3, 16.6), control1: p(6.5, 13.9), control2: p(6.1, 15.2))
        return path
    }
}

// MARK: - Previews

#Preview("Arc", as: .systemSmall) {
    RyzeArcWidget()
} timeline: {
    ArcEntry(date: .now, arc: .sample(lang: "fr"))
}

#Preview("Arc medium", as: .systemMedium) {
    RyzeArcWidget()
} timeline: {
    ArcEntry(date: .now, arc: .sample(lang: "en"))
}
