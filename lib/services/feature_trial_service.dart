import 'package:supabase_flutter/supabase_flutter.dart';

/// Service pour gérer les essais gratuits des features Premium
///
/// Règle : Chaque feature peut être utilisée 1 fois gratuitement par l'utilisateur,
/// puis nécessite un abonnement Premium pour les utilisations suivantes.
class FeatureTrialService {
  static final FeatureTrialService _instance = FeatureTrialService._internal();
  factory FeatureTrialService() => _instance;
  FeatureTrialService._internal();

  static FeatureTrialService get instance => _instance;

  final _supabase = Supabase.instance.client;

  // ═══════════════════════════════════════════════════════
  // CLÉS DES FEATURES PREMIUM
  // ═══════════════════════════════════════════════════════

  /// Scanner automatique de repas (photo)
  static const String keyScanner = 'feature_scanner_used';

  /// Scanner de codes-barres
  static const String keyBarcode = 'feature_barcode_used';

  /// Chat avec le Coach Ryze (texte/vocal)
  static const String keyChat = 'feature_chat_used';

  /// Générateur de workouts personnalisés
  static const String keyWorkout = 'feature_workout_used';

  /// Bilan nutritionnel quotidien
  static const String keyNutritionAnalysis = 'feature_nutrition_analysis_used';

  /// Analyse de progression par exercice
  static const String keyExerciseAnalysis = 'feature_exercise_analysis_used';

  // ═══════════════════════════════════════════════════════
  // MÉTHODES PUBLIQUES
  // ═══════════════════════════════════════════════════════

  /// Vérifier si l'utilisateur a déjà utilisé son essai gratuit pour cette feature
  ///
  /// Retourne `true` si l'essai a déjà été utilisé, `false` sinon.
  /// Retourne `false` si l'utilisateur n'est pas connecté.
  Future<bool> hasUsedFreeTrial(String featureKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ FeatureTrialService: User not logged in');
      return false;
    }

    try {
      final response = await _supabase
          .from('user_feature_trials')
          .select('used')
          .eq('user_id', userId)
          .eq('feature_key', featureKey)
          .maybeSingle();

      final hasUsed = response?['used'] == true;
      print('✅ FeatureTrialService: hasUsedFreeTrial($featureKey) = $hasUsed');
      return hasUsed;
    } catch (e) {
      print('❌ FeatureTrialService: Error checking trial for $featureKey: $e');
      return false; // En cas d'erreur, autoriser l'accès
    }
  }

  /// Marquer la feature comme utilisée (essai gratuit consommé)
  ///
  /// Cette méthode doit être appelée après que l'utilisateur a utilisé
  /// sa première fois gratuite d'une feature Premium.
  Future<void> markFeatureAsUsed(String featureKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ FeatureTrialService: User not logged in, cannot mark feature as used');
      return;
    }

    try {
      await _supabase.from('user_feature_trials').upsert({
        'user_id': userId,
        'feature_key': featureKey,
        'used': true,
        'used_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,feature_key');

      print('✅ FeatureTrialService: Marked $featureKey as used for user $userId');
    } catch (e) {
      print('❌ FeatureTrialService: Error marking $featureKey as used: $e');
    }
  }

  /// Réinitialiser l'essai gratuit pour une feature (pour testing ou support)
  ///
  /// ⚠️ À utiliser avec précaution : cela permet à l'utilisateur de réutiliser
  /// son essai gratuit.
  Future<void> resetTrial(String featureKey) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ FeatureTrialService: User not logged in, cannot reset trial');
      return;
    }

    try {
      await _supabase
          .from('user_feature_trials')
          .delete()
          .eq('user_id', userId)
          .eq('feature_key', featureKey);

      print('✅ FeatureTrialService: Reset trial for $featureKey for user $userId');
    } catch (e) {
      print('❌ FeatureTrialService: Error resetting trial for $featureKey: $e');
    }
  }

  /// Réinitialiser tous les essais gratuits pour l'utilisateur (pour testing)
  ///
  /// ⚠️ À utiliser uniquement pour le développement ou le support client
  Future<void> resetAllTrials() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ FeatureTrialService: User not logged in, cannot reset all trials');
      return;
    }

    try {
      await _supabase
          .from('user_feature_trials')
          .delete()
          .eq('user_id', userId);

      print('✅ FeatureTrialService: Reset all trials for user $userId');
    } catch (e) {
      print('❌ FeatureTrialService: Error resetting all trials: $e');
    }
  }

  /// Obtenir la liste des features déjà utilisées par l'utilisateur
  ///
  /// Utile pour afficher dans les paramètres ou pour le debugging
  Future<List<String>> getUsedFeatures() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      print('⚠️ FeatureTrialService: User not logged in');
      return [];
    }

    try {
      final response = await _supabase
          .from('user_feature_trials')
          .select('feature_key')
          .eq('user_id', userId)
          .eq('used', true);

      final features = (response as List)
          .map((item) => item['feature_key'] as String)
          .toList();

      print('✅ FeatureTrialService: User has used ${features.length} features: $features');
      return features;
    } catch (e) {
      print('❌ FeatureTrialService: Error getting used features: $e');
      return [];
    }
  }
}
