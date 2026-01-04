import 'package:flutter/material.dart';
import '../services/global_state_manager.dart';
import '../services/navigation_preloader.dart';
import '../services/water_service.dart';
import 'ai_scanner_screen.dart';

/// EXEMPLE: Comment optimiser n'importe quel écran existant
/// Copiez ce pattern dans vos screens pour éliminer la latence
class ExampleOptimizedScreen extends StatefulWidget {
  const ExampleOptimizedScreen({super.key});

  @override
  State<ExampleOptimizedScreen> createState() => _ExampleOptimizedScreenState();
}

class _ExampleOptimizedScreenState extends State<ExampleOptimizedScreen>
    with GlobalStateListener {

  // Données locales de la page
  List<dynamic>? _foodsList;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDataOptimized();
  }

  /// OPTIMISATION: Charger depuis le cache préchargé d'abord
  Future<void> _loadDataOptimized() async {
    // 1. INSTANTANÉ: Récupérer du cache préchargé
    final cachedFoods = NavigationPreloader.instance.getPreloadedData<List<dynamic>>('foods_list');

    if (cachedFoods != null) {
      setState(() {
        _foodsList = cachedFoods;
        _isLoading = false;
      });

      // Données affichées instantanément!
      debugPrint('⚡ Données chargées du cache en 0ms');

      // 2. Optionnel: Rafraîchir en arrière-plan si nécessaire
      _refreshInBackground();
    } else {
      // Fallback: Charger normalement si pas de cache
      setState(() => _isLoading = true);
      await _loadFromServer();
    }
  }

  /// Charger depuis le serveur
  Future<void> _loadFromServer() async {
    try {
      // Votre code existant de chargement
      // final foods = await DatabaseService.getFoods();

      setState(() {
        // _foodsList = foods;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Erreur: $e');
    }
  }

  /// Rafraîchir en arrière-plan sans bloquer l'UI
  void _refreshInBackground() {
    Future.delayed(Duration(milliseconds: 100), () async {
      try {
        // Récupérer les données fraîches
        // final freshFoods = await DatabaseService.getFoods();

        // Mettre à jour seulement si différent
        // if (mounted && _foodsList != freshFoods) {
        //   setState(() => _foodsList = freshFoods);
        // }
      } catch (e) {
        // Ignorer les erreurs en arrière-plan
      }
    });
  }

  /// OPTIMISATION: Réagir aux changements globaux instantanément
  @override
  void onGlobalStateUpdate(StateChangeEvent event) {
    // Mettre à jour l'UI immédiatement quand un autre écran modifie les données
    switch (event.type) {
      case ChangeType.calories:
        // Mettre à jour l'affichage des calories
        debugPrint('Calories mises à jour: ${event.value}');
        break;

      case ChangeType.water:
        // Mettre à jour l'affichage de l'eau
        debugPrint('Eau mise à jour: ${event.value}');
        break;

      case ChangeType.meals:
        // Recharger les repas si nécessaire
        _loadFromServer();
        break;

      default:
        break;
    }
  }

  /// OPTIMISATION: Naviguer avec préchargement
  void _navigateToOtherScreen() {
    NavigationPreloader.navigateWithPreload(
      context,
      const AIScannerScreen(),
      routeName: '/ai_scanner',
    );
  }

  /// OPTIMISATION: Ajouter de l'eau avec mise à jour globale instantanée
  void _addWaterOptimized() async {
    // 1. Mise à jour UI instantanée (0ms)
    GlobalStateManager.instance.updateWater(0.25); // +250ml

    // 2. Sauvegarder en base en arrière-plan
    WaterService.addWaterEntry(amount: 250).then((_) {
      debugPrint('✅ Eau sauvegardée en base');
    }).catchError((error) {
      // Rollback si erreur
      GlobalStateManager.instance.updateWater(-0.25);
      debugPrint('❌ Erreur: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Écran Optimisé')),
      body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : ListView(
            children: [
              // Affichage instantané des données globales
              Text('Calories: ${GlobalStateManager.instance.currentCalories}'),
              Text('Eau: ${GlobalStateManager.instance.currentWaterL}L'),

              // Votre UI existante
              if (_foodsList != null)
                ..._foodsList!.map((food) => ListTile(
                  title: Text(food.toString()),
                )),

              // Boutons d'action
              ElevatedButton(
                onPressed: _addWaterOptimized,
                child: Text('Ajouter de l\'eau'),
              ),

              ElevatedButton(
                onPressed: _navigateToOtherScreen,
                child: Text('Scanner un aliment'),
              ),
            ],
          ),
    );
  }
}