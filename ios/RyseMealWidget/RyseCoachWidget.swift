//
//  RyseCoachWidget.swift
//  RyseMealWidget
//
//  Lock Screen Widget affichant les calories et macros
//  Taille: accessoryRectangular (Lock Screen iOS 16+)
//

import WidgetKit
import SwiftUI

// MARK: - Widget Configuration

struct RyseCoachWidget: Widget {
    let kind: String = "RyseCoachWidget"
    private let localizationProvider = WidgetLocalizationProvider.shared

    var body: some WidgetConfiguration {
        let localization = localizationProvider.currentTranslations()

        return StaticConfiguration(kind: kind, provider: CoachWidgetProvider()) { entry in
            CoachWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey(localization.coachWidgetTitle))
        .description(LocalizedStringKey(localization.coachWidgetDescription))
        .supportedFamilies([.accessoryRectangular])
    }
}

// MARK: - Timeline Provider

struct CoachWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> CoachWidgetEntry {
        CoachWidgetEntry(
            date: Date(),
            data: CoachWidgetData.placeholder()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (CoachWidgetEntry) -> ()) {
        let entry = CoachWidgetEntry(
            date: Date(),
            data: loadCoachData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CoachWidgetEntry>) -> ()) {
        var entries: [CoachWidgetEntry] = []
        let currentDate = Date()

        // Refresh toutes les 15 minutes pour garder le message coach à jour
        let refreshInterval: TimeInterval = 15 * 60

        // Créer les entries pour les prochaines 4 heures
        for offset in stride(from: 0, to: 4 * 60 * 60, by: Int(refreshInterval)) {
            let entryDate = Calendar.current.date(byAdding: .second, value: offset, to: currentDate)!
            let data = loadCoachData()
            let entry = CoachWidgetEntry(date: entryDate, data: data)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // Charger les données depuis SharedPreferences Flutter
    func loadCoachData() -> CoachWidgetData {
        guard let userDefaults = UserDefaults(suiteName: "group.com.ryze.app") else {
            print("❌ ERREUR: App Group 'group.com.ryze.app' non disponible!")
            return CoachWidgetData.placeholder()
        }

        guard let jsonString = userDefaults.string(forKey: "widget_meal_data") else {
            print("⚠️ Aucune donnée widget trouvée")
            return CoachWidgetData.placeholder()
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return CoachWidgetData.placeholder()
        }

        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return CoachWidgetData.placeholder()
        }

        return CoachWidgetData.from(json: json)
    }
}

// MARK: - Models

struct CoachWidgetEntry: TimelineEntry {
    let date: Date
    let data: CoachWidgetData
}

struct CoachWidgetData {
    let currentCalories: Int
    let goalCalories: Int
    let percentage: Int
    let protein: Int
    let carbs: Int
    let fats: Int
    let coachMessage: String
    let streak: Int
    let languageCode: String

    // Localized macro labels
    var proteinLabel: String { languageCode == "fr" ? "P" : languageCode == "de" ? "E" : "P" }
    var carbsLabel: String { languageCode == "fr" ? "G" : languageCode == "de" ? "K" : "C" }
    var fatsLabel: String { languageCode == "fr" ? "L" : languageCode == "de" ? "F" : "F" }

    static func placeholder() -> CoachWidgetData {
        return CoachWidgetData(
            currentCalories: 0,
            goalCalories: 2000,
            percentage: 0,
            protein: 0,
            carbs: 0,
            fats: 0,
            coachMessage: "Continue ! 💪",
            streak: 0,
            languageCode: "fr"
        )
    }

    // Vérifie si les données sont d'aujourd'hui (reset à minuit)
    private static func checkIfDataIsFromToday(json: [String: Any]) -> Bool {
        guard let lastUpdateStr = json["lastUpdate"] as? String else {
            return false
        }

        // Parser la date UTC avec 'Z' (format envoyé par Flutter)
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard let lastUpdate = isoFormatter.date(from: lastUpdateStr) ?? ISO8601DateFormatter().date(from: lastUpdateStr) else {
            return false
        }

        return Calendar.current.isDateInToday(lastUpdate)
    }

    static func from(json: [String: Any]) -> CoachWidgetData {
        // Vérifier si les données sont d'aujourd'hui (reset à minuit)
        let isDataFromToday = checkIfDataIsFromToday(json: json)

        // Parse language
        let languageCode = (json["languageCode"] as? String) ?? "fr"

        // Parse totals
        let totalsJson = json["totals"] as? [String: Any] ?? [:]
        let current = (totalsJson["current"] as? Int) ?? (totalsJson["current"] as? Double).map { Int($0) } ?? 0
        let goal = (totalsJson["goal"] as? Int) ?? (totalsJson["goal"] as? Double).map { Int($0) } ?? 2000
        let percentage = (totalsJson["percentage"] as? Int) ?? (totalsJson["percentage"] as? Double).map { Int($0) } ?? 0

        // Parse macros
        let macrosJson = json["macros"] as? [String: Any] ?? [:]
        let protein = (macrosJson["protein"] as? Int) ?? (macrosJson["protein"] as? Double).map { Int($0) } ?? 0
        let carbs = (macrosJson["carbs"] as? Int) ?? (macrosJson["carbs"] as? Double).map { Int($0) } ?? 0
        let fats = (macrosJson["fats"] as? Int) ?? (macrosJson["fats"] as? Double).map { Int($0) } ?? 0

        // Parse coach
        let coachJson = json["coach"] as? [String: Any] ?? [:]
        let coachMessage = (coachJson["message"] as? String) ?? "Continue ! 💪"
        let streak = (coachJson["streak"] as? Int) ?? 0

        return CoachWidgetData(
            currentCalories: isDataFromToday ? current : 0,
            goalCalories: goal, // L'objectif reste visible
            percentage: isDataFromToday ? percentage : 0,
            protein: isDataFromToday ? protein : 0,
            carbs: isDataFromToday ? carbs : 0,
            fats: isDataFromToday ? fats : 0,
            coachMessage: coachMessage,
            streak: streak,
            languageCode: languageCode
        )
    }
}

// MARK: - Widget View

struct CoachWidgetEntryView: View {
    var entry: CoachWidgetProvider.Entry

    var body: some View {
        AccessoryRectangularView(entry: entry)
    }
}

// MARK: - Accessory Rectangular View (Lock Screen)

struct AccessoryRectangularView: View {
    var entry: CoachWidgetEntry

    private var progressWidth: CGFloat {
        let percentage = min(Double(entry.data.percentage), 100.0) / 100.0
        return percentage * 140 // Largeur maximale de la barre
    }

    var body: some View {
        Link(destination: URL(string: "ryse://dashboard")!) {
            VStack(alignment: .leading, spacing: 4) {
                // Ligne 1: Calories
                HStack(spacing: 3) {
                    Text("\(entry.data.currentCalories)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("/")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    Text("\(entry.data.goalCalories)")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))

                    Text("kcal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    Spacer()
                }

                // Ligne 2: Barre de progression
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 6)

                        // Progress
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white)
                            .frame(width: geometry.size.width * CGFloat(min(entry.data.percentage, 100)) / 100, height: 6)
                    }
                }
                .frame(height: 6)

                // Ligne 3: Macros compacts
                HStack(spacing: 8) {
                    MacroLabel(label: entry.data.proteinLabel, value: entry.data.protein)
                    MacroLabel(label: entry.data.carbsLabel, value: entry.data.carbs)
                    MacroLabel(label: entry.data.fatsLabel, value: entry.data.fats)

                    Spacer()
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
        }
        .widgetURL(URL(string: "ryse://dashboard")!)
    }
}

// MARK: - Macro Label Component

struct MacroLabel: View {
    let label: String
    let value: Int

    var body: some View {
        HStack(spacing: 2) {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
            Text("\(value)")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.9))
        }
    }
}

// MARK: - Preview

struct RyseCoachWidget_Previews: PreviewProvider {
    static var previews: some View {
        CoachWidgetEntryView(
            entry: CoachWidgetEntry(
                date: Date(),
                data: CoachWidgetData(
                    currentCalories: 1850,
                    goalCalories: 2000,
                    percentage: 92,
                    protein: 120,
                    carbs: 220,
                    fats: 60,
                    coachMessage: "En bonne voie, continue ! 🎯",
                    streak: 7,
                    languageCode: "fr"
                )
            )
        )
        .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}
