//
//  RyseMealWidget.swift
//  RyseMealWidget
//
//  Widget iOS pour afficher le repas contextuel et les calories
//

import WidgetKit
import SwiftUI

// MARK: - Widget Configuration

struct RyseMealWidget: Widget {
    let kind: String = "RyseMealWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RyseMealWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Mes Repas")
        .description("Voir vos repas et calories du jour")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Timeline Provider

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> MealEntry {
        MealEntry(
            date: Date(),
            mealData: MealData.placeholder()
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MealEntry) -> ()) {
        let entry = MealEntry(
            date: Date(),
            mealData: loadMealData()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MealEntry>) -> ()) {
        var entries: [MealEntry] = []
        let currentDate = Date()

        // Stratégie intelligente : refresh plus fréquent aux heures de repas
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: currentDate)

        let refreshInterval: TimeInterval
        if (7...10).contains(hour) || (11...14).contains(hour) || (18...21).contains(hour) {
            // Heures de repas : refresh toutes les 15 minutes
            refreshInterval = 15 * 60
        } else {
            // Autres heures : refresh toutes les heures
            refreshInterval = 60 * 60
        }

        // Créer les entries pour les prochaines 24h
        for offset in stride(from: 0, to: 24 * 60 * 60, by: Int(refreshInterval)) {
            let entryDate = calendar.date(byAdding: .second, value: offset, to: currentDate)!
            let mealData = loadMealData()
            let entry = MealEntry(date: entryDate, mealData: mealData)
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // Charger les données depuis SharedPreferences Flutter
    func loadMealData() -> MealData {
        guard let userDefaults = UserDefaults(suiteName: "group.com.ryse.app"),
              let jsonString = userDefaults.string(forKey: "widget_meal_data"),
              let jsonData = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("⚠️ Impossible de charger les données du widget")
            return MealData.placeholder()
        }

        return MealData.from(json: json)
    }
}

// MARK: - Models

struct MealEntry: TimelineEntry {
    let date: Date
    let mealData: MealData
}

struct MealData {
    let contextualMeal: ContextualMeal
    let allMeals: [MealInfo]
    let totals: Totals
    let macros: Macros

    struct ContextualMeal {
        let type: String
        let name: String
        let emoji: String
        let calories: Int
        let hasItems: Bool
        let itemCount: Int
    }

    struct MealInfo {
        let type: String
        let name: String
        let emoji: String
        let calories: Int
        let hasItems: Bool
        let itemCount: Int
    }

    struct Totals {
        let current: Int
        let goal: Int
        let percentage: Int
    }

    struct Macros {
        let protein: Int
        let carbs: Int
        let fats: Int
    }

    static func placeholder() -> MealData {
        return MealData(
            contextualMeal: ContextualMeal(
                type: "dejeuner",
                name: "Déjeuner",
                emoji: "🌤️",
                calories: 0,
                hasItems: false,
                itemCount: 0
            ),
            allMeals: [
                MealInfo(type: "petit-dejeuner", name: "Petit-déjeuner", emoji: "🌅", calories: 0, hasItems: false, itemCount: 0),
                MealInfo(type: "dejeuner", name: "Déjeuner", emoji: "🌤️", calories: 0, hasItems: false, itemCount: 0),
                MealInfo(type: "diner", name: "Dîner", emoji: "🌙", calories: 0, hasItems: false, itemCount: 0)
            ],
            totals: Totals(current: 0, goal: 2000, percentage: 0),
            macros: Macros(protein: 0, carbs: 0, fats: 0)
        )
    }

    static func from(json: [String: Any]) -> MealData {
        // Parse contextualMeal
        let contextualMealJson = json["contextualMeal"] as? [String: Any] ?? [:]
        let contextualMeal = ContextualMeal(
            type: contextualMealJson["type"] as? String ?? "dejeuner",
            name: contextualMealJson["name"] as? String ?? "Déjeuner",
            emoji: contextualMealJson["emoji"] as? String ?? "🌤️",
            calories: contextualMealJson["calories"] as? Int ?? 0,
            hasItems: contextualMealJson["hasItems"] as? Bool ?? false,
            itemCount: contextualMealJson["itemCount"] as? Int ?? 0
        )

        // Parse allMeals
        let allMealsJson = json["allMeals"] as? [[String: Any]] ?? []
        let allMeals = allMealsJson.map { mealJson in
            MealInfo(
                type: mealJson["type"] as? String ?? "",
                name: mealJson["name"] as? String ?? "",
                emoji: mealJson["emoji"] as? String ?? "🍽️",
                calories: mealJson["calories"] as? Int ?? 0,
                hasItems: mealJson["hasItems"] as? Bool ?? false,
                itemCount: mealJson["itemCount"] as? Int ?? 0
            )
        }

        // Parse totals
        let totalsJson = json["totals"] as? [String: Any] ?? [:]
        let totals = Totals(
            current: totalsJson["current"] as? Int ?? 0,
            goal: totalsJson["goal"] as? Int ?? 2000,
            percentage: totalsJson["percentage"] as? Int ?? 0
        )

        // Parse macros
        let macrosJson = json["macros"] as? [String: Any] ?? [:]
        let macros = Macros(
            protein: macrosJson["protein"] as? Int ?? 0,
            carbs: macrosJson["carbs"] as? Int ?? 0,
            fats: macrosJson["fats"] as? Int ?? 0
        )

        return MealData(
            contextualMeal: contextualMeal,
            allMeals: allMeals,
            totals: totals,
            macros: macros
        )
    }
}

// MARK: - Widget Views

struct RyseMealWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Lock Screen)

struct SmallWidgetView: View {
    var entry: MealEntry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0B132B"), Color(hex: "1C2951")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 8) {
                // Emoji du repas
                Text(entry.mealData.contextualMeal.emoji)
                    .font(.system(size: 32))

                // Nom du repas
                Text(entry.mealData.contextualMeal.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)

                // Calories du repas
                Text("\(entry.mealData.contextualMeal.calories) kcal")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)

                Spacer().frame(height: 4)

                // Quick actions
                HStack(spacing: 4) {
                    QuickActionButton(icon: "pencil", mealType: entry.mealData.contextualMeal.type, mode: "manual")
                    QuickActionButton(icon: "camera.fill", mealType: entry.mealData.contextualMeal.type, mode: "camera")
                    QuickActionButton(icon: "barcode.viewfinder", mealType: entry.mealData.contextualMeal.type, mode: "barcode")
                }
            }
            .padding(12)
        }
        .widgetURL(URL(string: "ryse://add-food?meal=\(entry.mealData.contextualMeal.type)")!)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    var entry: MealEntry

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "0B132B"), Color(hex: "1C2951")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("🍽️ Repas")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Text(formattedTime())
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)

                Spacer().frame(height: 12)

                // Contextual Meal with [+] button
                Link(destination: URL(string: "ryse://add-food?meal=\(entry.mealData.contextualMeal.type)")!) {
                    HStack {
                        Text(entry.mealData.contextualMeal.emoji)
                            .font(.system(size: 20))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.mealData.contextualMeal.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)

                            Text("\(entry.mealData.contextualMeal.calories) kcal")
                                .font(.system(size: 11))
                                .foregroundColor(.orange)
                        }

                        Spacer()

                        // [+] Button
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 12)

                // Quick Actions
                HStack(spacing: 8) {
                    ForEach(quickActions, id: \.mode) { action in
                        Link(destination: URL(string: "ryse://add-food?meal=\(entry.mealData.contextualMeal.type)&mode=\(action.mode)")!) {
                            VStack(spacing: 4) {
                                Image(systemName: action.icon)
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(0.15))
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)

                Spacer().frame(height: 12)

                // Progress bar
                VStack(spacing: 4) {
                    HStack {
                        Text("📊 Total")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("\(entry.mealData.totals.current) / \(entry.mealData.totals.goal) kcal")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .cornerRadius(4)

                            Rectangle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color.orange, Color.red],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(min(entry.mealData.totals.percentage, 100)) / 100)
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 8)
                }
                .padding(.horizontal, 16)

                Spacer()
            }
        }
    }

    func formattedTime() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: Date())
    }

    var quickActions: [(icon: String, mode: String)] {
        [
            ("pencil", "manual"),
            ("camera.fill", "camera"),
            ("barcode.viewfinder", "barcode"),
            ("fork.knife", "recipe"),
            ("message.fill", "chat")
        ]
    }
}

// MARK: - Quick Action Button (Small Widget)

struct QuickActionButton: View {
    let icon: String
    let mealType: String
    let mode: String

    var body: some View {
        Link(destination: URL(string: "ryse://add-food?meal=\(mealType)&mode=\(mode)")!) {
            Image(systemName: icon)
                .font(.system(size: 12))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.white.opacity(0.15))
                .cornerRadius(8)
        }
    }
}

// MARK: - Color Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
