import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/supabase_config.dart';
import '../design/design.dart';
import '../services/app_navigator.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/weekly_planner_service.dart';
import 'arc_page.dart';
import 'arc_state.dart';
import 'arc_words.dart';
import 'winter_flame.dart';

/// Ce que la base vient de valider, sous les yeux.
enum ArcValidated {
  /// Aujourd'hui : le repas ou le verre qui manquait vient d'être noté.
  today,

  /// Hier, rattrapé avant midi.
  yesterday,
}

/// Le bandeau du moment où la journée est validée.
///
/// La feuille du matin remplit la case d'hier le lendemain ; ce bandeau dit la
/// chose à l'instant où elle arrive, là où l'on est : « Jour 12 validé. Plus
/// que 78 jours. », sur la nuit de la saison, avec la flamme de glace. Il
/// laisse passer d'abord « Repas ajouté · Annuler », qui occupe la même place,
/// et se pousse au-dessus si une autre écriture en affiche un pendant qu'il est
/// là. Une fois par jour et par journée validée.
class ArcBanner {
  ArcBanner._();

  static const Duration life = Duration(milliseconds: 4200);

  static OverlayEntry? _entry;
  static Timer? _timer;

  /// Ce que la réponse de la base a changé, sans rien afficher.
  static ArcValidated? detect(ArcState? before, ArcState next) {
    if (before == null || !next.isOpen) return null;
    final b = before.today;
    final n = next.today;
    if (b.year != n.year || b.month != n.month || b.day != n.day) return null;
    if (!before.todayHeld && next.todayHeld) return ArcValidated.today;
    final wasOpen = before.grace != null && before.yesterdayCell == ArcCell.pending;
    final y = next.yesterdayCell;
    if (wasOpen && next.grace == null && (y == ArcCell.held || y == ArcCell.trained)) return ArcValidated.yesterday;
    return null;
  }

  /// Le titre et la ligne du bandeau.
  static (String, String) words(ArcValidated what, ArcState s, String lang) {
    if (what == ArcValidated.yesterday) {
      return (
        'arc_banner_yesterday'.tr(lang),
        'arc_banner_yesterday_sub'.tr(lang).replaceAll('{n}', '${s.streak}').replaceAll('{days}', ArcWords.days(s.streak, lang)),
      );
    }
    if (s.won) return ('arc_won_title'.tr(lang), 'arc_won_sub'.tr(lang));
    final left = ArcSeason.length - s.streak;
    return (
      'arc_held_title'.tr(lang).replaceAll('{n}', '${s.dayNumber}'),
      'arc_held_sub'.tr(lang).replaceAll('{n}', '$left').replaceAll('{days}', ArcWords.days(left, lang)),
    );
  }

  /// Montre le bandeau s'il n'a pas déjà été vu pour cette journée.
  static Future<void> celebrate(ArcValidated what, ArcState s) async {
    if (WeeklyPlannerService.isDemoMode) return;
    final uid = SupabaseConfig.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'arc_banner_${what.name}_$uid';
      final day = _ymd(s.today);
      if (prefs.getString(key) == day) return;
      await prefs.setString(key, day);
    } catch (_) {}

    // « Repas ajouté · Annuler » d'abord : on n'enlève jamais le moyen de
    // revenir en arrière.
    for (var i = 0; i < 24 && RyzeUndo.visible.value; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    final context = AppNavigator().overlayContext;
    if (context == null || !context.mounted) return;
    show(context, what, s);
  }

  static void show(BuildContext context, ArcValidated what, ArcState s) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;
    dismiss();
    final lang = LocalizationService.instance.currentLanguageCode;
    final (title, sub) = words(what, s, lang);
    RyzeFeedback.success();
    final entry = OverlayEntry(
      builder: (context) => _ArcBannerView(
        title: title,
        sub: sub,
        onTap: () {
          dismiss();
          final nav = AppNavigator().navigatorState;
          if (nav != null) openArcPage(nav.context);
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
    _timer = Timer(life, dismiss);
  }

  static void dismiss() {
    _timer?.cancel();
    _timer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _ArcBannerView extends StatefulWidget {
  const _ArcBannerView({required this.title, required this.sub, required this.onTap});

  final String title;
  final String sub;
  final VoidCallback onTap;

  @override
  State<_ArcBannerView> createState() => _ArcBannerViewState();
}

class _ArcBannerViewState extends State<_ArcBannerView> with SingleTickerProviderStateMixin {
  static const Color _night = Color(0xFF0B132B);
  static const Color _night2 = Color(0xFF16224A);

  late final AnimationController _c = AnimationController(vsync: this, duration: RyzeDurations.enter)..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final flame = context.vw(7.7);
    return ValueListenableBuilder<bool>(
      // Une autre écriture affiche son « Annuler » : le bandeau se pousse au-dessus.
      valueListenable: RyzeUndo.visible,
      builder: (context, undo, child) => AnimatedPositioned(
        duration: reduce ? Duration.zero : RyzeDurations.enter,
        curve: RyzeCurves.out,
        left: context.vw(5.1),
        right: context.vw(5.1),
        bottom: RyzeUndo.bottomInset + MediaQuery.paddingOf(context).bottom + (undo ? 52 : 0),
        child: child!,
      ),
      child: SlideTransition(
        position: Tween(begin: Offset(0, reduce ? 0 : 0.6), end: Offset.zero).animate(CurvedAnimation(parent: _c, curve: RyzeCurves.spring)),
        child: FadeTransition(
          opacity: _c,
          child: Material(
            color: Colors.transparent,
            child: Pressable(
              onTap: widget.onTap,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(3.1)),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_night, _night2]),
                  borderRadius: BorderRadius.circular(RyzeRadius.lg),
                  boxShadow: RyzeShadow.lift,
                ),
                child: Row(
                  children: [
                    SizedBox.square(
                      dimension: flame,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          WinterFlame(size: flame),
                          if (!reduce) const Positioned.fill(child: IgnorePointer(child: SparkBurst(count: 14))),
                        ],
                      ),
                    ),
                    SizedBox(width: context.vw(3.1)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: RyzeText.display(context, 4.4, color: Colors.white),
                          ),
                          SizedBox(height: context.vw(0.5)),
                          Text(
                            widget.sub,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: RyzeText.body(context, 3.4, weight: FontWeight.w600, color: ArcIce.midTop),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
