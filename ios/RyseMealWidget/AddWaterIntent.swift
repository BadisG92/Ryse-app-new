//
//  AddWaterIntent.swift
//  RyseMealWidget
//
//  One or two glasses, added from the widget without opening the app.
//
//  The intent runs in the widget's own process, so it does two things: it
//  redraws the glasses at once, and it leaves the amount in the App Group
//  for the app, which writes it to the journal the next time it comes to
//  the front (WidgetWaterHandler). What is left for the app is added to
//  what is already waiting, never written over it: two taps while the app
//  is closed are two glasses, on the widget and in the journal alike.
//

import AppIntents
import Foundation
import WidgetKit

struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource = "Add water"
    static var description = IntentDescription("Adds one or two glasses to today's water in Ryze.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Glasses")
    var glasses: Int

    init() {
        glasses = 1
    }

    init(glasses: Int) {
        self.glasses = glasses
    }

    func perform() async throws -> some IntentResult {
        guard let defaults = WidgetStore.defaults else {
            throw WidgetIntentError.appGroupUnavailable
        }

        var json = WidgetStore.raw() ?? [:]
        var water = json["water"] as? [String: Any] ?? [:]
        let glassMl = WidgetSnapshot.int(water["glassMl"], or: 250)
        let millilitres = max(1, glasses) * glassMl

        // The glasses fill now. Data from another day is first brought to
        // today, empty: a glass drunk this morning must not be added to
        // yesterday's evening.
        let today = WidgetStore.todayKey()
        if (json["day"] as? String) != today {
            json["day"] = today
            if var kcal = json["kcal"] as? [String: Any] {
                kcal["eaten"] = 0
                json["kcal"] = kcal
            }
            json["lines"] = []
            let freeWord = (json["strings"] as? [String: String])?["free_word"]
            if let slots = json["slots"] as? [[String: Any]] {
                json["slots"] = slots.map { slot -> [String: Any] in
                    var free = slot
                    free["state"] = "free"
                    if let word = freeWord { free["word"] = word }
                    return free
                }
            }
            water["ml"] = 0
        }
        water["ml"] = WidgetSnapshot.int(water["ml"]) + millilitres
        json["water"] = water
        WidgetStore.write(json)

        // And the app writes it when it comes back, added to what it has
        // not taken yet.
        let waiting = defaults.bool(forKey: WidgetStore.pendingFlagKey)
            ? defaults.integer(forKey: WidgetStore.pendingAmountKey)
            : 0
        defaults.set(true, forKey: WidgetStore.pendingFlagKey)
        defaults.set(waiting + millilitres, forKey: WidgetStore.pendingAmountKey)
        defaults.set(Date().timeIntervalSince1970, forKey: WidgetStore.pendingStampKey)

        WidgetCenter.shared.reloadAllTimelines()
        return .result()
    }
}

enum WidgetIntentError: Error {
    case appGroupUnavailable
}
