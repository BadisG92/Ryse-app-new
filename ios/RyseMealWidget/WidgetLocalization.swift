//
//  WidgetLocalization.swift
//  RyseMealWidget
//

import Foundation

struct WidgetLocalizationStrings {
    let languageCode: String
    let widgetTitle: String
    let widgetDescription: String
    let placeholderMeal: String
    let addWaterTitle: String
    let addWaterDescription: String
    let addWaterPresetFormat: String
    let coachWidgetTitle: String
    let coachWidgetDescription: String
    let mealShortNames: [String: String]

    static func fallback() -> WidgetLocalizationStrings {
        return WidgetLocalizationStrings(
            languageCode: "fr",
            widgetTitle: "Mes Repas",
            widgetDescription: "Voir vos repas et calories du jour",
            placeholderMeal: "Repas",
            addWaterTitle: "Ajouter de l'eau",
            addWaterDescription: "Ajoute de l'eau à votre consommation quotidienne",
            addWaterPresetFormat: "Ajouter {amount} ml",
            coachWidgetTitle: "Coach Ryse",
            coachWidgetDescription: "Suivi calories avec conseils personnalisés",
            mealShortNames: [
                "petit-dejeuner": "Petit-déj.",
                "breakfast": "Breakfast",
                "dejeuner": "Déjeuner",
                "lunch": "Lunch",
                "diner": "Dîner",
                "dinner": "Dinner",
                "snack": "Collation",
                "collation": "Collation",
                "default": "Repas",
            ]
        )
    }

    static func from(json: [String: Any]?) -> WidgetLocalizationStrings {
        let defaults = WidgetLocalizationStrings.fallback()
        guard let json = json else {
            return defaults
        }

        let texts = json["texts"] as? [String: Any] ?? [:]
        let shortNamesJson = json["mealShortNames"] as? [String: String] ?? [:]

        var mergedShortNames = defaults.mealShortNames
        for (key, value) in shortNamesJson {
            mergedShortNames[key.lowercased()] = value
        }

        return WidgetLocalizationStrings(
            languageCode: (json["languageCode"] as? String) ?? defaults.languageCode,
            widgetTitle: texts["widgetTitle"] as? String ?? defaults.widgetTitle,
            widgetDescription: texts["widgetDescription"] as? String ?? defaults.widgetDescription,
            placeholderMeal: texts["placeholderMeal"] as? String ?? defaults.placeholderMeal,
            addWaterTitle: texts["addWaterTitle"] as? String ?? defaults.addWaterTitle,
            addWaterDescription: texts["addWaterDescription"] as? String ?? defaults.addWaterDescription,
            addWaterPresetFormat: texts["addWaterPresetFormat"] as? String ?? defaults.addWaterPresetFormat,
            coachWidgetTitle: texts["coachWidgetTitle"] as? String ?? defaults.coachWidgetTitle,
            coachWidgetDescription: texts["coachWidgetDescription"] as? String ?? defaults.coachWidgetDescription,
            mealShortNames: mergedShortNames
        )
    }

    func shortName(for mealType: String) -> String {
        let lower = mealType.lowercased()
        return mealShortNames[lower] ?? mealShortNames["default"] ?? "Meal"
    }

    func presetLabel(for amount: Int) -> String {
        let placeholder = "{amount}"
        if addWaterPresetFormat.contains(placeholder) {
            return addWaterPresetFormat.replacingOccurrences(of: placeholder, with: "\(amount)")
        }
        return "\(addWaterPresetFormat) \(amount)"
    }
}

struct WidgetLocalizationProvider {
    static let shared = WidgetLocalizationProvider()
    private let appGroupId = "group.com.ryze.app"

    func currentTranslations() -> WidgetLocalizationStrings {
        guard let userDefaults = UserDefaults(suiteName: appGroupId),
              let jsonString = userDefaults.string(forKey: "widget_meal_data"),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return WidgetLocalizationStrings.fallback()
        }

        let translationsJson = json["translations"] as? [String: Any]
        return WidgetLocalizationStrings.from(json: translationsJson)
    }
}
