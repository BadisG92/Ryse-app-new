import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../components/ui/onboarding_models.dart';
import '../models/weekly_planner_models.dart';
import '../services/coach_personality_service.dart';
import '../services/localization_service.dart';
import '../services/planner_ai_service.dart';
import '../services/unit_service.dart';
import '../services/weekly_bilan_service.dart';
import 'onboarding_state.dart';
import 'onboarding_strings.dart';

/// Persists the onboarding exactly like the legacy flow did:
/// same tables, same columns, same local preferences.
class OnboardingRepository {
  OnboardingRepository({SupabaseClient? client}) : _supabase = client ?? Supabase.instance.client;

  final SupabaseClient _supabase;

  /// Port of `OnboardingGamifiedHybrid._saveUserData`.
  /// Writes `users`, `user_profile_history`, the daily macro prefs,
  /// `onboarding_completed`, the measurement unit and `UnitService`.
  Future<void> saveProfile(OnbAnswers a) async {
    final prefs = await SharedPreferences.getInstance();
    final profile = a.toProfile();

    final calories = MetabolicCalculations.calculateDailyGoal(profile);
    final macros = MetabolicCalculations.calculateMacros(profile);
    final bmr = MetabolicCalculations.calculateBMR(profile);

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('Utilisateur non connecté - impossible de sauvegarder');
      }

      // Legacy flow derived the birth date from the age: 1st of January.
      final birthYear = DateTime.now().year - a.age;
      final birthDate = '$birthYear-01-01';

      // Storage is always metric (kg, cm); the ruler already converts.
      final double heightValue = a.heightCm.toDouble();
      final double weightValue = a.weightKg;
      final double targetWeightValue = a.hasTarget ? a.targetKg : a.weightKg;
      final now = DateTime.now().toIso8601String();

      final updateData = {
        // asked in chapter 1 when the account did not bring one
        if ((a.firstName ?? '').trim().isNotEmpty) 'first_name': a.firstName!.trim(),
        'gender': a.gender,
        'birth_date': birthDate,
        'age': a.age,
        'height': heightValue,
        'weight': weightValue,
        'target_weight': targetWeightValue,
        'is_metric': a.isMetric,
        'activity_level': a.activity,
        'fitness_goal': a.goal,
        'dietary_restrictions': a.restrictions,
        'daily_calories': calories,
        'daily_protein': macros['protein'],
        'daily_carbs': macros['carbs'],
        'daily_fat': macros['fat'],
        'bmr': bmr,
        'updated_at': now,
      };

      await _supabase.from('users').update(updateData).eq('id', userId).select();

      if (weightValue > 0) {
        final historyData = {
          'gender': a.gender,
          'birth_date': birthDate,
          'age': a.age,
          'height': heightValue,
          'weight': weightValue,
          'activity_level': a.activity,
          'fitness_goal': a.goal,
          'dietary_restrictions': a.restrictions,
          'daily_calories': calories,
          'daily_protein': macros['protein'],
          'daily_carbs': macros['carbs'],
          'daily_fat': macros['fat'],
          'bmr': bmr,
          'valid_from': now,
          'change_source': 'onboarding_completion',
          'weight_modified': true,
        };

        final existingProfile = await _supabase.from('user_profile_history').select('id').eq('user_id', userId).eq('is_current', true).maybeSingle();

        if (existingProfile != null) {
          await _supabase.from('user_profile_history').update(historyData).eq('id', existingProfile['id']).select();
        } else {
          await _supabase.from('user_profile_history').insert({
            'user_id': userId,
            ...historyData,
            'is_current': true,
          }).select();
        }
      }

      await _saveLocalMacros(prefs, calories, macros);
      await prefs.setString('measurement_unit', a.isMetric ? 'Métrique' : 'Impérial');
      await UnitService.instance.setImperial(!a.isMetric);
      await OnbProgressStore.markProfileSaved();
    } catch (e) {
      debugPrint('❌ Onboarding saveProfile: $e');
      try {
        await _saveLocalMacros(prefs, calories, macros);
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _saveLocalMacros(SharedPreferences prefs, int calories, Map<String, int> macros) async {
    await prefs.setInt('daily_calories', calories);
    await prefs.setInt('daily_protein', macros['protein'] ?? 0);
    await prefs.setInt('daily_carbs', macros['carbs'] ?? 0);
    await prefs.setInt('daily_fat', macros['fat'] ?? 0);
    await prefs.setBool('onboarding_completed', true);
  }

  /// Port of `WeeklyContractScreen._saveAndComplete`.
  Future<void> saveBilanDay(int day) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('users').update({
          'weekly_bilan_day': day,
          'weekly_bilan_enabled': true,
        }).eq('id', user.id);
        await WeeklyBilanService.instance.setBilanDay(day);
      }
    } catch (e) {
      debugPrint('❌ Onboarding saveBilanDay: $e');
    }
  }

  Future<void> savePersonality(String key) async {
    try {
      final type = CoachPersonalityType.values.firstWhere((t) => t.name == key, orElse: () => CoachPersonalityType.friendly);
      await CoachPersonalityService.instance.setPersonality(type);
    } catch (e) {
      debugPrint('❌ Onboarding savePersonality: $e');
    }
  }

  /// Port of `OnboardingChatScreen._extractAndSaveInsights`, without the
  /// Gemini round trip: the answers are already structured, so the summary is
  /// written in the same categories the coach memory expects.
  Future<void> saveCoachInsights(OnbAnswers a, OnbStrings s) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      final lines = <String>[];
      final goalLabel = a.goal == null ? null : s.t('goal_${a.goal}');
      if (a.motivation != null) {
        lines.add('- **${s.t('insight_motivation')}**: ${s.t(a.motivation!)}${a.motivationText.trim().isNotEmpty ? ' ("${a.motivationText.trim()}")' : ''}');
      }
      if (goalLabel != null) {
        final target = a.hasTarget ? ' (${OnbUnits.fmtKg(a.weightKg)} kg → ${OnbUnits.fmtKg(a.targetKg)} kg)' : '';
        lines.add('- **${s.t('insight_goal')}**: $goalLabel$target');
      }
      if (a.obstacles.isNotEmpty && !(a.obstacles.length == 1 && a.obstacles.first == 'obs_none')) {
        lines.add('- **${s.t('insight_blockers')}**: ${a.obstacles.where((o) => o != 'obs_none').map((o) => s.t(o)).join(', ')}');
      }
      if (a.restrictions.isNotEmpty) {
        lines.add('- **${s.t('insight_constraints')}**: ${a.restrictions.join(', ')}');
      }
      if (a.personality != null) {
        lines.add(
            '- **${s.t('insight_tone')}**: ${CoachPersonalityService.getLocalizedLabel(CoachPersonalityType.values.firstWhere((t) => t.name == a.personality, orElse: () => CoachPersonalityType.friendly), s.lang)}');
      }
      if (lines.isEmpty) return;
      final insights = lines.join('\n');

      final existingResponse = await _supabase.from('user_coach_preferences').select('preferences').eq('user_id', user.id).maybeSingle();

      Map<String, dynamic> existingPrefs = {};
      if (existingResponse != null && existingResponse['preferences'] != null) {
        existingPrefs = Map<String, dynamic>.from(existingResponse['preferences'] as Map);
      }
      existingPrefs['onboarding_insights'] = insights;

      await _supabase.from('user_coach_preferences').upsert(
        {
          'user_id': user.id,
          'preferences': existingPrefs,
          'last_extraction_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id',
      );
    } catch (e) {
      debugPrint('❌ Onboarding saveCoachInsights: $e');
    }
  }

  static const String _pendingSyncKey = 'onb_pending_completion_sync';

  /// Port of `RyzeApp._completeOnboarding` (the persistence part).
  /// Returns false when the server could not be updated: the local flags are
  /// set anyway (the user has paid) and [retryPendingCompletion] replays it.
  Future<bool> markCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_intro', true);
    await prefs.setBool('is_onboarded', true);
    final synced = await _pushCompleted();
    await prefs.setBool(_pendingSyncKey, !synced);
    if (synced) await OnbProgressStore.clear();
    return synced;
  }

  Future<bool> _pushCompleted() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;
    try {
      await _supabase.from('users').update({
        'is_onboarded': true,
        'ai_onboarding_completed': true,
      }).eq('id', user.id);
      await LocalizationService.instance.syncLanguageToSupabase();
      return true;
    } catch (e) {
      debugPrint('❌ Onboarding markCompleted: $e');
      return false;
    }
  }

  /// Called at launch: replays a completion the server missed (offline right
  /// after the purchase). Returns true while the server is still behind.
  Future<bool> retryPendingCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_pendingSyncKey) ?? false)) return false;
    final synced = await _pushCompleted();
    if (synced) {
      await prefs.setBool(_pendingSyncKey, false);
      await OnbProgressStore.clear();
    }
    return !synced;
  }

  /// Port of `OnboardingPlannerDemo` post-purchase save. False as soon as one
  /// item was refused (the service reports failures in `success`, it does not throw).
  Future<bool> saveDemoPlan(List<PendingMeal> meals, List<PendingWorkout> workouts, List<PendingSession> sessions) async {
    var ok = true;
    // The plan is now written before the purchase, so the user keeps their week
    // if they leave the paywall. Demo mode must stay on while it is written:
    // the onboarding demo is not one of the five free planner uses.
    PlannerAIService.setDemoMode(true);
    try {
      for (final meal in meals) {
        ok = (await PlannerAIService.confirmMeals([meal])).success && ok;
      }
      if (workouts.isNotEmpty) {
        ok = (await PlannerAIService.confirmWorkouts(workouts)).success && ok;
      }
      for (final session in sessions) {
        ok = (await PlannerAIService.confirmSingleSession(session)).success && ok;
      }
      return ok;
    } catch (e) {
      debugPrint('⚠️ Onboarding saveDemoPlan: $e');
      return false;
    } finally {
      PlannerAIService.setDemoMode(false);
    }
  }
}
