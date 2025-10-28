/// EXEMPLE D'INTÉGRATION DU TUTORIAL DANS LE DASHBOARD
///
/// Ce fichier montre comment intégrer le TutorialService dans main_dashboard_hybrid.dart
/// NE PAS UTILISER CE FICHIER DIRECTEMENT - C'est juste un exemple de référence
///
/// Pour l'implémenter dans votre dashboard existant, suivez ces étapes:

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        ÉTAPE 1: IMPORTS NÉCESSAIRES                           ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Ajouter cet import en haut de main_dashboard_hybrid.dart:
*/

// import '../services/tutorial_service.dart';

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                     ÉTAPE 2: DÉCLARER LES GLOBALKEYS                          ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Dans la classe _MainDashboardHybridState, ajouter ces GlobalKeys:
*/

class _MainDashboardHybridStateExample {
  // NOUVEAU: GlobalKeys pour le tutorial
  final GlobalKey addFoodKey = GlobalKey();
  final GlobalKey addExerciseKey = GlobalKey();
  final GlobalKey caloriesCardKey = GlobalKey();
  final GlobalKey nutritionTabKey = GlobalKey();
  final GlobalKey sportTabKey = GlobalKey();

  // Le reste de vos variables existantes...
  // UserProfile? userProfile;
  // List<DailyGoal> dailyGoals = [];
  // etc.
}

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                   ÉTAPE 3: DÉCLENCHER LE TUTORIAL AU DÉMARRAGE               ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Dans initState(), ajouter ce code APRÈS le chargement des données:
*/

void initStateExample() {
  // super.initState();
  // ... votre code existant ...
  // _loadDashboardData();

  // NOUVEAU: Afficher le tutorial après que la page soit construite
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _showDashboardTutorial();
  });
}

Future<void> _showDashboardTutorial() async {
  // Obtenir le code de langue
  final locService = LocalizationService.instance;

  // Déclencher le tutorial
  await TutorialService().showDashboardTutorial(
    context: context,
    addFoodKey: addFoodKey,
    addExerciseKey: addExerciseKey,
    caloriesCardKey: caloriesCardKey,
    nutritionTabKey: nutritionTabKey,
    sportTabKey: sportTabKey,
    languageCode: locService.currentLanguageCode,
  );
}

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║            ÉTAPE 4: ATTACHER LES KEYS AUX WIDGETS CORRESPONDANTS             ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Vous devez trouver les widgets suivants dans votre code et ajouter les keys:

1. BOUTON "AJOUTER ALIMENT" (probablement dans QuickActionsSection):
   Wrap le widget avec une key:
*/

// AVANT:
// IconButton(
//   onPressed: () => _handleAddFood(),
//   icon: Icon(LucideIcons.plus),
// )

// APRÈS:
// Container(
//   key: addFoodKey,  // ← AJOUTER CETTE LIGNE
//   child: IconButton(
//     onPressed: () => _handleAddFood(),
//     icon: Icon(LucideIcons.plus),
//   ),
// )

/*
2. BOUTON "AJOUTER EXERCICE":
   Même principe
*/

// Container(
//   key: addExerciseKey,  // ← AJOUTER CETTE LIGNE
//   child: IconButton(
//     onPressed: () => _handleAddExercise(),
//     icon: Icon(LucideIcons.dumbbell),
//   ),
// )

/*
3. CARTE DES CALORIES (probablement EnhancedDailyGoalsSection ou CalorieCard):
   Trouver le widget Container/Card principal et ajouter la key
*/

// Container(
//   key: caloriesCardKey,  // ← AJOUTER CETTE LIGNE
//   child: CalorieProgressCard(...),
// )

/*
4. ONGLETS NAVIGATION (dans BottomNavigation):
   Les keys sont maintenant supportées directement. Dans main_app.dart, passer les keys:
*/

// Positioned(
//   bottom: 0,
//   child: BottomNavigation(
//     activeTab: _activeTab,
//     onTabChange: _onTabChange,
//     nutritionTabKey: nutritionTabKey,  // ← AJOUTER
//     sportTabKey: sportTabKey,          // ← AJOUTER
//   ),
// )

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                        ÉTAPE 5: GESTION DES KEYS PARTAGÉES                    ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Si les onglets sont dans main_app.dart mais le tutorial dans main_dashboard_hybrid.dart,
vous devez passer les keys via le constructeur:
*/

class MainDashboardHybridWithKeys {
  final Function(String)? onTabChange;
  final GlobalKey? nutritionTabKey;  // NOUVEAU
  final GlobalKey? sportTabKey;      // NOUVEAU

  const MainDashboardHybridWithKeys({
    super.key,
    this.onTabChange,
    this.nutritionTabKey,
    this.sportTabKey,
  });
}

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                          EXEMPLE COMPLET DE BUILD                             ║
╚═══════════════════════════════════════════════════════════════════════════════╝

Voici à quoi pourrait ressembler votre méthode build() modifiée:
*/

class BuildExample {
  Widget buildExample(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Header...

          // Contenu avec les keys attachées
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Objectifs du jour avec key
                  Container(
                    key: caloriesCardKey,  // ← AJOUTER LA KEY
                    child: EnhancedDailyGoalsSection(
                      goals: dailyGoals,
                      profile: userProfile!,
                    ),
                  ),

                  // Actions rapides
                  QuickActionsSection(
                    actions: [
                      QuickAction(
                        key: addFoodKey,  // ← AJOUTER LA KEY
                        title: 'Ajouter aliment',
                        icon: LucideIcons.apple,
                        onTap: () {},
                      ),
                      QuickAction(
                        key: addExerciseKey,  // ← AJOUTER LA KEY
                        title: 'Ajouter exercice',
                        icon: LucideIcons.dumbbell,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                       ÉTAPE 6: TESTER LE TUTORIAL                             ║
╚═══════════════════════════════════════════════════════════════════════════════╝

1. Installez les dépendances:
   flutter pub get

2. Lancez l'app:
   flutter run

3. Le tutorial devrait apparaître automatiquement au démarrage du dashboard

4. En mode debug (_debugMode = true), il s'affichera à chaque fois

5. Pour désactiver le mode debug, modifiez tutorial_service.dart ligne 15:
   static const bool _debugMode = false;
*/

/*
╔═══════════════════════════════════════════════════════════════════════════════╗
║                           POINTS D'ATTENTION                                  ║
╚═══════════════════════════════════════════════════════════════════════════════╝

⚠️ IMPORTANT:
- Les GlobalKeys doivent être déclarées dans le State, pas dans le Widget
- Les keys doivent être attachées AVANT que le tutorial ne se lance
- Utilisez WidgetsBinding.instance.addPostFrameCallback pour lancer après le build
- Si un widget avec key n'est pas trouvé, le tutorial sautera cette étape
- En mode debug, le tutorial s'affiche toujours (ignorer SharedPreferences)
- Les keys peuvent être null - le tutorial gérera ça gracieusement

📝 ORDRE DE PRIORITÉ:
1. ✅ Ajouter les imports et GlobalKeys
2. ✅ Attacher les keys aux widgets existants
3. ✅ Ajouter l'appel au tutorial dans initState
4. ✅ Tester avec flutter pub get + flutter run
5. ✅ Ajuster les positions des bulles si nécessaire (ContentAlign)

🎨 PERSONNALISATION:
- Les couleurs et styles sont déjà configurés pour matcher votre app
- Les traductions FR/EN sont déjà ajoutées
- Vous pouvez modifier les textes dans lib/services/translations.dart
- Pour changer l'opacité de l'overlay, modifier opacityShadow dans tutorial_service.dart
*/

// Ce fichier est UNIQUEMENT un exemple de référence
// Suivez les instructions ci-dessus pour l'implémenter dans votre code existant
