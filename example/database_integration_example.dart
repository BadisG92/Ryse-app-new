import 'package:flutter/material.dart';
import '../lib/services/database_service.dart';
import '../lib/types/database_types.dart';

/// Exemple d'intégration de la nouvelle architecture de base de données simplifiée
/// 
/// Cet exemple démontre comment utiliser le DatabaseService pour :
/// - Récupérer des données localisées
/// - Créer du contenu personnalisé
/// - Gérer l'historique utilisateur
/// - Afficher des résumés quotidiens

class DatabaseIntegrationExample extends StatefulWidget {
  @override
  _DatabaseIntegrationExampleState createState() => _DatabaseIntegrationExampleState();
}

class _DatabaseIntegrationExampleState extends State<DatabaseIntegrationExample> {
  List<Exercise> exercises = [];
  List<Food> foods = [];
  List<HiitWorkout> hiitWorkouts = [];
  List<Recipe> recipes = [];
  UserDailySummary? dailySummary;
  bool isLoading = true;
  String currentLanguage = 'fr';

  @override
  void initState() {
    super.initState();
    loadAllData();
  }

  Future<void> loadAllData() async {
    setState(() => isLoading = true);
    
    try {
      // Charger toutes les données en parallèle pour de meilleures performances
      final results = await Future.wait([
        DatabaseService.getExercises(language: currentLanguage),
        DatabaseService.getFoods(language: currentLanguage),
        DatabaseService.getHiitWorkouts(language: currentLanguage),
        DatabaseService.getRecipes(language: currentLanguage),
      ]);

      // Charger le résumé quotidien (nécessite un userId réel)
      // final summary = await DatabaseService.getUserDailySummary('user-id-here');

      setState(() {
        exercises = results[0] as List<Exercise>;
        foods = results[1] as List<Food>;
        hiitWorkouts = results[2] as List<HiitWorkout>;
        recipes = results[3] as List<Recipe>;
        // dailySummary = summary;
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() => isLoading = false);
    }
  }

  void toggleLanguage() {
    setState(() {
      currentLanguage = currentLanguage == 'fr' ? 'en' : 'fr';
    });
    loadAllData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Database Integration Example'),
        actions: [
          IconButton(
            icon: Icon(Icons.language),
            onPressed: toggleLanguage,
            tooltip: 'Changer de langue (${currentLanguage.toUpperCase()})',
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLanguageIndicator(),
                  SizedBox(height: 20),
                  _buildDataSummary(),
                  SizedBox(height: 20),
                  _buildExercisesSection(),
                  SizedBox(height: 20),
                  _buildFoodsSection(),
                  SizedBox(height: 20),
                  _buildHiitWorkoutsSection(),
                  SizedBox(height: 20),
                  _buildRecipesSection(),
                  SizedBox(height: 20),
                  _buildCustomContentSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildLanguageIndicator() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.language, color: Colors.blue),
            SizedBox(width: 8),
            Text(
              'Langue actuelle: ${currentLanguage == 'fr' ? 'Français' : 'English'}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: toggleLanguage,
              child: Text('Changer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSummary() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Résumé des Données',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard('Exercices', exercises.length, Icons.fitness_center),
                _buildStatCard('Aliments', foods.length, Icons.restaurant),
                _buildStatCard('HIIT', hiitWorkouts.length, Icons.timer),
                _buildStatCard('Recettes', recipes.length, Icons.book),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, int count, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        SizedBox(height: 4),
        Text(
          count.toString(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildExercisesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exercices (${exercises.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...exercises.take(5).map((exercise) => ListTile(
              leading: Icon(Icons.fitness_center),
              title: Text(exercise.getLocalizedName(currentLanguage)),
              subtitle: Text('${exercise.muscleGroup} • ${exercise.equipment ?? 'N/A'}'),
              trailing: exercise.isCustom 
                  ? Chip(label: Text('Custom'), backgroundColor: Colors.orange.shade100)
                  : null,
            )),
            if (exercises.length > 5)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('... et ${exercises.length - 5} autres'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aliments (${foods.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...foods.take(5).map((food) => ListTile(
              leading: Icon(Icons.restaurant),
              title: Text(food.getLocalizedName(currentLanguage)),
              subtitle: Text('${food.calories} cal • P:${food.proteins}g C:${food.carbs}g F:${food.fats}g'),
              trailing: food.category != null 
                  ? Chip(label: Text(food.category!), backgroundColor: Colors.green.shade100)
                  : null,
            )),
            if (foods.length > 5)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('... et ${foods.length - 5} autres'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHiitWorkoutsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Entraînements HIIT (${hiitWorkouts.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...hiitWorkouts.map((workout) => ListTile(
              leading: Icon(Icons.timer),
              title: Text(workout.getLocalizedTitle(currentLanguage)),
              subtitle: Text(
                '${workout.workDuration}s travail • ${workout.restDuration}s repos • ${workout.totalRounds} rounds'
              ),
              trailing: Text('${(workout.totalDuration / 60).round()} min'),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recettes (${recipes.length})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            ...recipes.take(3).map((recipe) => ListTile(
              leading: Icon(Icons.book),
              title: Text(recipe.getLocalizedName(currentLanguage)),
              subtitle: Text(
                '${recipe.servings} portions • ${recipe.difficulty ?? 'N/A'} • ${recipe.getLocalizedSteps(currentLanguage).length} étapes'
              ),
              trailing: recipe.duration != null 
                  ? Chip(label: Text(recipe.duration!))
                  : null,
            )),
            if (recipes.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('... et ${recipes.length - 3} autres'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomContentSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Créer du Contenu Personnalisé',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Exemples de création de contenu personnalisé avec la nouvelle API:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            SizedBox(height: 16),
            _buildCustomExampleButton(
              'Créer Exercice Personnalisé',
              Icons.fitness_center,
              _createCustomExercise,
            ),
            SizedBox(height: 8),
            _buildCustomExampleButton(
              'Créer Aliment Personnalisé',
              Icons.restaurant,
              _createCustomFood,
            ),
            SizedBox(height: 8),
            _buildCustomExampleButton(
              'Créer Recette Personnalisée',
              Icons.book,
              _createCustomRecipe,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomExampleButton(String label, IconData icon, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  void _createCustomExercise() async {
    try {
      final customExercise = Exercise(
        id: '', // Sera généré par Supabase
        nameEn: 'My Custom Push-up',
        nameFr: 'Mes Pompes Personnalisées',
        muscleGroup: 'chest',
        equipment: 'bodyweight',
        description: 'A custom variation of push-ups',
        isCustom: true,
        userId: 'current-user-id', // Remplacer par l'ID utilisateur réel
      );

      // Note: Cette fonction nécessite une authentification réelle
      // final created = await DatabaseService.createCustomExercise(customExercise);
      
      _showSuccessDialog('Exercice personnalisé créé avec succès !');
    } catch (e) {
      _showErrorDialog('Erreur lors de la création: $e');
    }
  }

  void _createCustomFood() async {
    try {
      final customFood = Food(
        id: '', // Sera généré par Supabase
        nameEn: 'My Custom Smoothie',
        nameFr: 'Mon Smoothie Personnalisé',
        calories: 150,
        proteins: 5.0,
        carbs: 25.0,
        fats: 3.0,
        category: 'Boissons',
        isCustom: true,
        userId: 'current-user-id', // Remplacer par l'ID utilisateur réel
      );

      // Note: Cette fonction nécessite une authentification réelle
      // final created = await DatabaseService.createCustomFood(customFood);
      
      _showSuccessDialog('Aliment personnalisé créé avec succès !');
    } catch (e) {
      _showErrorDialog('Erreur lors de la création: $e');
    }
  }

  void _createCustomRecipe() async {
    try {
      final customRecipe = Recipe(
        id: '', // Sera généré par Supabase
        nameEn: 'My Custom Recipe',
        nameFr: 'Ma Recette Personnalisée',
        ingredients: [
          {'quantity': 2, 'unit': 'cups', 'food_name': 'Flour'},
          {'quantity': 1, 'unit': 'cup', 'food_name': 'Sugar'},
        ],
        stepsEn: ['Mix ingredients', 'Bake for 30 minutes'],
        stepsFr: ['Mélanger les ingrédients', 'Cuire pendant 30 minutes'],
        servings: 4,
        difficulty: 'easy',
        tags: ['dessert', 'homemade'],
        isCustom: true,
        userId: 'current-user-id', // Remplacer par l'ID utilisateur réel
      );

      // Note: Cette fonction nécessite une authentification réelle
      // final created = await DatabaseService.createCustomRecipe(customRecipe);
      
      _showSuccessDialog('Recette personnalisée créée avec succès !');
    } catch (e) {
      _showErrorDialog('Erreur lors de la création: $e');
    }
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Succès'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Exemple d'utilisation des fonctions de recherche
class SearchExample extends StatefulWidget {
  @override
  _SearchExampleState createState() => _SearchExampleState();
}

class _SearchExampleState extends State<SearchExample> {
  List<Food> searchResults = [];
  TextEditingController searchController = TextEditingController();

  void searchFoods(String query) async {
    if (query.isEmpty) {
      setState(() => searchResults = []);
      return;
    }

    try {
      final results = await DatabaseService.searchFoods(query, language: 'fr');
      setState(() => searchResults = results);
    } catch (e) {
      print('Erreur de recherche: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Recherche d\'Aliments')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Rechercher un aliment...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: searchFoods,
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: searchResults.length,
                itemBuilder: (context, index) {
                  final food = searchResults[index];
                  return ListTile(
                    title: Text(food.getLocalizedName('fr')),
                    subtitle: Text('${food.calories} cal • ${food.category ?? 'N/A'}'),
                    trailing: Text('P:${food.proteins}g'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
} 