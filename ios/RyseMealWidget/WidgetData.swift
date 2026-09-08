//
//  WidgetData.swift
//  RyseMealWidget
//
//  What the app writes, read for one moment of the day. The contract is
//  documented in lib/services/meal_widget_data_provider.dart and WIDGET.md.
//

import Foundation
import WidgetKit

// MARK: - Snapshot

struct WidgetSnapshot {
    struct Kcal {
        let eaten: Int
        let goal: Int
    }

    struct Water {
        let ml: Int
        let goalMl: Int
        let glassMl: Int
    }

    enum SlotState: String {
        case free, planned, done
    }

    struct Slot {
        let id: String
        let state: SlotState
        let label: String
        let word: String
        let kind: String?
    }

    /// The coach's line from a given hour on. `restates` marks a line that
    /// only repeats what is left of the goal, which the figure already says.
    struct Line {
        let from: Int
        let text: String
        let restates: Bool
    }

    let day: String
    let lang: String
    let kcal: Kcal
    let water: Water
    let slots: [Slot]
    let lines: [Line]
    let strings: [String: String]
    let palette: RyzePalette

    // MARK: Readings

    var goalKnown: Bool { kcal.goal > 0 }
    var left: Int { kcal.goal - kcal.eaten }
    var fraction: Double { kcal.goal > 0 ? min(max(Double(kcal.eaten) / Double(kcal.goal), 0), 1) : 0 }

    /// One glass is 250 ml, so the goal decides how many are drawn: the rule
    /// of the app's own glass row, four to twelve.
    var glasses: Int { water.glassMl > 0 ? water.ml / water.glassMl : 0 }
    var goalGlasses: Int {
        guard water.goalMl > 0, water.glassMl > 0 else { return 8 }
        let n = Int((Double(water.goalMl) / Double(water.glassMl)).rounded())
        return min(max(n, 4), 12)
    }
    var waterFull: Bool { water.goalMl > 0 && water.ml >= water.goalMl }

    var locale: Locale { Locale(identifier: lang) }

    func string(_ key: String) -> String {
        strings[key] ?? WidgetFallback.string(key, lang: lang)
    }

    func fill(_ key: String, _ args: [String: String]) -> String {
        var text = string(key)
        for (name, value) in args {
            text = text.replacingOccurrences(of: "{\(name)}", with: value)
        }
        return text
    }

    func integer(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    func litres(_ ml: Int) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: Double(ml) / 1000)) ?? "\(Double(ml) / 1000)"
    }

    /// What is left, the goal met, or the goal passed: the three states the
    /// home's instrument knows, never a fourth.
    var leadKey: String {
        guard goalKnown else { return "lead_loading" }
        return left > 0 ? "lead_remaining" : (left == 0 ? "lead_reached" : "lead_over")
    }

    var shortKey: String { left > 0 ? "left_short" : (left == 0 ? "reached_short" : "over_short") }

    var figure: String { goalKnown ? integer(abs(left)) : "—" }
    var eatenText: String { fill("eaten_tpl", ["n": integer(kcal.eaten)]) }
    var goalText: String { fill("goal_tpl", ["n": integer(kcal.goal)]) }
    var waterText: String { litres(water.ml) }
    var waterGoalText: String { fill("water_goal_tpl", ["g": litres(water.goalMl)]) }
    var glassesOf: String { fill("glasses_of_tpl", ["n": integer(glasses), "g": integer(goalGlasses)]) }

    /// The coach's line for that moment: the last band that has started.
    func line(at date: Date) -> Line? {
        let hour = Calendar.current.component(.hour, from: date)
        let started = lines.filter { $0.from <= hour }
        return started.max(by: { $0.from < $1.from }) ?? lines.first
    }

    /// What the lock screen says under the gauge: the coach's line, unless
    /// it would only repeat the figure, in which case the water.
    func caption(at date: Date) -> String? {
        guard let line = line(at: date) else { return nil }
        return line.restates ? glassesOf : line.text
    }

    // MARK: Parsing

    /// Reads the app's JSON. Data from another day keeps the goals and the
    /// labels and zeroes everything eaten, drunk or planned: the widget never
    /// shows yesterday as today. Data from an older app is treated as none.
    static func parse(_ json: [String: Any], today: String) -> WidgetSnapshot? {
        guard int(json["v"]) >= 2 else { return nil }

        let day = json["day"] as? String ?? ""
        let isToday = day == today
        let lang = json["lang"] as? String ?? WidgetFallback.deviceLanguage
        let strings = json["strings"] as? [String: String] ?? [:]

        let kcalJson = json["kcal"] as? [String: Any] ?? [:]
        let waterJson = json["water"] as? [String: Any] ?? [:]

        let kcal = Kcal(eaten: isToday ? int(kcalJson["eaten"]) : 0, goal: int(kcalJson["goal"]))
        let water = Water(
            ml: isToday ? int(waterJson["ml"]) : 0,
            goalMl: int(waterJson["goalMl"]),
            glassMl: int(waterJson["glassMl"], or: 250)
        )

        let freeWord = strings["free_word"]
        let slots = (json["slots"] as? [[String: Any]] ?? []).map { item -> Slot in
            let state = SlotState(rawValue: item["state"] as? String ?? "") ?? .free
            let word = item["word"] as? String ?? ""
            return Slot(
                id: item["slot"] as? String ?? "",
                state: isToday ? state : .free,
                label: item["label"] as? String ?? "",
                word: isToday ? word : (freeWord ?? word),
                kind: item["kind"] as? String
            )
        }

        let lines = isToday
            ? (json["lines"] as? [[String: Any]] ?? []).compactMap { item -> Line? in
                guard let text = item["text"] as? String, !text.isEmpty else { return nil }
                return Line(from: int(item["from"]), text: text, restates: item["restates"] as? Bool ?? false)
            }
            : []

        return WidgetSnapshot(
            day: day, lang: lang, kcal: kcal, water: water, slots: slots, lines: lines, strings: strings,
            palette: RyzePalette.from(json["theme"] as? [String: Any])
        )
    }

    static func int(_ value: Any?, or fallback: Int = 0) -> Int {
        if let i = value as? Int { return i }
        if let d = value as? Double { return Int(d) }
        if let s = value as? String, let i = Int(s) { return i }
        return fallback
    }

    /// Example values for the gallery and the placeholder. They are drawn
    /// redacted or labelled as a preview, never as the user's own day.
    static func sample(lang: String) -> WidgetSnapshot {
        func word(_ key: String) -> String { WidgetFallback.string(key, lang: lang) }
        return WidgetSnapshot(
            day: WidgetStore.todayKey(),
            lang: lang,
            kcal: Kcal(eaten: 1240, goal: 2100),
            water: Water(ml: 1250, goalMl: 2000, glassMl: 250),
            slots: [
                Slot(id: "breakfast", state: .done, label: word("slot_breakfast"), word: word("slot_done"), kind: nil),
                Slot(id: "lunch", state: .done, label: word("slot_lunch"), word: word("slot_done"), kind: nil),
                Slot(id: "snack", state: .free, label: word("slot_snack"), word: word("slot_free"), kind: nil),
                Slot(id: "dinner", state: .planned, label: word("slot_dinner"), word: word("slot_planned"), kind: nil),
                Slot(id: "sport", state: .planned, label: word("slot_sport"), word: word("slot_planned"), kind: "strength"),
            ],
            lines: [Line(from: 0, text: word("sample_line"), restates: false)],
            strings: [:],
            palette: .nuit
        )
    }
}

// MARK: - Store

/// The App Group the app and the widgets share.
enum WidgetStore {
    static let appGroup = "group.com.ryze.app"
    static let dataKey = "widget_meal_data"

    /// Water added from the widget and not yet written by the app.
    static let pendingFlagKey = "widget_pending_water_add"
    static let pendingAmountKey = "widget_pending_water_amount"
    static let pendingStampKey = "widget_pending_water_timestamp"

    static var defaults: UserDefaults? { UserDefaults(suiteName: appGroup) }

    static func raw() -> [String: Any]? {
        guard let text = defaults?.string(forKey: dataKey),
              let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        return json
    }

    static func write(_ json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let text = String(data: data, encoding: .utf8) else { return }
        defaults?.set(text, forKey: dataKey)
    }

    /// The local day as the app writes it: compared as text, never parsed.
    static func todayKey(_ date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.timeZone = TimeZone.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    static func load(now: Date = Date()) -> WidgetSnapshot? {
        guard let json = raw() else { return nil }
        return WidgetSnapshot.parse(json, today: todayKey(now))
    }

    /// The app's language once it has written, the device's before.
    static func language() -> String {
        (raw()?["lang"] as? String) ?? WidgetFallback.deviceLanguage
    }

    /// The palette the app last wrote, for the states that have no data.
    static func palette() -> RyzePalette {
        RyzePalette.from(raw()?["theme"] as? [String: Any])
    }
}

// MARK: - Timeline

struct RyzeEntry: TimelineEntry {
    let date: Date

    /// Nil before the app has ever written, or after a sign-out.
    let snapshot: WidgetSnapshot?
}

/// One provider for the three widgets. The data only changes when the app
/// writes it and asks for a reload; what changes on its own is the coach's
/// line, at the hours the app listed. So the timeline is one entry now, one
/// at each of those hours still ahead today, and a reload after midnight,
/// when the day the data describes is over.
struct RyzeProvider: TimelineProvider {
    func placeholder(in context: Context) -> RyzeEntry {
        RyzeEntry(date: Date(), snapshot: .sample(lang: WidgetStore.language()))
    }

    func getSnapshot(in context: Context, completion: @escaping (RyzeEntry) -> Void) {
        let real = WidgetStore.load()
        let snapshot = real ?? (context.isPreview ? WidgetSnapshot.sample(lang: WidgetStore.language()) : nil)
        completion(RyzeEntry(date: Date(), snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<RyzeEntry>) -> Void) {
        let now = Date()
        let calendar = Calendar.current
        let snapshot = WidgetStore.load(now: now)

        var dates = [now]
        for line in snapshot?.lines ?? [] {
            if let start = calendar.date(bySettingHour: line.from, minute: 0, second: 0, of: now), start > now {
                dates.append(start)
            }
        }
        let tomorrow = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: now) ?? now)

        let entries = dates.sorted().map { RyzeEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(tomorrow)))
    }
}

// MARK: - Fallback words

/// The few words the extension needs before the app has ever written: the
/// names in the gallery, the empty state, and the labels of the sample. They
/// are copies of lib/services/translations.dart, chosen by the device's
/// language; every word on a real widget comes from the app.
enum WidgetFallback {
    static var deviceLanguage: String {
        let code = Locale.current.language.languageCode?.identifier ?? "en"
        return ["fr", "en", "de"].contains(code) ? code : "en"
    }

    static func string(_ key: String, lang: String) -> String {
        let language = ["fr", "en", "de"].contains(lang) ? lang : "en"
        return table[key]?[language] ?? table[key]?["en"] ?? key
    }

    private static let table: [String: [String: String]] = [
        "title_water": ["fr": "Eau", "en": "Water", "de": "Wasser"],
        "desc_water": ["fr": "Tes verres du jour, et un de plus d'un tap", "en": "Today's glasses, and one more in a tap", "de": "Deine Gläser heute, und eins mehr mit einem Tipp"],
        "title_meals": ["fr": "Repas", "en": "Meals", "de": "Mahlzeiten"],
        "desc_meals": ["fr": "Ce qu'il te reste, et les repas du jour", "en": "What is left, and today's meals", "de": "Was dir bleibt, und die Mahlzeiten des Tages"],
        "title_today": ["fr": "Aujourd'hui", "en": "Today", "de": "Heute"],
        "desc_today": ["fr": "Ce qu'il te reste, et un mot du coach", "en": "What is left, and a word from the coach", "de": "Was dir bleibt, und ein Wort vom Coach"],
        "open_app": ["fr": "Ouvre Ryze", "en": "Open Ryze", "de": "Ryze öffnen"],
        "lead_remaining": ["fr": "Il te reste", "en": "You have left", "de": "Dir bleiben"],
        "lead_reached": ["fr": "Objectif du jour atteint", "en": "Goal reached today", "de": "Tagesziel erreicht"],
        "lead_over": ["fr": "Tu as dépassé de", "en": "You are over by", "de": "Du liegst drüber um"],
        "lead_loading": ["fr": "Ta journée arrive", "en": "Your day is loading", "de": "Dein Tag lädt"],
        "unit": ["fr": "kcal", "en": "kcal", "de": "kcal"],
        "eaten_tpl": ["fr": "{n} kcal mangées", "en": "{n} kcal eaten", "de": "{n} kcal gegessen"],
        "goal_tpl": ["fr": "objectif {n}", "en": "goal {n}", "de": "Ziel {n}"],
        "left_short": ["fr": "kcal restantes", "en": "kcal left", "de": "kcal übrig"],
        "over_short": ["fr": "kcal au-dessus", "en": "kcal over", "de": "kcal darüber"],
        "reached_short": ["fr": "objectif atteint", "en": "goal reached", "de": "Ziel erreicht"],
        "water": ["fr": "Eau", "en": "Water", "de": "Wasser"],
        "water_goal_tpl": ["fr": "/ {g} L", "en": "/ {g} L", "de": "/ {g} L"],
        "glasses_of_tpl": ["fr": "{n} verres sur {g}", "en": "{n} of {g} glasses", "de": "{n} von {g} Gläsern"],
        "glass_one": ["fr": "+ 1 verre", "en": "+ 1 glass", "de": "+ 1 Glas"],
        "glass_two": ["fr": "+ 2", "en": "+ 2", "de": "+ 2"],
        "slot_breakfast": ["fr": "Petit-déj", "en": "Breakfast", "de": "Frühstück"],
        "slot_lunch": ["fr": "Déjeuner", "en": "Lunch", "de": "Mittag"],
        "slot_snack": ["fr": "Collation", "en": "Snack", "de": "Snack"],
        "slot_dinner": ["fr": "Dîner", "en": "Dinner", "de": "Abend"],
        "slot_sport": ["fr": "Séance", "en": "Session", "de": "Training"],
        "slot_free": ["fr": "Libre", "en": "Free", "de": "Frei"],
        "slot_planned": ["fr": "Prévu", "en": "Planned", "de": "Geplant"],
        "slot_done": ["fr": "Fait", "en": "Done", "de": "Erledigt"],
        "sample_line": ["fr": "Tu n'as presque rien bu aujourd'hui.", "en": "You've barely had any water today.", "de": "Du hast heute kaum getrunken."],
    ]
}
