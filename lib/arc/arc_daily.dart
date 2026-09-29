import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../design/design.dart';
import '../services/app_navigator.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/weekly_planner_service.dart';
import 'arc_grid.dart';
import 'arc_intro_sheet.dart';
import 'arc_service.dart';
import 'arc_state.dart';
import 'arc_words.dart';

/// Ce que la première ouverture du jour a à dire.
enum ArcMorning {
  /// La première fois : l'arc s'annonce, avec son règlement.
  intro,

  /// Le 90e jour est tenu.
  won,

  /// Hier est incomplet et rattrapable jusqu'à midi.
  grace,

  /// La série s'est arrêtée.
  broke,

  /// Un joker a sauvé hier.
  joker,

  /// Hier est tenu : sa case se remplit.
  held,

  /// Rien à dire.
  none,
}

/// La feuille du matin : une fois par jour, à la première ouverture.
///
/// C'est le rituel de l'arc. La case d'hier se remplit sous les yeux, ou la
/// feuille dit ce qui reste à rattraper avant midi, ou qu'un joker a servi,
/// ou que la série repart. Jamais deux feuilles le même jour.
class ArcDaily {
  ArcDaily._();

  static bool _busy = false;

  /// L'onboarding vient de se terminer dans cette session : son pacte, signé
  /// en maintenant un bouton une minute plus tôt, vaut engagement. L'intro du
  /// Winter Arc ne redemande donc pas le même geste, elle offre un simple
  /// bouton.
  static bool pactJustSigned = false;

  /// Le choix, sans rien afficher : ce que la base a rendu, et ce que ce
  /// téléphone a déjà montré.
  ///
  /// Avant l'ouverture, l'intro s'annonce une fois (`soonSeen`) : on s'y
  /// engage déjà. Le premier jour, elle revient une dernière fois pour dire
  /// que c'est parti, sans redemander le geste.
  static ArcMorning pick(
    ArcState s, {
    required bool introSeen,
    required bool wonSeen,
    bool soonSeen = false,
    DateTime? breakSeen,
    DateTime? jokerSeen,
  }) {
    if (s.won && !wonSeen) return ArcMorning.won;
    if (s.isSoon) return introSeen || soonSeen ? ArcMorning.none : ArcMorning.intro;
    if (!s.isOpen) return ArcMorning.none;
    if (!introSeen) return ArcMorning.intro;
    if (s.rescuable) return ArcMorning.grace;
    final broke = s.lastBreak;
    if (broke != null && broke.lost >= 2 && (breakSeen == null || broke.day.isAfter(breakSeen))) return ArcMorning.broke;
    final joker = s.lastJoker;
    if (joker != null && (jokerSeen == null || joker.isAfter(jokerSeen))) return ArcMorning.joker;
    final y = s.yesterdayCell;
    if (y == ArcCell.held || y == ArcCell.trained) return ArcMorning.held;
    return ArcMorning.none;
  }

  /// Montre la feuille du jour si elle n'a pas encore été vue.
  static Future<void> maybeShow(BuildContext context) async {
    if (_busy || WeeklyPlannerService.isDemoMode) return;
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return;
    _busy = true;
    try {
      await ArcService.instance.firstAnswer;
      final s = ArcService.instance.state;
      if (s == null) return;

      final prefs = await SharedPreferences.getInstance();
      String key(String name) => 'arc_${name}_$uid';
      final today = _ymd(s.today);
      if (prefs.getString(key('seen')) == today) return;

      final what = pick(
        s,
        introSeen: prefs.getBool(key('intro')) ?? false,
        wonSeen: prefs.getBool(key('won')) ?? false,
        soonSeen: prefs.getBool(key('intro_soon')) ?? false,
        breakSeen: DateTime.tryParse(prefs.getString(key('break')) ?? ''),
        jokerSeen: DateTime.tryParse(prefs.getString(key('joker')) ?? ''),
      );

      // Marqué avant d'afficher : un retour rapide à l'app ne doit pas la
      // rouvrir pendant qu'elle est encore à l'écran.
      await prefs.setString(key('seen'), today);
      switch (what) {
        case ArcMorning.intro when s.isSoon:
          // L'annonce : l'intro du premier jour reste à venir.
          await prefs.setBool(key('intro_soon'), true);
        case ArcMorning.intro:
          await prefs.setBool(key('intro'), true);
          // Ce qui s'est passé avant l'intro n'est pas une nouvelle : sans
          // ça, le lendemain matin annoncerait une série perdue que
          // l'utilisateur n'a jamais connue, ou un joker qu'il n'a jamais vu.
          if (s.lastBreak != null) await prefs.setString(key('break'), _ymd(s.lastBreak!.day));
          if (s.lastJoker != null) await prefs.setString(key('joker'), _ymd(s.lastJoker!));
        case ArcMorning.won:
          await prefs.setBool(key('won'), true);
        case ArcMorning.broke:
          await prefs.setString(key('break'), _ymd(s.lastBreak!.day));
        case ArcMorning.joker:
          await prefs.setString(key('joker'), _ymd(s.lastJoker!));
        case ArcMorning.grace:
        case ArcMorning.held:
        case ArcMorning.none:
          break;
      }
      if (what == ArcMorning.none || !context.mounted) return;
      // Engagé avant l'ouverture : le premier jour, un simple « C'est parti ».
      final pactBefore = prefs.getString('arc_pact_$uid') != null;
      await _show(context, s, what, pactBefore: pactBefore);
    } finally {
      _busy = false;
    }
  }

  static Future<void> _show(BuildContext context, ArcState s, ArcMorning what, {bool pactBefore = false}) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    // La première fois, ce n'est pas une feuille de plus : c'est l'affiche.
    if (what == ArcMorning.intro) {
      final onboarding = pactJustSigned;
      pactJustSigned = false;
      final source = onboarding ? 'onboarding' : (pactBefore && !s.isSoon ? 'preseason' : 'intro');
      return showArcIntro(context, s, lang, alreadyCommitted: source != 'intro', source: source);
    }
    final today = s.todayStatus;
    final todayMissing = today == null || today.held ? '' : ArcWords.missing(meals: today.mealsMissing, waterMl: today.waterMissingMl, lang: lang);
    final yesterday = s.cells.length - 2;

    late final String title;
    late final String subtitle;
    int? reveal;
    var cta = 'arc_continue'.tr(lang);
    VoidCallback? onCta;
    String? secondary;

    switch (what) {
      case ArcMorning.won:
        title = 'arc_won_title'.tr(lang);
        subtitle = 'arc_won_sub'.tr(lang);
      case ArcMorning.grace:
        final g = s.grace!;
        title = 'arc_grace_title'.tr(lang);
        subtitle = 'arc_grace_sub'
            .tr(lang)
            .replaceAll('{missing}', ArcWords.missing(meals: g.mealsMissing, waterMl: g.waterMissingMl, lang: lang))
            .replaceAll('{n}', '${s.streak}')
            .replaceAll('{days}', ArcWords.days(s.streak, lang));
        cta = 'arc_grace_cta'.tr(lang);
        onCta = () => AppNavigator().requestNutritionHistory();
        secondary = 'arc_later'.tr(lang);
      case ArcMorning.broke:
        final b = s.lastBreak!;
        title = 'arc_break_title'.tr(lang).replaceAll('{n}', '${b.lost}').replaceAll('{days}', ArcWords.days(b.lost, lang));
        subtitle = 'arc_break_sub'.tr(lang);
        cta = 'arc_restart'.tr(lang);
      case ArcMorning.joker:
        title = 'arc_joker_title'.tr(lang);
        subtitle = 'arc_joker_sub'.tr(lang).replaceAll('{n}', '${s.jokers}');
        reveal = yesterday >= 0 ? yesterday : null;
      case ArcMorning.held:
        final left = ArcSeason.length - s.streak;
        title = 'arc_held_title'.tr(lang).replaceAll('{n}', '${yesterday + 1}');
        subtitle = [
          'arc_held_sub'.tr(lang).replaceAll('{n}', '$left').replaceAll('{days}', ArcWords.days(left, lang)),
          if (todayMissing.isNotEmpty) 'arc_held_today'.tr(lang).replaceAll('{missing}', todayMissing),
        ].join(' ');
        reveal = yesterday;
      case ArcMorning.intro:
      case ArcMorning.none:
        return;
    }

    await showRyzeSheet<void>(
      context,
      title: title,
      subtitle: subtitle,
      builder: (sheet) => Padding(
        padding: EdgeInsets.only(top: sheet.vw(1)),
        child: ArcGrid(cells: s.cells, reveal: reveal),
      ),
      actions: [
        Builder(
          builder: (sheet) => OnbButton(
            label: cta,
            onPressed: () {
              Navigator.of(sheet).pop();
              onCta?.call();
            },
          ),
        ),
        if (secondary != null)
          Builder(
            builder: (sheet) => _TextAction(
              label: secondary!,
              onTap: () => Navigator.of(sheet).pop(),
            ),
          ),
      ],
    );
  }
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(2.3)),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.ink),
        ),
      ),
    );
  }
}

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
