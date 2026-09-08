import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../design/design.dart';
import '../models/nutrition_analysis.dart';
import '../services/coach_ryze_nutrition_service.dart';
import '../services/food_entries_service.dart';
import '../services/global_state_manager.dart';
import '../services/localization_service.dart';
import '../services/paywall_service.dart';
import '../services/translations.dart';
import '../sport/sport_data.dart';

/// Le bilan de la journée par Coach Ryze.
///
/// La fonction existait déjà — service, cache par date, paywall — mais son
/// seul point de montage était l'ancien journal, et elle est tombée avec lui.
/// Elle revient à un seul endroit au lieu de quatre : le coach la propose le
/// soir sur l'accueil, et Nutrition en garde la porte, parce que c'est de
/// nourriture qu'elle parle.
///
/// Un seul contexte est offert, `end_of_day`. Les trois autres que le service
/// sait produire ne valaient pas leur appel : analyser une journée vide donne
/// de la motivation creuse, et « en cours » à 15 h ne peut dire que
/// « continue », sans rien apprendre à personne.
class DayAnalysis {
  DayAnalysis._();

  /// À partir de cette heure, la journée a assez servi pour être lue.
  static const int fromHour = 20;

  /// En dessous, il n'y a rien à analyser : le coach a mieux à dire.
  static const double minimumShare = 0.3;

  /// Jusqu'à cette heure, la journée dont on parle est celle d'hier.
  ///
  /// L'application bascule de jour à minuit, sur l'horloge locale. Passé
  /// minuit, l'état global compte donc les calories d'une journée vieille de
  /// quelques minutes, et la journée qu'on vient de vivre devient muette : son
  /// analyse cesse d'être proposée alors que c'est le moment où elle vaut le
  /// plus. Entre minuit et cinq heures, le sujet reste hier.
  static const int nightUntil = 5;

  /// Vrai entre minuit et cinq heures.
  static bool isNight({DateTime? now}) => (now ?? DateTime.now()).hour < nightUntil;

  /// La journée qui vient de finir.
  static DateTime yesterday({DateTime? now}) {
    final t = now ?? DateTime.now();
    return DateTime(t.year, t.month, t.day).subtract(const Duration(days: 1));
  }

  /// Vrai quand l'analyse a un sens maintenant, pour la journée en cours.
  static bool isOffered({DateTime? now}) {
    final t = now ?? DateTime.now();
    if (t.hour < fromHour) return false;
    final gs = GlobalStateManager.instance;
    final goal = gs.calorieGoal;
    if (goal <= 0) return false;
    return gs.currentCalories / goal >= minimumShare;
  }

  /// Vrai quand ce jour-là a assez servi pour être lu. Sert à la nuit, où les
  /// chiffres du jour ne sont plus ceux de la journée dont on parle : ils sont
  /// relus dans la base plutôt que pris à l'état global.
  static Future<bool> worthReading(DateTime day) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final goal = GlobalStateManager.instance.calorieGoal;
    if (userId == null || goal <= 0) return false;
    try {
      final byDay = await FoodEntriesService.getDailyCalories(userId: userId, from: day, to: day);
      final eaten = byDay['${day.year}-${day.month}-${day.day}'] ?? 0;
      return eaten / goal >= minimumShare;
    } catch (_) {
      return false;
    }
  }

  /// L'analyse déjà produite pour ce jour, s'il y en a une. Sert à choisir
  /// entre « analyser ma journée » et « voir mon analyse ».
  static Future<NutritionAnalysis?> cached({DateTime? date}) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;
    return CoachRyzeNutritionService.getAnalysisForDate(userId: userId, date: date ?? DateTime.now());
  }

  /// Ouvre l'analyse : celle en cache, sinon une nouvelle.
  static Future<void> open(BuildContext context, {DateTime? date}) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final day = date ?? DateTime.now();
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    final existing = await CoachRyzeNutritionService.getAnalysisForDate(userId: userId, date: day);
    if (!context.mounted) return;
    if (existing != null) {
      await _show(context, lang: lang, analysis: existing, onRegenerate: () => _generate(context, userId: userId, day: day, lang: lang));
      return;
    }
    await _generate(context, userId: userId, day: day, lang: lang);
  }

  static Future<void> _generate(BuildContext context, {required String userId, required DateTime day, required String lang}) async {
    final canUse = await PaywallService.instance.canUseFeature(
      context: context,
      paywallContext: PaywallContext.nutritionAnalysis,
    );
    if (!canUse || !context.mounted) return;

    final progress = _showBusy(context, lang);
    try {
      final gs = GlobalStateManager.instance;
      final meals = await FoodEntriesService.getFoodEntriesForDate(userId, day);
      // La séance du jour vient de l'onglet Sport : le coach doit savoir si
      // ces calories ont été gagnées à la salle.
      final sessions = await SportData.onDay(day);
      final burned = sessions.fold<int>(0, (n, s) => n + s.kcal);

      final analysis = await CoachRyzeNutritionService.generateAnalysis(
        userId: userId,
        date: day,
        todayMeals: meals,
        calorieTarget: gs.calorieGoal.round(),
        proteinTarget: gs.proteinGoal.toDouble(),
        carbsTarget: gs.carbsGoal.toDouble(),
        fatsTarget: gs.fatGoal.toDouble(),
        waterIntake: (gs.currentWaterL * 1000).round(),
        hasWorkoutToday: sessions.isNotEmpty,
        workoutType: sessions.isEmpty ? null : sessions.first.name,
        caloriesBurned: burned > 0 ? burned : null,
        workoutTime: sessions.isEmpty ? null : sessions.first.date,
        languageCode: lang,
      );

      progress.remove();
      if (!context.mounted) return;
      RyzeFeedback.success();
      await _show(context, lang: lang, analysis: analysis, onRegenerate: null);
    } catch (_) {
      progress.remove();
      if (context.mounted) RyzeUndo.failed(context, message: 'day_analysis_failed'.tr(lang));
    }
  }

  /// L'écran entier passe à l'encre le temps de la réponse.
  ///
  /// C'était une boîte blanche au centre d'un voile gris : la silhouette
  /// exacte d'un dialogue Material, avec un logo figé dedans. Le moment où
  /// Ryze réfléchit se traite comme le viseur ou la séance en direct — plein
  /// cadre sur l'encre, une seule chose au centre, et elle respire.
  static OverlayEntry _showBusy(BuildContext context, String lang) {
    final entry = OverlayEntry(builder: (_) => _Busy(lang: lang));
    Overlay.of(context, rootOverlay: true).insert(entry);
    return entry;
  }

  static Future<void> _show(
    BuildContext context, {
    required String lang,
    required NutritionAnalysis analysis,
    required VoidCallback? onRegenerate,
  }) {
    return showRyzeSheet<void>(
      context,
      title: 'day_analysis_title'.tr(lang),
      subtitle: 'day_analysis_by'.tr(lang),
      builder: (sheet) => _Body(lang: lang, analysis: analysis),
    );
  }
}

/// Ryze en train de lire la journée : l'encre plein cadre, la marque en
/// ambre au centre, et une onde qui part d'elle toutes les deux secondes.
///
/// L'onde est la seule chose qui bouge. Elle ne prétend pas mesurer une
/// progression — l'appel dure ce qu'il dure, et une barre qui avance sans
/// rien savoir serait un mensonge de plus.
class _Busy extends StatefulWidget {
  const _Busy({required this.lang});

  final String lang;

  @override
  State<_Busy> createState() => _BusyState();
}

class _BusyState extends State<_Busy> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ring = context.vw(34);

    return ColoredBox(
      color: RyzeColors.ink,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: ring,
              height: ring,
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, child) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      if (!still)
                        for (final offset in const [0.0, 0.5])
                          Builder(
                            builder: (context) {
                              final t = (_c.value + offset) % 1;
                              return Opacity(
                                opacity: (1 - t) * 0.30,
                                child: Container(
                                  width: ring * (0.34 + t * 0.66),
                                  height: ring * (0.34 + t * 0.66),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: RyzeColors.acc, width: 1.2),
                                  ),
                                ),
                              );
                            },
                          ),
                      child!,
                    ],
                  );
                },
                child: RyzeMark(size: context.vw(11), color: RyzeColors.acc),
              ),
            ),
            SizedBox(height: context.vw(4.6)),
            Text(
              'day_analysis_running'.tr(widget.lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 3.9, color: RyzeColors.surf.withValues(alpha: 0.78)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.lang, required this.analysis});

  final String lang;
  final NutritionAnalysis analysis;

  /// Le service formate chaque conseil en `**Titre**\ndescription`.
  static (String title, String body) _split(String raw) {
    final match = RegExp(r'^\*\*(.+?)\*\*\s*\n?(.*)$', dotAll: true).firstMatch(raw.trim());
    if (match == null) return ('', raw.trim());
    return (match.group(1)!.trim(), (match.group(2) ?? '').trim());
  }

  @override
  Widget build(BuildContext context) {
    final m = analysis.metadata;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Les chiffres du jour, une fois, en haut — c'est justement pour
        // qu'on les ait sous les yeux que le prompt interdit au coach de les
        // répéter dans son texte.
        Row(
          children: [
            Expanded(child: _Stat(value: '${m.totalCalories}', label: 'nutri_kcal'.tr(lang))),
            Expanded(child: _Stat(value: '${m.totalProteins.round()} g', label: 'proteins'.tr(lang))),
            Expanded(child: _Stat(value: '${m.totalCarbs.round()} g', label: 'carbohydrates'.tr(lang))),
            Expanded(child: _Stat(value: '${m.totalFats.round()} g', label: 'fats'.tr(lang))),
          ],
        ),
        SizedBox(height: context.vw(5.1)),
        Text(analysis.analysisText, style: RyzeText.body(context, 3.6, height: 1.55)),
        if (analysis.recommendations.isNotEmpty) ...[
          SizedBox(height: context.vw(5.1)),
          Text('ai_analysis_recommendations'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
          SizedBox(height: context.vw(2.6)),
          for (final raw in analysis.recommendations) _Reco(parts: _split(raw)),
        ],
      ],
    );
  }
}

class _Reco extends StatelessWidget {
  const _Reco({required this.parts});

  final (String, String) parts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.vw(2.6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: EdgeInsets.only(top: context.vw(1.5), right: context.vw(2.6)),
            decoration: BoxDecoration(color: RyzeColors.acc, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (parts.$1.isNotEmpty) Text(parts.$1, style: RyzeText.body(context, 3.4, weight: FontWeight.w600)),
                if (parts.$2.isNotEmpty) Text(parts.$2, style: RyzeText.body(context, 3.1, color: RyzeColors.mute, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          style: RyzeText.display(context, 5.6, weight: FontWeight.w600).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        SizedBox(height: context.vw(0.5)),
        Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 2.6, color: RyzeColors.mute)),
      ],
    );
  }
}

/// La porte, dans Nutrition, sous les repas du jour : une rangée discrète qui
/// n'apparaît que le soir. Pas une carte colorée — l'accueil a déjà proposé
/// l'analyse une fois, celle-ci est là pour qui revient dans son journal.
class DayAnalysisRow extends StatelessWidget {
  const DayAnalysisRow({super.key, required this.lang, required this.hasAnalysis, required this.onTap});

  final String lang;
  final bool hasAnalysis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.6)),
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          borderRadius: BorderRadius.circular(RyzeRadius.md),
          border: Border.all(color: RyzeColors.line),
        ),
        child: Row(
          children: [
            const CoachAvatar(RyzeAssets.nutriAvatar, sizeVw: 9.7),
            SizedBox(width: context.vw(3.1)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasAnalysis ? 'day_analysis_see'.tr(lang) : 'day_analysis_run'.tr(lang),
                    style: RyzeText.body(context, 3.6, weight: FontWeight.w600),
                  ),
                  Text('day_analysis_hint'.tr(lang), maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, size: context.vw(4.6), color: RyzeColors.mute2),
          ],
        ),
      ),
    );
  }
}
