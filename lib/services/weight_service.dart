import 'package:supabase_flutter/supabase_flutter.dart';
import '../components/ui/global_progress_models.dart';

class WeightService {
  static final _supabase = Supabase.instance.client;

  /// Récupère la progression du poids depuis l'historique du profil utilisateur
  static Future<WeightProgress> getWeightProgress() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer l'historique des poids triés par date (seulement les pesées intentionnelles)
      // Trier par date ET par heure pour prendre la plus récente en cas de multiples pesées le même jour
      final response = await _supabase
          .from('user_profile_history')
          .select('weight, valid_from, target_weight')
          .eq('user_id', user.id)
          .eq('weight_modified', true)
          .not('weight', 'is', null)
          .order('valid_from', ascending: true);

      final data = List<Map<String, dynamic>>.from(response);
      
      if (data.isEmpty) {
        // Essayer de créer une entrée initiale pour les utilisateurs existants
        try {
          await createInitialWeightEntry();
          // Refaire la requête après la création
          final retryResponse = await _supabase
              .from('user_profile_history')
              .select('weight, valid_from, target_weight')
              .eq('user_id', user.id)
              .eq('weight_modified', true)
              .not('weight', 'is', null)
              .order('valid_from', ascending: true);
          
          final retryData = List<Map<String, dynamic>>.from(retryResponse);
          if (retryData.isNotEmpty) {
            // Utiliser les données créées
            final entries = retryData.map((item) {
              return WeightEntry(
                date: DateTime.parse(item['valid_from']),
                weight: (item['weight'] as num).toDouble(),
              );
            }).toList();

            final currentWeight = entries.last.weight;
            final initialWeight = entries.first.weight;
            final previousWeight = entries.length > 1 ? entries[entries.length - 2].weight : currentWeight;
            final targetWeight = (retryData.last['target_weight'] as num?)?.toDouble() ?? currentWeight;

            return WeightProgress(
              currentWeight: currentWeight,
              previousWeight: previousWeight,
              initialWeight: initialWeight,
              targetWeight: targetWeight,
              entries: entries,
            );
          }
        } catch (e) {
          print('Impossible de créer une entrée initiale: $e');
        }
        
        // Fallback: récupérer depuis la table users
        final userResponse = await _supabase
            .from('users')
            .select('weight, target_weight')
            .eq('id', user.id)
            .single();
        
        final currentWeight = (userResponse['weight'] as num?)?.toDouble() ?? 70.0;
        final targetWeight = (userResponse['target_weight'] as num?)?.toDouble() ?? currentWeight;
        
        print('DEBUG WeightService FALLBACK - currentWeight: $currentWeight, targetWeight: $targetWeight');
        
        return WeightProgress(
          currentWeight: currentWeight,
          previousWeight: currentWeight,
          initialWeight: currentWeight,
          targetWeight: targetWeight,
          entries: [
            WeightEntry(
              date: DateTime.now(),
              weight: currentWeight,
            ),
          ],
        );
      }

      // Convertir les données en entrées de poids et grouper par jour (prendre la plus récente par jour)
      final Map<String, WeightEntry> entriesByDay = {};
      
      for (final item in data) {
        final date = DateTime.parse(item['valid_from']);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final entry = WeightEntry(
          date: date,
          weight: (item['weight'] as num).toDouble(),
        );
        
        // Garder seulement l'entrée la plus récente pour chaque jour
        if (!entriesByDay.containsKey(dateKey) || 
            date.isAfter(entriesByDay[dateKey]!.date)) {
          entriesByDay[dateKey] = entry;
        }
      }
      
      // Trier les entrées par date
      final entries = entriesByDay.values.toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      // Données pour la progression
      final currentWeight = entries.last.weight;
      final initialWeight = entries.first.weight;
      final previousWeight = entries.length > 1 ? entries[entries.length - 2].weight : currentWeight;
      final targetWeight = (data.last['target_weight'] as num?)?.toDouble() ?? currentWeight;

      print('DEBUG WeightService - currentWeight: $currentWeight, targetWeight: $targetWeight, entries: ${entries.length}');

      return WeightProgress(
        currentWeight: currentWeight,
        previousWeight: previousWeight,
        initialWeight: initialWeight,
        targetWeight: targetWeight,
        entries: entries,
      );
    } catch (e) {
      print('Erreur lors du chargement des données de poids: $e');
      rethrow;
    }
  }

  /// Enregistre un nouveau poids dans l'historique utilisateur
  static Future<void> saveWeightEntry(double weight) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Récupérer le profil actuel
      final currentProfile = await _supabase
          .from('users')
          .select('weight, target_weight, height, age, gender, activity_level, fitness_goal, daily_calories, daily_protein, daily_carbs, daily_fat, bmr, dietary_restrictions')
          .eq('id', user.id)
          .single();

      // Marquer l'entrée actuelle comme non-courante si elle existe
      await _supabase
          .from('user_profile_history')
          .update({'is_current': false, 'valid_until': DateTime.now().toIso8601String()})
          .eq('user_id', user.id)
          .eq('is_current', true);

      // Créer une nouvelle entrée dans l'historique
      await _supabase
          .from('user_profile_history')
          .insert({
        'user_id': user.id,
        'weight': weight,
        'target_weight': currentProfile['target_weight'],
        'height': currentProfile['height'],
        'age': currentProfile['age'],
        'gender': currentProfile['gender'],
        'activity_level': currentProfile['activity_level'],
        'fitness_goal': currentProfile['fitness_goal'],
        'daily_calories': currentProfile['daily_calories'],
        'daily_protein': currentProfile['daily_protein'],
        'daily_carbs': currentProfile['daily_carbs'],
        'daily_fat': currentProfile['daily_fat'],
        'bmr': currentProfile['bmr'],
        'dietary_restrictions': currentProfile['dietary_restrictions'],
        'valid_from': DateTime.now().toIso8601String(),
        'is_current': true,
        'change_source': 'weight_update',
        'weight_modified': true,
      });

      // Mettre à jour le poids dans la table users
      await _supabase
          .from('users')
          .update({'weight': weight, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', user.id);

      print('Nouveau poids enregistré: ${weight}kg');
    } catch (e) {
      print('Erreur lors de l\'enregistrement du poids: $e');
      rethrow;
    }
  }

  /// Récupère l'historique des pesées pour la page de détail
  static Future<List<WeightEntry>> getWeightHistory() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      final response = await _supabase
          .from('user_profile_history')
          .select('weight, valid_from')
          .eq('user_id', user.id)
          .eq('weight_modified', true)
          .not('weight', 'is', null)
          .order('valid_from', ascending: false);

      final data = List<Map<String, dynamic>>.from(response);
      
      return data.map((item) {
        return WeightEntry(
          date: DateTime.parse(item['valid_from']),
          weight: (item['weight'] as num).toDouble(),
        );
      }).toList();
    } catch (e) {
      print('Erreur lors du chargement de l\'historique des poids: $e');
      rethrow;
    }
  }

  /// Obtient le poids actuel de l'utilisateur
  static Future<double?> getCurrentWeight() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('weight')
          .eq('id', user.id)
          .single();

      return (response['weight'] as num?)?.toDouble();
    } catch (e) {
      print('Erreur lors de la récupération du poids actuel: $e');
      return null;
    }
  }

  /// Obtient le poids cible de l'utilisateur
  static Future<double?> getTargetWeight() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('target_weight')
          .eq('id', user.id)
          .single();

      return (response['target_weight'] as num?)?.toDouble();
    } catch (e) {
      print('Erreur lors de la récupération du poids cible: $e');
      return null;
    }
  }

  /// Crée une entrée initiale de poids pour les utilisateurs existants qui n'en ont pas
  /// Utile pour migrer les utilisateurs existants vers le nouveau système
  static Future<void> createInitialWeightEntry() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('Utilisateur non connecté');
      }

      // Vérifier s'il existe déjà des entrées de poids intentionnelles
      final existingEntries = await _supabase
          .from('user_profile_history')
          .select('id')
          .eq('user_id', user.id)
          .eq('weight_modified', true)
          .limit(1);

      if (existingEntries.isNotEmpty) {
        print('L\'utilisateur a déjà des entrées de poids');
        return;
      }

      // Récupérer le profil utilisateur actuel
      final userProfile = await _supabase
          .from('users')
          .select('weight, target_weight, height, age, gender, activity_level, fitness_goal, daily_calories, daily_protein, daily_carbs, daily_fat, bmr, dietary_restrictions')
          .eq('id', user.id)
          .single();

      final weight = (userProfile['weight'] as num?)?.toDouble();
      if (weight == null || weight <= 0) {
        print('Aucun poids valide trouvé pour créer une entrée initiale');
        return;
      }

      // Créer l'entrée initiale
      await _supabase
          .from('user_profile_history')
          .insert({
        'user_id': user.id,
        'weight': weight,
        'target_weight': userProfile['target_weight'],
        'height': userProfile['height'],
        'age': userProfile['age'],
        'gender': userProfile['gender'],
        'activity_level': userProfile['activity_level'],
        'fitness_goal': userProfile['fitness_goal'],
        'daily_calories': userProfile['daily_calories'],
        'daily_protein': userProfile['daily_protein'],
        'daily_carbs': userProfile['daily_carbs'],
        'daily_fat': userProfile['daily_fat'],
        'bmr': userProfile['bmr'],
        'dietary_restrictions': userProfile['dietary_restrictions'],
        'valid_from': DateTime.now().toIso8601String(),
        'is_current': true,
        'change_source': 'initial_migration',
        'weight_modified': true,
      });

      print('Entrée de poids initiale créée pour l\'utilisateur existant');
    } catch (e) {
      print('Erreur lors de la création de l\'entrée initiale: $e');
      rethrow;
    }
  }
}