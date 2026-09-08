import 'package:flutter/foundation.dart';

import '../services/coach_context_builder.dart';
import '../services/weight_service.dart';
import 'prompts/persona_strings.dart';
import 'ryze_context.dart';
import 'ryze_memory.dart';

/// D'où viennent les blocs de contexte.
///
/// Les récupérateurs de `CoachContextBuilder` marchent et ont été vérifiés ;
/// ce qui manquait, c'était la structure autour. Ils sont donc réutilisés tels
/// quels et branchés ici sur les blocs bornés, mis en cache et rendus dans la
/// langue de l'utilisateur.
///
/// Ils appartiendront à `lib/ai/` quand le planificateur rejoindra le même
/// moteur ; les déplacer maintenant ferait bouger deux choses à la fois.
class RyzeContextSource {
  RyzeContextSource._();

  static final RyzeContextSource instance = RyzeContextSource._();

  /// La photo brute, prise une fois et partagée par tous les blocs.
  ///
  /// L'ancien code refaisait ses huit requêtes à chaque reconstruction du
  /// prompt, c'est-à-dire à chaque ouverture et à chaque changement de ton.
  Future<Map<String, dynamic>>? _snapshot;
  DateTime? _snapshotAt;

  Future<Map<String, dynamic>> _userContext() {
    final frais = _snapshotAt != null &&
        DateTime.now().difference(_snapshotAt!) < RyzeContext.ttl;
    if (_snapshot != null && frais) return _snapshot!;

    _snapshotAt = DateTime.now();
    _snapshot = CoachContextBuilder.instance.buildUserContext();
    return _snapshot!;
  }

  void invalidate() {
    _snapshot = null;
    _snapshotAt = null;
    RyzeContext.instance.clear();
  }

  /// Le contexte complet, assemblé et prêt à être collé sous la persona.
  Future<String> build(PersonaStrings s) async {
    final ctx = RyzeContext.instance;

    final blocs = <RyzeBlock, String>{
      RyzeBlock.today: await ctx.block(RyzeBlock.today, () => _today(s)),
      RyzeBlock.meals: await ctx.block(RyzeBlock.meals, () => _meals(s)),
      RyzeBlock.profile: await ctx.block(RyzeBlock.profile, () => _profile(s)),
      RyzeBlock.weekPlan: await ctx.block(RyzeBlock.weekPlan, () => _week(s)),
      RyzeBlock.history14d: await ctx.block(RyzeBlock.history14d, () => _history(s)),
      RyzeBlock.recentSessions: await ctx.block(RyzeBlock.recentSessions, () => _sessions(s)),
      RyzeBlock.weightTrend: await ctx.block(RyzeBlock.weightTrend, () => _weight(s)),
      RyzeBlock.memory: await ctx.block(RyzeBlock.memory, () => _memory(s)),
    };

    return RyzeContext.assemble(blocs);
  }

  // ------------------------------------------------------------- les blocs

  int _int(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num) return v.round();
    return 0;
  }

  double _double(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v is num) return v.toDouble();
    return 0;
  }

  Future<String> _today(PersonaStrings s) async {
    final c = await _userContext();
    return RyzeContext.renderToday(
      s,
      calorieGoal: _int(c, 'calorieGoal'),
      caloriesEaten: _int(c, 'caloriesEaten'),
      proteins: _int(c, 'proteinsEaten'),
      proteinsGoal: _int(c, 'proteinsGoal'),
      carbs: _int(c, 'carbsEaten'),
      carbsGoal: _int(c, 'carbsGoal'),
      fats: _int(c, 'fatsEaten'),
      fatsGoal: _int(c, 'fatsGoal'),
      waterL: _double(c, 'waterDrunk'),
      waterGoalL: _double(c, 'waterGoal'),
    );
  }

  Future<String> _meals(PersonaStrings s) async {
    final c = await _userContext();
    final brut = '${c['mealsToday'] ?? ''}';
    final lignes = brut
        .split('\n')
        .map((l) => l.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim())
        .where((l) => l.isNotEmpty)
        .toList();
    return RyzeContext.renderMeals(s, lignes);
  }

  Future<String> _profile(PersonaStrings s) async {
    final c = await _userContext();
    return RyzeContext.renderProfile(
      s,
      gender: c['userGender'] as String?,
      age: c['userAge'] as int?,
      fitnessGoal: c['fitnessGoal'] as String?,
      currentWeight: (c['currentWeight'] as num?)?.toDouble(),
      targetWeight: (c['targetWeight'] as num?)?.toDouble(),
      activityLevel: c['activityLevel'] as String?,
      streak: _int(c, 'streak'),
    );
  }

  Future<String> _week(PersonaStrings s) async {
    final c = await _userContext();
    return RyzeContext.section(s, 'section_week', '${c['weeklyPlanning'] ?? ''}');
  }

  Future<String> _history(PersonaStrings s) async {
    final c = await _userContext();
    return RyzeContext.section(s, 'section_history', '${c['mealHistory14Days'] ?? ''}');
  }

  Future<String> _sessions(PersonaStrings s) async {
    final c = await _userContext();
    final lignes = <String>[
      ...'${c['recentWorkouts'] ?? ''}'.split('\n'),
      ...'${c['recentCardio'] ?? ''}'.split('\n'),
    ].map((l) => l.replaceFirst(RegExp(r'^[-•*]\s*'), '').trim()).where((l) => l.isNotEmpty).toList();
    return RyzeContext.renderSessions(s, lignes);
  }

  /// La tendance du poids, que le prompt ne portait pas.
  ///
  /// Le coach ne voyait que le poids du jour et la cible : il ne pouvait pas
  /// dire si ça montait ou si ça descendait.
  Future<String> _weight(PersonaStrings s) async {
    try {
      final p = await WeightService.getWeightProgress();
      if (p.currentWeight <= 0) return '';

      // La photo d'il y a quatre semaines, ou la première pesée connue.
      final limite = DateTime.now().subtract(const Duration(days: 28));
      final anciennes = p.entries.where((e) => e.date.isBefore(limite)).toList();
      final reference = anciennes.isNotEmpty
          ? anciennes.last.weight
          : (p.entries.isNotEmpty ? p.entries.first.weight : p.currentWeight);

      return RyzeContext.renderWeightTrend(
        s,
        current: p.currentWeight,
        fourWeeksAgo: reference,
        target: p.targetWeight > 0 ? p.targetWeight : null,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ RyzeContextSource: poids indisponible : $e');
      return '';
    }
  }

  Future<String> _memory(PersonaStrings s) async {
    final prefs = await RyzeMemory.instance.load();
    return RyzeContext.renderMemory(s, RyzeMemory.promptLines(prefs, s));
  }
}
