import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import 'localization_service.dart';

/// Service pour récupérer les exercices avec localisation
/// 
/// Exemple concret d'utilisation du système de localisation 
/// avec les vraies colonnes de la base de données
class LocalizedExerciseService {
  static SupabaseClient get _supabase => SupabaseConfig.client;

  /// Récupère les exercices avec nom et instructions localisés
  static Future<List<Map<String, dynamic>>> getExercises({
    String? muscleGroup,
    int? limit,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix(); // '_fr' ou '_en'
    
    try {
      var query = _supabase
          .from('exercises')
          .select('''
            id,
            name$suffix,
            instructions$suffix,
            muscle_group_fr,
            muscle_group_en,
            equipment,
            difficulty_level,
            video_url,
            image_url
          ''');
      
      if (muscleGroup != null) {
        // Filtrer par le groupe musculaire dans la langue appropriée
        query = query.eq('muscle_group$suffix', muscleGroup);
      }
      
      if (limit != null) {
        query = query.limit(limit);
      }
      
      return await query.order('name$suffix');
      
    } catch (e) {
      print('Erreur lors de la récupération des exercices: $e');
      return [];
    }
  }

  /// Récupère les activités cardio avec noms localisés
  static Future<List<Map<String, dynamic>>> getCardioActivities() async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      return await _supabase
          .from('cardio_activity_types')
          .select('''
            id,
            activity_key,
            name$suffix,
            description$suffix,
            icon_name,
            is_active,
            sort_order
          ''')
          .eq('is_active', true)
          .order('sort_order');
      
    } catch (e) {
      print('Erreur lors de la récupération des activités cardio: $e');
      return [];
    }
  }

  /// Récupère les formats d'activité cardio avec noms localisés
  static Future<List<Map<String, dynamic>>> getCardioFormats(String activityTypeId) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      return await _supabase
          .from('cardio_activity_formats')
          .select('''
            id,
            name$suffix,
            description$suffix,
            icon_name,
            is_trackable,
            is_configurable,
            config_type,
            default_duration_minutes,
            default_distance_km
          ''')
          .eq('activity_type_id', activityTypeId)
          .eq('is_active', true)
          .order('sort_order');
      
    } catch (e) {
      print('Erreur lors de la récupération des formats cardio: $e');
      return [];
    }
  }

  /// Récupère les templates d'entraînement avec noms localisés
  static Future<List<Map<String, dynamic>>> getWorkoutTemplates({
    bool onlyPublic = false,
    String? userId,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      var query = _supabase
          .from('workout_templates')
          .select('''
            id,
            name$suffix,
            description$suffix,
            difficulty_level,
            estimated_duration_minutes,
            target_muscle_groups,
            equipment_needed,
            is_custom,
            is_public,
            user_id,
            usage_count,
            average_rating
          ''');
      
      if (onlyPublic) {
        query = query.eq('is_public', true);
      }
      
      if (userId != null) {
        query = query.or('is_public.eq.true,user_id.eq.$userId');
      }
      
      return await query.order('average_rating', ascending: false);
      
    } catch (e) {
      print('Erreur lors de la récupération des templates: $e');
      return [];
    }
  }

  /// Récupère les exercices d'un template avec noms localisés
  static Future<List<Map<String, dynamic>>> getTemplateExercises(String templateId) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      return await _supabase
          .from('workout_template_exercises')
          .select('''
            id,
            order_index,
            suggested_sets,
            suggested_reps_min,
            suggested_reps_max,
            suggested_rest_seconds,
            notes$suffix,
            exercises!workout_template_exercises_exercise_id_fkey(
              id,
              name$suffix,
              muscle_group_fr,
              muscle_group_en,
              equipment,
              difficulty_level
            )
          ''')
          .eq('template_id', templateId)
          .order('order_index');
      
    } catch (e) {
      print('Erreur lors de la récupération des exercices du template: $e');
      return [];
    }
  }

  /// Récupère les workouts HIIT avec titres localisés  
  static Future<List<Map<String, dynamic>>> getHIITWorkouts({
    bool onlyPublic = false,
    String? userId,
  }) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      var query = _supabase
          .from('hiit_workouts')
          .select('''
            id,
            title$suffix,
            description$suffix,
            work_duration,
            rest_duration,
            total_duration,
            total_rounds,
            is_custom,
            is_public,
            user_id,
            community_rating,
            rating_count,
            tags
          ''');
      
      if (onlyPublic) {
        query = query.eq('is_public', true);
      }
      
      if (userId != null) {
        query = query.or('is_public.eq.true,user_id.eq.$userId');
      }
      
      return await query.order('community_rating', ascending: false);
      
    } catch (e) {
      print('Erreur lors de la récupération des workouts HIIT: $e');
      return [];
    }
  }

  /// Méthode utilitaire pour récupérer le texte localisé d'un résultat de requête
  static String getLocalizedText(Map<String, dynamic> data, String baseColumnName) {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    return data['$baseColumnName$suffix'] as String? ?? 
           data['${baseColumnName}_fr'] as String? ?? 
           data['${baseColumnName}_en'] as String? ?? 
           'Non disponible';
  }

  /// Exemple d'utilisation combinée : récupérer un exercice complet avec ses détails localisés
  static Future<Map<String, dynamic>?> getExerciseDetails(String exerciseId) async {
    final locService = LocalizationService.instance;
    final suffix = locService.getColumnSuffix();
    
    try {
      final result = await _supabase
          .from('exercises')
          .select('''
            id,
            name$suffix,
            instructions$suffix,
            muscle_group_fr,
            muscle_group_en,
            equipment,
            description,
            difficulty_level,
            video_url,
            image_url,
            tags,
            community_rating,
            rating_count,
            is_verified
          ''')
          .eq('id', exerciseId)
          .maybeSingle();
      
      if (result != null) {
        // Ajouter des informations de localisation pour le client
        result['localized_name'] = getLocalizedText(result, 'name');
        result['localized_instructions'] = getLocalizedText(result, 'instructions');
        result['current_language'] = locService.currentLanguageCode;
      }
      
      return result;
      
    } catch (e) {
      print('Erreur lors de la récupération des détails de l\'exercice: $e');
      return null;
    }
  }
}