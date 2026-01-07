import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'global_state_manager.dart';
import 'subscription_service.dart';
import 'coach_personality_service.dart';

/// Service for managing weekly bilan (check-in) feature
/// Premium only - provides weekly conversational check-in with Coach Ryze
class WeeklyBilanService {
  static final WeeklyBilanService _instance = WeeklyBilanService._internal();
  static WeeklyBilanService get instance => _instance;

  WeeklyBilanService._internal();

  final _supabase = Supabase.instance.client;

  // ===========================================
  // 🧪 TEST MODE - Set to true to force show banner
  // ===========================================
  static const bool kTestMode = true; // TEMP: Set to false for production
  // ===========================================

  // Cache for bilan status
  bool? _cachedIsBilanDay;
  bool? _cachedIsBilanDone;
  DateTime? _lastCheck;

  // Session-level flag: true if bilan was started this session
  bool _bilanStartedThisSession = false;

  /// Check if user has weekly bilan enabled
  Future<bool> isWeeklyBilanEnabled() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      final response = await _supabase
          .from('users')
          .select('weekly_bilan_enabled')
          .eq('id', user.id)
          .maybeSingle();

      return response?['weekly_bilan_enabled'] == true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error checking enabled: $e');
      return false;
    }
  }

  /// Get the user's chosen bilan day (1=Monday, 7=Sunday)
  Future<int?> getBilanDay() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('users')
          .select('weekly_bilan_day')
          .eq('id', user.id)
          .maybeSingle();

      return response?['weekly_bilan_day'] as int?;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error getting bilan day: $e');
      return null;
    }
  }

  /// Get the user's chosen bilan hour (default: 19)
  Future<int> getBilanHour() async {
    if (_cachedBilanHour != null) return _cachedBilanHour!;

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return kDefaultBilanHour;

      final response = await _supabase
          .from('users')
          .select('weekly_bilan_hour')
          .eq('id', user.id)
          .maybeSingle();

      _cachedBilanHour = (response?['weekly_bilan_hour'] as int?) ?? kDefaultBilanHour;
      return _cachedBilanHour!;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error getting bilan hour: $e');
      return kDefaultBilanHour;
    }
  }

  /// Update bilan day
  Future<bool> setBilanDay(int day) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('users').update({
        'weekly_bilan_day': day,
        'weekly_bilan_enabled': true,
      }).eq('id', user.id);

      // Clear cache
      _cachedIsBilanDay = null;
      _lastCheck = null;

      if (kDebugMode) debugPrint('✅ Bilan day updated to $day');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error setting bilan day: $e');
      return false;
    }
  }

  /// Update bilan hour
  Future<bool> setBilanHour(int hour) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('users').update({
        'weekly_bilan_hour': hour,
      }).eq('id', user.id);

      // Clear cache
      _cachedBilanHour = hour;
      _cachedIsBilanDay = null;
      _lastCheck = null;

      if (kDebugMode) debugPrint('✅ Bilan hour updated to $hour');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error setting bilan hour: $e');
      return false;
    }
  }

  /// Disable weekly bilan
  Future<bool> disableBilan() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return false;

      await _supabase.from('users').update({
        'weekly_bilan_enabled': false,
      }).eq('id', user.id);

      // Clear cache
      _cachedIsBilanDay = null;
      _lastCheck = null;

      if (kDebugMode) debugPrint('✅ Bilan disabled');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error disabling bilan: $e');
      return false;
    }
  }

  // Default hour when bilan becomes available (19h = 7PM)
  static const int kDefaultBilanHour = 19;

  // Cached bilan hour (loaded from DB)
  int? _cachedBilanHour;

  /// Check if today is the user's bilan day AND it's after the configured hour
  Future<bool> isBilanDay() async {
    // Use cache if checked recently (within 5 minutes)
    if (_cachedIsBilanDay != null && _lastCheck != null) {
      final diff = DateTime.now().difference(_lastCheck!);
      if (diff.inMinutes < 5) {
        return _cachedIsBilanDay!;
      }
    }

    try {
      // Must be premium
      if (!SubscriptionService.instance.isPremium) {
        _cachedIsBilanDay = false;
        _lastCheck = DateTime.now();
        return false;
      }

      final bilanDay = await getBilanDay();
      if (bilanDay == null) {
        _cachedIsBilanDay = false;
        _lastCheck = DateTime.now();
        return false;
      }

      final bilanHour = await getBilanHour();
      final now = DateTime.now();

      // Check if today matches AND it's after the configured hour
      final isCorrectDay = now.weekday == bilanDay;
      final isAfterBilanHour = now.hour >= bilanHour;

      _cachedIsBilanDay = isCorrectDay && isAfterBilanHour;
      _lastCheck = DateTime.now();

      if (kDebugMode && isCorrectDay && !isAfterBilanHour) {
        debugPrint('📅 WeeklyBilanService: Bilan day but waiting for ${bilanHour}h (current: ${now.hour}h)');
      }

      return _cachedIsBilanDay!;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error checking bilan day: $e');
      return false;
    }
  }

  /// Check if the bilan is already done for this week
  Future<bool> isBilanDoneThisWeek() async {
    // Use cache if checked recently (within 5 minutes)
    if (_cachedIsBilanDone != null && _lastCheck != null) {
      final diff = DateTime.now().difference(_lastCheck!);
      if (diff.inMinutes < 5) {
        return _cachedIsBilanDone!;
      }
    }

    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return true; // No user = consider done

      final response = await _supabase
          .from('users')
          .select('last_bilan_week')
          .eq('id', user.id)
          .maybeSingle();

      final lastBilanWeek = response?['last_bilan_week'] as String?;
      if (lastBilanWeek == null) {
        _cachedIsBilanDone = false;
        return false;
      }

      // Get Monday of current week
      final now = DateTime.now();
      final currentMonday = now.subtract(Duration(days: now.weekday - 1));
      final currentMondayStr = DateFormat('yyyy-MM-dd').format(currentMonday);

      // Compare
      _cachedIsBilanDone = lastBilanWeek == currentMondayStr;
      return _cachedIsBilanDone!;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error checking bilan done: $e');
      return true; // Assume done on error
    }
  }

  /// Mark that bilan was started this session (hides banner/badge)
  void markBilanStarted() {
    _bilanStartedThisSession = true;
    if (kDebugMode) debugPrint('✅ Bilan marked as started this session');
  }

  /// Mark the bilan as done for this week
  Future<void> markBilanDone() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;

      // Get Monday of current week
      final now = DateTime.now();
      final currentMonday = now.subtract(Duration(days: now.weekday - 1));
      final currentMondayStr = DateFormat('yyyy-MM-dd').format(currentMonday);

      await _supabase.from('users').update({
        'last_bilan_week': currentMondayStr,
      }).eq('id', user.id);

      // Update cache
      _cachedIsBilanDone = true;

      if (kDebugMode) debugPrint('✅ Bilan marked as done for week $currentMondayStr');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error marking bilan done: $e');
    }
  }

  /// Check if bilan banner should be shown
  /// Returns true if: premium + bilan day + not done this week + bilan enabled
  Future<bool> shouldShowBilanBanner() async {
    // If bilan was already started this session, don't show banner
    if (_bilanStartedThisSession) {
      return false;
    }

    // 🧪 TEST MODE: Always show banner for testing (if not started this session)
    if (kTestMode) {
      if (kDebugMode) debugPrint('🧪 WeeklyBilanService: TEST MODE - Forcing banner display');
      return true;
    }

    if (!SubscriptionService.instance.isPremium) return false;

    final enabled = await isWeeklyBilanEnabled();
    if (!enabled) return false;

    final isDay = await isBilanDay();
    if (!isDay) return false;

    final isDone = await isBilanDoneThisWeek();
    return !isDone;
  }

  /// Get weekly stats for bilan context
  Future<WeeklyStats> getWeeklyStats() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return WeeklyStats.empty();

      // Get week boundaries (Monday to Sunday)
      final now = DateTime.now();
      final monday = now.subtract(Duration(days: now.weekday - 1));
      final startOfWeek = DateTime(monday.year, monday.month, monday.day);
      final endOfWeek = startOfWeek.add(const Duration(days: 7));

      // Get food entries for the week
      final foodResponse = await _supabase
          .from('food_entries')
          .select('calories, proteins, carbs, fats, consumed_at')
          .eq('user_id', user.id)
          .gte('consumed_at', startOfWeek.toIso8601String())
          .lt('consumed_at', endOfWeek.toIso8601String());

      // Calculate daily calories
      final dailyCalories = <int, int>{}; // weekday -> calories
      for (var entry in foodResponse) {
        final date = DateTime.parse(entry['consumed_at'] as String);
        final calories = (entry['calories'] as num?)?.toInt() ?? 0;
        dailyCalories[date.weekday] = (dailyCalories[date.weekday] ?? 0) + calories;
      }

      // Get calorie goal
      final globalState = GlobalStateManager.instance;
      final calorieGoal = globalState.calorieGoal.toInt();

      // Count days on target (within 10% of goal)
      int daysOnTarget = 0;
      for (var calories in dailyCalories.values) {
        final diff = (calories - calorieGoal).abs();
        if (diff <= calorieGoal * 0.1) {
          daysOnTarget++;
        }
      }

      // Calculate average calories
      final totalCalories = dailyCalories.values.fold<int>(0, (sum, c) => sum + c);
      final daysWithData = dailyCalories.length;
      final avgCalories = daysWithData > 0 ? totalCalories ~/ daysWithData : 0;

      // Get workout sessions for the week
      final workoutResponse = await _supabase
          .from('workout_session_summaries')
          .select('id')
          .eq('user_id', user.id)
          .gte('session_date', DateFormat('yyyy-MM-dd').format(startOfWeek))
          .lt('session_date', DateFormat('yyyy-MM-dd').format(endOfWeek));

      // Get cardio sessions for the week
      final cardioResponse = await _supabase
          .from('cardio_sessions')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_completed', true)
          .gte('start_time', startOfWeek.toIso8601String())
          .lt('start_time', endOfWeek.toIso8601String());

      final sportDays = (workoutResponse as List).length + (cardioResponse as List).length;

      // Get weight change (if any weight entries this week vs last week)
      double? weightChange;
      try {
        final currentWeightResponse = await _supabase
            .from('weight_entries')
            .select('weight')
            .eq('user_id', user.id)
            .gte('entry_date', DateFormat('yyyy-MM-dd').format(startOfWeek))
            .order('entry_date', ascending: false)
            .limit(1)
            .maybeSingle();

        final lastWeekStart = startOfWeek.subtract(const Duration(days: 7));
        final previousWeightResponse = await _supabase
            .from('weight_entries')
            .select('weight')
            .eq('user_id', user.id)
            .lt('entry_date', DateFormat('yyyy-MM-dd').format(startOfWeek))
            .gte('entry_date', DateFormat('yyyy-MM-dd').format(lastWeekStart))
            .order('entry_date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (currentWeightResponse != null && previousWeightResponse != null) {
          final current = (currentWeightResponse['weight'] as num).toDouble();
          final previous = (previousWeightResponse['weight'] as num).toDouble();
          weightChange = current - previous;
        }
      } catch (e) {
        // Ignore weight errors
      }

      return WeeklyStats(
        avgCalories: avgCalories,
        calorieGoal: calorieGoal,
        daysOnTarget: daysOnTarget,
        daysTracked: daysWithData,
        sportDays: sportDays,
        streak: globalState.currentStreak,
        weightChange: weightChange,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ WeeklyBilanService: Error getting stats: $e');
      return WeeklyStats.empty();
    }
  }

  /// Build the bilan first message from Coach Ryze
  Future<String> buildBilanFirstMessage(String lang) async {
    final stats = await getWeeklyStats();
    final globalState = GlobalStateManager.instance;
    final userName = globalState.userName.isNotEmpty ? globalState.userName : 'Champion';

    final isFr = lang == 'fr';

    // Use real stats or test data
    final avgCalories = stats.avgCalories > 0 ? stats.avgCalories : (kTestMode ? 1850 : 0);
    final sportDays = stats.sportDays > 0 ? stats.sportDays : (kTestMode ? 3 : 0);

    // Get personality-based opener
    final opener = await CoachPersonalityService.instance.getBilanOpener(lang, userName);

    // Build stats summary
    final statsSummary = isFr
        ? 'Cette semaine, t\'as mangé en moyenne $avgCalories kcal/jour${sportDays > 0 ? ' et fait $sportDays séance${sportDays > 1 ? 's' : ''} de sport' : ''}.'
        : 'This week, you averaged $avgCalories kcal/day${sportDays > 0 ? ' and did $sportDays workout session${sportDays > 1 ? 's' : ''}' : ''}.';

    // Get personality-based closing question
    final closingQuestion = await _getBilanClosingQuestion(lang);

    return '''$opener

$statsSummary

$closingQuestion''';
  }

  /// Get closing question based on personality
  Future<String> _getBilanClosingQuestion(String lang) async {
    final personality = await CoachPersonalityService.instance.getPersonality();
    final isFr = lang == 'fr';

    switch (personality.type) {
      case CoachPersonalityType.friendly:
        return isFr
            ? 'Alors, comment tu te sens ? C\'était une bonne semaine ou plutôt galère ?'
            : 'So, how are you feeling? Was it a good week or more of a struggle?';

      case CoachPersonalityType.strict:
        return isFr
            ? 'Es-tu satisfait de ces résultats ? Qu\'est-ce qui peut être amélioré ?'
            : 'Are you satisfied with these results? What can be improved?';

      case CoachPersonalityType.supportive:
        return isFr
            ? 'Comment te sens-tu par rapport à cette semaine ? Je suis là pour t\'écouter.'
            : 'How do you feel about this week? I\'m here to listen.';

      case CoachPersonalityType.sassy:
        return isFr
            ? 'Alors, t\'as des excuses ou t\'assumes ? 😏'
            : 'So, any excuses or are you owning it? 😏';

      case CoachPersonalityType.direct:
        return isFr
            ? 'Objectifs atteints ?'
            : 'Goals met?';

      case CoachPersonalityType.custom:
        return isFr
            ? 'Comment s\'est passée ta semaine ?'
            : 'How was your week?';
    }
  }

  /// Clear cache (call on logout or when settings change)
  void clearCache() {
    _cachedIsBilanDay = null;
    _cachedIsBilanDone = null;
    _cachedBilanHour = null;
    _lastCheck = null;
    _bilanStartedThisSession = false;
  }
}

/// Weekly stats for bilan context
class WeeklyStats {
  final int avgCalories;
  final int calorieGoal;
  final int daysOnTarget;
  final int daysTracked;
  final int sportDays;
  final int streak;
  final double? weightChange;

  WeeklyStats({
    required this.avgCalories,
    required this.calorieGoal,
    required this.daysOnTarget,
    required this.daysTracked,
    required this.sportDays,
    required this.streak,
    this.weightChange,
  });

  factory WeeklyStats.empty() => WeeklyStats(
        avgCalories: 0,
        calorieGoal: 2000,
        daysOnTarget: 0,
        daysTracked: 0,
        sportDays: 0,
        streak: 0,
      );

  /// Format for AI context
  String toPromptString() {
    final buffer = StringBuffer();
    buffer.writeln('- Calories moyennes: $avgCalories/$calorieGoal kcal');
    buffer.writeln('- Jours où l\'objectif a été atteint: $daysOnTarget/$daysTracked');
    buffer.writeln('- Jours de sport: $sportDays/7');
    buffer.writeln('- Streak actuel: $streak jours');
    if (weightChange != null) {
      final sign = weightChange! >= 0 ? '+' : '';
      buffer.writeln('- Évolution poids: $sign${weightChange!.toStringAsFixed(1)} kg');
    }
    return buffer.toString();
  }
}
