//
//  AddWaterIntent.swift
//  RyseMealWidget
//
//  App Intent pour ajouter de l'eau directement depuis le widget (iOS 17+)
//

import AppIntents
import Foundation
import WidgetKit

@available(iOS 17.0, *)
struct AddWaterIntent: AppIntent {
    static var title: LocalizedStringResource { "Ajouter de l'eau" }
    static var description: IntentDescription { IntentDescription("Ajoute de l'eau à ta journée") }

    static var openAppWhenRun: Bool = false // Ne pas ouvrir l'app
    
    @Parameter(title: "Amount (ml)")
    var amount: Int
    
    init() {
        amount = 0
    }
    
    init(amount: Int) {
        self.amount = amount
    }
    
    func perform() async throws -> some IntentResult {
        // Sauvegarder dans App Group UserDefaults pour que Flutter puisse le traiter
        guard let userDefaults = UserDefaults(suiteName: "group.com.ryze.app") else {
            throw IntentError.appGroupUnavailable
        }

        // MISE À JOUR OPTIMISTE : Mettre à jour immédiatement les valeurs affichées
        // Récupérer les données actuelles du widget
        if let jsonString = userDefaults.string(forKey: "widget_meal_data"),
           let jsonData = jsonString.data(using: .utf8),
           var widgetData = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           var water = widgetData["water"] as? [String: Any] {

            // Ajouter la quantité à la valeur actuelle
            let currentMl = (water["current"] as? Int) ?? 0
            let goalMl = (water["goal"] as? Int) ?? 2000
            let newCurrentMl = currentMl + amount
            let newCurrentL = Double(newCurrentMl) / 1000.0
            let newPercentage = goalMl > 0 ? (newCurrentMl * 100 / goalMl) : 0

            // Mettre à jour les valeurs
            water["current"] = newCurrentMl
            water["currentL"] = newCurrentL
            water["percentage"] = newPercentage
            widgetData["water"] = water

            // Sauvegarder immédiatement pour que le widget affiche les nouvelles valeurs
            if let updatedJsonData = try? JSONSerialization.data(withJSONObject: widgetData),
               let updatedJsonString = String(data: updatedJsonData, encoding: .utf8) {
                userDefaults.set(updatedJsonString, forKey: "widget_meal_data")
            }
        }

        // Notifier Flutter pour la synchronisation en arrière-plan
        userDefaults.set(true, forKey: "widget_pending_water_add")
        userDefaults.set(amount, forKey: "widget_pending_water_amount")
        userDefaults.set(Date().timeIntervalSince1970, forKey: "widget_pending_water_timestamp")

        // Recharger le widget immédiatement avec les nouvelles valeurs
        WidgetCenter.shared.reloadAllTimelines()

        return .result()
    }
}

@available(iOS 17.0, *)
enum IntentError: Error {
    case appGroupUnavailable
}

// Actions rapides prédéfinies pour les boutons du widget (iOS 17+)
