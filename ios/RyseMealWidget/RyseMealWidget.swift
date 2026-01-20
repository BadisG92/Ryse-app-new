//
//  RyseMealWidget.swift
//  RyseMealWidget
//
//  Widget iOS pour afficher le repas contextuel et les calories
//

import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

// MARK: - Widget Configuration

struct RyseMealWidget: Widget {
    let kind: String = "RyseMealWidget"
    private let localizationProvider = WidgetLocalizationProvider.shared

    var body: some WidgetConfiguration {
        let localization = localizationProvider.currentTranslations()

        return StaticConfiguration(kind: kind, provider: Provider()) { entry in
            RyseMealWidgetEntryView(entry: entry)
        }
        .configurationDisplayName(LocalizedStringKey(localization.widgetTitle))
        .description(LocalizedStringKey(localization.widgetDescription))
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
        guard let userDefaults = UserDefaults(suiteName: "group.com.ryze.app") else {
            print("❌ ERREUR: App Group 'group.com.ryze.app' non disponible!")
            print("   Vérifier la configuration dans Xcode > Signing & Capabilities")
            return MealData.placeholder()
        }

        guard let jsonString = userDefaults.string(forKey: "widget_meal_data") else {
            print("⚠️ Aucune donnée widget trouvée dans UserDefaults")
            print("   L'app doit être lancée au moins une fois pour synchroniser les données")
            // Sauvegarder un placeholder pour éviter les valeurs par défaut la prochaine fois
            let placeholder = MealData.placeholder()
            return placeholder
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            print("❌ ERREUR: Impossible de convertir JSON string en Data")
            return MealData.placeholder()
        }

        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            print("❌ ERREUR: JSON invalide")
            print("   JSON String: \(String(jsonString.prefix(200)))...")
            return MealData.placeholder()
        }

        print("✅ Données widget chargées avec succès depuis App Group")

        // Vérifier les valeurs d'objectifs
        if let totals = json["totals"] as? [String: Any],
           let goal = totals["goal"] as? Int ?? (totals["goal"] as? Double).map({ Int($0) }) {
            print("   📊 Objectif calories: \(goal) kcal")
        }

        if let water = json["water"] as? [String: Any],
           let goalMl = water["goal"] as? Int ?? (water["goal"] as? Double).map({ Int($0) }),
           let goalL = water["goalL"] as? Double {
            print("   💧 Objectif eau: \(goalMl) ml (\(goalL) L)")
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
    let water: Water
    let localization: WidgetLocalizationStrings

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
    
    struct Water {
        let current: Int // en ml
        let goal: Int // en ml
        let percentage: Int
        let currentL: Double
        let goalL: Double
    }

    static func placeholder() -> MealData {
        // Charger les dernières valeurs connues depuis UserDefaults pour éviter les valeurs par défaut
        let lastKnownData = loadLastKnownData()

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
                MealInfo(type: "diner", name: "Dîner", emoji: "🌙", calories: 0, hasItems: false, itemCount: 0),
                MealInfo(type: "snack", name: "Collation", emoji: "🍎", calories: 0, hasItems: false, itemCount: 0)
            ],
            // Utiliser les vraies valeurs d'objectifs sauvegardées, ou 0 si non disponibles
            totals: Totals(
                current: 0,
                goal: lastKnownData?.totals.goal ?? 0,  // Utiliser la vraie valeur sauvegardée
                percentage: 0
            ),
            macros: Macros(protein: 0, carbs: 0, fats: 0),
            water: Water(
                current: 0,
                goal: lastKnownData?.water.goal ?? 0,  // Utiliser la vraie valeur sauvegardée
                percentage: 0,
                currentL: 0.0,
                goalL: lastKnownData?.water.goalL ?? 0.0  // Utiliser la vraie valeur sauvegardée
            ),
            localization: WidgetLocalizationStrings.fallback()
        )
    }

    // Vérifie si les données sont d'aujourd'hui en comparant lastUpdate
    private static func checkIfDataIsFromToday(json: [String: Any]) -> Bool {
        guard let lastUpdateStr = json["lastUpdate"] as? String else {
            print("⚠️ Pas de lastUpdate dans les données, considéré comme périmé")
            return false
        }

        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Essayer aussi sans les fractions de secondes
        guard let lastUpdate = isoFormatter.date(from: lastUpdateStr) ?? ISO8601DateFormatter().date(from: lastUpdateStr) else {
            print("⚠️ Format de date invalide: \(lastUpdateStr)")
            return false
        }

        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(lastUpdate)

        if !isToday {
            print("📅 Les données datent d'un jour précédent (\(lastUpdateStr)), affichage remis à 0")
        }

        return isToday
    }

    // Nouvelle méthode pour charger les dernières données connues
    private static func loadLastKnownData() -> MealData? {
        guard let userDefaults = UserDefaults(suiteName: "group.com.ryze.app") else {
            return nil
        }

        guard let jsonString = userDefaults.string(forKey: "widget_meal_data") else {
            return nil
        }

        guard let jsonData = jsonString.data(using: .utf8) else {
            return nil
        }

        guard let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            return nil
        }

        return MealData.from(json: json)
    }

    static func from(json: [String: Any]) -> MealData {
        // Vérifier si les données sont d'aujourd'hui
        let isDataFromToday = checkIfDataIsFromToday(json: json)

        // Parse contextualMeal
        let contextualMealJson = json["contextualMeal"] as? [String: Any] ?? [:]
        let contextualMeal = ContextualMeal(
            type: contextualMealJson["type"] as? String ?? "dejeuner",
            name: contextualMealJson["name"] as? String ?? "Déjeuner",
            emoji: contextualMealJson["emoji"] as? String ?? "🌤️",
            calories: isDataFromToday ? (contextualMealJson["calories"] as? Int ?? 0) : 0,
            hasItems: isDataFromToday ? (contextualMealJson["hasItems"] as? Bool ?? false) : false,
            itemCount: isDataFromToday ? (contextualMealJson["itemCount"] as? Int ?? 0) : 0
        )

        // Parse allMeals
        let allMealsJson = json["allMeals"] as? [[String: Any]] ?? []
        let allMeals = allMealsJson.map { mealJson in
            MealInfo(
                type: mealJson["type"] as? String ?? "",
                name: mealJson["name"] as? String ?? "",
                emoji: mealJson["emoji"] as? String ?? "🍽️",
                calories: isDataFromToday ? (mealJson["calories"] as? Int ?? 0) : 0,
                hasItems: isDataFromToday ? (mealJson["hasItems"] as? Bool ?? false) : false,
                itemCount: isDataFromToday ? (mealJson["itemCount"] as? Int ?? 0) : 0
            )
        }

        // Parse totals (utiliser les valeurs du JSON, pas de valeur par défaut)
        let totalsJson = json["totals"] as? [String: Any] ?? [:]
        let currentCalories = (totalsJson["current"] as? Int) ?? (totalsJson["current"] as? Double).map { Int($0) } ?? 0
        let goalCalories = (totalsJson["goal"] as? Int) ?? (totalsJson["goal"] as? Double).map { Int($0) } ?? 0
        let totals = Totals(
            current: isDataFromToday ? currentCalories : 0,
            goal: goalCalories, // L'objectif reste le même
            percentage: isDataFromToday ? ((totalsJson["percentage"] as? Int) ?? (totalsJson["percentage"] as? Double).map { Int($0) } ?? 0) : 0
        )

        print("📊 Données calories: \(totals.current) / \(totals.goal) kcal (\(totals.percentage)%)")
        if totals.goal == 0 {
            print("⚠️ ATTENTION: Objectif calories est 0! Vérifier la synchronisation des données")
        }

        // Parse macros
        let macrosJson = json["macros"] as? [String: Any] ?? [:]
        let macros = Macros(
            protein: isDataFromToday ? (macrosJson["protein"] as? Int ?? 0) : 0,
            carbs: isDataFromToday ? (macrosJson["carbs"] as? Int ?? 0) : 0,
            fats: isDataFromToday ? (macrosJson["fats"] as? Int ?? 0) : 0
        )

        // Parse water (utiliser les valeurs du JSON, pas de valeurs par défaut)
        let waterJson = json["water"] as? [String: Any] ?? [:]
        let currentWater = (waterJson["current"] as? Int) ?? (waterJson["current"] as? Double).map { Int($0) } ?? 0
        let goalWater = (waterJson["goal"] as? Int) ?? (waterJson["goal"] as? Double).map { Int($0) } ?? 0
        let currentWaterL = (waterJson["currentL"] as? Double) ?? 0.0
        let goalWaterL = (waterJson["goalL"] as? Double) ?? 0.0
        let water = Water(
            current: isDataFromToday ? currentWater : 0,
            goal: goalWater, // L'objectif reste le même
            percentage: isDataFromToday ? ((waterJson["percentage"] as? Int) ?? (waterJson["percentage"] as? Double).map { Int($0) } ?? 0) : 0,
            currentL: isDataFromToday ? currentWaterL : 0.0,
            goalL: goalWaterL // L'objectif reste le même
        )

        print("💧 Données eau: \(water.current)ml / \(water.goal)ml (\(water.percentage)%)")
        if water.goal == 0 {
            print("⚠️ ATTENTION: Objectif eau est 0! Vérifier la synchronisation des données")
        }

        let localization = WidgetLocalizationStrings.from(json: json["translations"] as? [String: Any])

        return MealData(
            contextualMeal: contextualMeal,
            allMeals: allMeals,
            totals: totals,
            macros: macros,
            water: water,
            localization: localization
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

// MARK: - Small Widget (Eau)

struct SmallWidgetView: View {
    var entry: MealEntry
    
    // Calculer le pourcentage de progression (peut dépasser 100%)
    private var waterPercentage: Double {
        let goal = entry.mealData.water.goal
        guard goal > 0 else { return 0 }
        let current = entry.mealData.water.current
        // Ne pas limiter à 1.0 pour permettre de dépasser l'objectif
        return Double(current) / Double(goal)
    }
    
    private var waterLabel: String {
        let current = entry.mealData.water.currentL
        let goal = entry.mealData.water.goalL
        guard goal > 0 else { return "0 / 0 L" }
        return String(format: "%.1f / %.1f L", current, goal)
    }
    
    private var hasCompletedWaterGoal: Bool {
        let goal = entry.mealData.water.goalL
        guard goal > 0 else { return false }
        return entry.mealData.water.currentL >= goal
    }

    var body: some View {
        ZStack {
            // Background gradient bleu (comme les calories cardio)
            LinearGradient(
                colors: [
                    Color(hex: "1C2951"), // Bleu secondaire
                    Color(hex: "2A3A6B")  // Version plus claire
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack(spacing: 6) {
                    if hasCompletedWaterGoal {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "8EF7C9"),
                                        Color(hex: "4ADE80")
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    Text(waterLabel)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.bottom, 6)
                
                Spacer()
                
                // Cercle de progression avec icône de verre d'eau au centre
                ZStack {
                    // Cercle de fond (gris clair)
                    Circle()
                        .stroke(Color.white.opacity(0.2), lineWidth: 6)
                        .frame(width: 60, height: 60)
                    
                    // Cercle de progression (bleu)
                    if waterPercentage > 0 {
                        Circle()
                            .trim(from: 0, to: min(waterPercentage, 1.0))
                            .stroke(
                                // Changer la couleur si on dépasse l'objectif
                                waterPercentage > 1.0 ? Color(hex: "4ADE80") : Color(hex: "60A5FA"),
                                style: StrokeStyle(lineWidth: 6, lineCap: .round)
                            )
                            .frame(width: 60, height: 60)
                            .rotationEffect(.degrees(-90)) // Commencer en haut
                    }
                    
                    // Icône de bouteille d'eau au centre
                    Image(systemName: "waterbottle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Spacer().frame(height: 8)
                
                // Boutons pour ajouter de l'eau directement (iOS 17+ avec App Intents)
                if #available(iOS 17.0, *) {
                    // iOS 17+ : Boutons interactifs sans ouvrir l'app
                    HStack(spacing: 6) {
                        Button(intent: AddWaterIntent(amount: 250)) {
                            Text("+250")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)

                        Button(intent: AddWaterIntent(amount: 500)) {
                            Text("+500")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.white.opacity(0.2))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    // iOS 16 : Link qui ouvre l'app
                    Link(destination: URL(string: "ryse://add-water")!) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer().frame(height: 8)
            }
            .padding(.horizontal, 10)
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(hex: "1C2951"), // Bleu secondaire
                    Color(hex: "2A3A6B")  // Version plus claire
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .widgetURL(URL(string: "ryse://add-water")!)
    }
}

// MARK: - Medium Widget

struct MediumWidgetView: View {
    var entry: MealEntry
    
    private var localization: WidgetLocalizationStrings {
        entry.mealData.localization
    }
    
    // Obtenir les repas dans l'ordre : Petit-déjeuner, Déjeuner, Dîner, Snack
    private var orderedMeals: [MealData.MealInfo] {
        let mealOrder = ["petit-dejeuner", "dejeuner", "diner", "snack"]
        return mealOrder.compactMap { mealType in
            entry.mealData.allMeals.first { $0.type == mealType }
        }
    }

    var body: some View {
        ZStack {
            // Background gradient bleu (comme les calories cardio - #1C2951)
            LinearGradient(
                colors: [
                    Color(hex: "1C2951"), // Bleu secondaire (couleur principale cardio)
                    Color(hex: "2A3A6B")  // Version plus claire pour le dégradé
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Barre de progression des calories en haut
                VStack(spacing: 4) {
                    HStack {
                        Text("\(entry.mealData.totals.current) / \(entry.mealData.totals.goal) kcal")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(hex: "60A5FA"))
                        Spacer()
                    }

                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            // Background
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))

                            // Progress
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "60A5FA"),
                                            Color(hex: "4ADE80")
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(min(entry.mealData.totals.percentage, 100)) / 100)
                        }
                    }
                    .frame(height: 6)
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)
                .padding(.bottom, 8)

                // Ligne horizontale des 4 repas
                HStack(spacing: 6) {
                    MealButton(meal: orderedMeals[safe: 0], localization: localization)
                    MealButton(meal: orderedMeals[safe: 1], localization: localization)
                    MealButton(meal: orderedMeals[safe: 2], localization: localization)
                    MealButton(meal: orderedMeals[safe: 3], localization: localization)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .containerBackground(for: .widget) {
            LinearGradient(
                colors: [
                    Color(hex: "1C2951"), // Bleu secondaire (couleur principale cardio)
                    Color(hex: "2A3A6B")  // Version plus claire pour le dégradé
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

}

// MARK: - Meal Button Component

struct MealButton: View {
    let meal: MealData.MealInfo?
    let localization: WidgetLocalizationStrings
    
    private func isSnack(_ mealType: String) -> Bool {
        let lower = mealType.lowercased()
        return lower == "snack" || lower == "collation"
    }
    
    // Obtenir l'icône SF Symbol selon le type de repas
    private func getMealIcon(_ mealType: String) -> String {
        switch mealType.lowercased() {
        case "petit-dejeuner", "breakfast":
            return "sunrise.fill" // LucideIcons.sunrise équivalent
        case "dejeuner", "lunch":
            return "sun.max.fill" // LucideIcons.sun équivalent
        case "diner", "dinner":
            return "sunset.fill" // LucideIcons.sunset équivalent
        case "snack", "collation":
            return "waterbottle.fill" // Fallback si l'asset n'est pas disponible
        default:
            return "fork.knife"
        }
    }
    
    @ViewBuilder
    private func iconView(for mealType: String) -> some View {
        if isSnack(mealType) {
            Image("MilkIcon")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(height: 20)
                .foregroundColor(.white)
        } else {
            Image(systemName: getMealIcon(mealType))
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .frame(height: 20)
        }
    }
    
    // Obtenir le nom court du repas
    private func getMealShortName(_ mealType: String) -> String {
        return localization.shortName(for: mealType)
    }
    
    var body: some View {
        if let meal = meal {
            Link(destination: URL(string: "ryse://add-food?meal=\(meal.type)")!) {
                VStack(spacing: 2) {
                    // Nom du repas (très petit, en haut)
                    Text(getMealShortName(meal.type))
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    // Icône SF Symbol du repas
                    iconView(for: meal.type)
                    
                    // Calories (format compact)
                    Text(meal.calories > 0 ? "\(meal.calories)" : "0")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(meal.calories > 0 ? Color(hex: "60A5FA") : .white.opacity(0.5))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "0B132B"), // Gradient foncé comme le fond
                                    Color(hex: "1C2951")
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            }
        } else {
            // Placeholder si le repas n'existe pas
            VStack(spacing: 2) {
                Text(localization.placeholderMeal)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .frame(height: 20)
                
                Text("0")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(hex: "0B132B"), // Gradient foncé comme le fond
                                Color(hex: "1C2951")
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
        }
    }
}

// MARK: - Array Safe Index Extension

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
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
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "0B132B"), Color(hex: "1C2951")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
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
