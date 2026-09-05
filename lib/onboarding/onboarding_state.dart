import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../components/ui/onboarding_models.dart';

/// Everything the onboarding collects. Values are stored the way the app
/// stores them today: metric units, `Homme` / `Femme`, activity keys
/// `low` / `light` / `moderate` / `high`, goal keys `lose` / `gain` / `maintain`.
class OnbAnswers {
  String? goal;
  String? gender;
  int age = 26;
  int heightCm = 178;
  int weightKg = 82;
  int targetKg = 74;
  bool isMetric = true;
  String? activity;
  List<String> restrictions = [];
  String? motivation;
  String motivationText = '';
  List<String> obstacles = [];
  String? personality;
  int? bilanDay; // 1 = Monday … 7 = Sunday, like `weekly_bilan_day`
  String plan = 'annual';

  bool get hasTarget => goal != null && goal != 'maintain';

  Map<String, dynamic> toJson() => {
        'goal': goal,
        'gender': gender,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'targetKg': targetKg,
        'isMetric': isMetric,
        'activity': activity,
        'restrictions': restrictions,
        'motivation': motivation,
        'motivationText': motivationText,
        'obstacles': obstacles,
        'personality': personality,
        'bilanDay': bilanDay,
        'plan': plan,
      };

  static OnbAnswers fromJson(Map<String, dynamic> j) {
    final a = OnbAnswers();
    a.goal = j['goal'] as String?;
    a.gender = j['gender'] as String?;
    a.age = (j['age'] as num?)?.toInt() ?? a.age;
    a.heightCm = (j['heightCm'] as num?)?.toInt() ?? a.heightCm;
    a.weightKg = (j['weightKg'] as num?)?.toInt() ?? a.weightKg;
    a.targetKg = (j['targetKg'] as num?)?.toInt() ?? a.targetKg;
    a.isMetric = j['isMetric'] as bool? ?? true;
    a.activity = j['activity'] as String?;
    a.restrictions = List<String>.from(j['restrictions'] as List? ?? const []);
    a.motivation = j['motivation'] as String?;
    a.motivationText = j['motivationText'] as String? ?? '';
    a.obstacles = List<String>.from(j['obstacles'] as List? ?? const []);
    a.personality = j['personality'] as String?;
    a.bilanDay = (j['bilanDay'] as num?)?.toInt();
    a.plan = j['plan'] as String? ?? 'annual';
    return a;
  }

  /// Same map shape the legacy questionnaire fed to `UserProfile.fromMap`.
  UserProfile toProfile() => UserProfile.fromMap({
        'gender': gender ?? '',
        'age': age.toString(),
        'weight': weightKg.toString(),
        'height': heightCm.toString(),
        'activity': activity ?? '',
        'goal': goal ?? '',
        'targetWeight': hasTarget ? targetKg.toString() : null,
        'obstacles': obstacles,
        'restrictions': restrictions,
      });
}

/// Metabolic numbers, computed with the app's own `MetabolicCalculations`
/// so the onboarding shows exactly what the dashboard will show.
class OnbMetabolics {
  OnbMetabolics._();

  static double bmr(OnbAnswers a) => MetabolicCalculations.calculateBMR(a.toProfile());
  static int dailyCalories(OnbAnswers a) => MetabolicCalculations.calculateDailyGoal(a.toProfile());
  static Map<String, int> macros(OnbAnswers a) => MetabolicCalculations.calculateMacros(a.toProfile());

  static int sessionsPerWeek(OnbAnswers a) {
    switch (a.activity) {
      case 'low':
        return 2;
      case 'moderate':
        return 4;
      case 'high':
        return 5;
      default:
        return 3;
    }
  }

  /// Healthy-pace projection to the target weight. Null when maintaining.
  static OnbProjection? projection(OnbAnswers a, String lang) {
    if (!a.hasTarget) return null;
    final delta = a.targetKg - a.weightKg;
    if (delta == 0) return null;
    final rate = a.goal == 'lose' ? 0.6 : 0.3;
    final weeks = (delta.abs() / rate).ceil().clamp(2, 200);
    final date = DateTime.now().add(Duration(days: weeks * 7));
    return OnbProjection(deltaKg: delta, weeks: weeks, date: date, label: shortDate(date, lang), ratePerWeekKg: delta.abs() / weeks);
  }

  /// "12 nov." / "Nov 12" / "12. Nov." without touching intl's locale data,
  /// which the app only initializes in the coach chat.
  static String shortDate(DateTime d, String lang) {
    const fr = ['janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin', 'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.'];
    const en = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const de = ['Jan.', 'Feb.', 'März', 'Apr.', 'Mai', 'Juni', 'Juli', 'Aug.', 'Sept.', 'Okt.', 'Nov.', 'Dez.'];
    switch (lang) {
      case 'fr':
        return '${d.day} ${fr[d.month - 1]}';
      case 'de':
        return '${d.day}. ${de[d.month - 1]}';
      default:
        return '${en[d.month - 1]} ${d.day}';
    }
  }
}

class OnbProjection {
  const OnbProjection({required this.deltaKg, required this.weeks, required this.date, required this.label, required this.ratePerWeekKg});
  final int deltaKg;
  final int weeks;
  final DateTime date;
  final String label;
  final double ratePerWeekKg;
}

/// Unit helpers. Storage is always metric; only the display converts.
class OnbUnits {
  OnbUnits._();

  static int cmToIn(int cm) => (cm / 2.54).round();
  static int inToCm(int inches) => (inches * 2.54).round();
  static int kgToLb(int kg) => (kg * 2.20462).round();
  static int lbToKg(int lb) => (lb / 2.20462).round();

  static String height(int cm, bool metric) {
    if (metric) return '$cm cm';
    final inches = cmToIn(cm);
    return '${inches ~/ 12} ft ${inches % 12} in';
  }

  static String weight(int kg, bool metric) => metric ? '$kg kg' : '${kgToLb(kg)} lb';
}

/// Local progress so a user who closes the app comes back where they were,
/// including straight to the paywall once the profile is saved.
class OnbProgressStore {
  OnbProgressStore._();

  static const String _key = 'onb_v2_progress';
  static const String profileSavedKey = 'onb_v2_profile_saved';

  static Future<void> save(String stepId, OnbAnswers answers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode({'step': stepId, 'answers': answers.toJson()}));
  }

  static Future<({String step, OnbAnswers answers})?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return null;
    try {
      final j = jsonDecode(raw) as Map<String, dynamic>;
      return (step: j['step'] as String, answers: OnbAnswers.fromJson(j['answers'] as Map<String, dynamic>));
    } catch (_) {
      return null;
    }
  }

  static Future<void> markProfileSaved() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(profileSavedKey, true);
  }

  static Future<bool> isProfileSaved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(profileSavedKey) ?? false;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
    await prefs.remove(profileSavedKey);
  }
}
