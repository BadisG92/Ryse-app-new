import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../services/analytics_service.dart';
import '../../services/haptic_service.dart';
import '../../services/notification_service.dart';
import '../onboarding_repository.dart';
import '../onboarding_state.dart';
import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import '../widgets/choices.dart';
import '../widgets/onb_widgets.dart';

/// Ce que la page de sortie rend au paywall.
enum OnbExitOutcome {
  /// Rien n'a changé : on revient à l'offre telle qu'elle était.
  stay,

  /// « C'est trop cher » : le paywall se rouvre sur le plan le plus court.
  weekly,

  /// « Je veux essayer avant » : le paywall se rouvre sur l'annuel et son essai.
  trial,

  /// « Pas maintenant » : deux rappels sont posés, le compte est gardé.
  reminded,
}

/// La porte de sortie du paywall.
///
/// Le paywall est dur : rien de cet écran n'ouvre l'app. Ce qu'il fait, c'est
/// transformer un départ muet en une phrase — la seule donnée qui manquait
/// pour savoir quoi répondre. Aujourd'hui, quelqu'un qui ne veut pas payer
/// ferme l'app, et au lancement suivant il retombe sur le prix, sans l'histoire
/// et sans le plan qu'il a construit : le deuxième contact est la pire version
/// de l'argumentaire.
///
/// Chaque motif a sa réponse, et chaque réponse est vraie : l'hebdo existe
/// vraiment, l'essai est vraiment gratuit, et le rappel part vraiment.
class OnboardingExitScreen extends StatefulWidget {
  const OnboardingExitScreen({
    super.key,
    required this.s,
    required this.plan,
    required this.weeklyPrice,
    required this.trialEligible,
    required this.store,
  });

  final OnbStrings s;

  /// Le plan sélectionné au moment où la personne a voulu partir.
  final String plan;

  /// Le prix réel de l'hebdo, tel que le store le donne.
  final String weeklyPrice;

  /// L'essai n'est proposé que s'il peut vraiment démarrer.
  final bool trialEligible;

  final String store;

  static Future<OnbExitOutcome> show(
    BuildContext context, {
    required OnbStrings s,
    required String plan,
    required String weeklyPrice,
    required bool trialEligible,
    required String store,
  }) async {
    final outcome = await Navigator.of(context).push<OnbExitOutcome>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingExitScreen(
          s: s,
          plan: plan,
          weeklyPrice: weeklyPrice,
          trialEligible: trialEligible,
          store: store,
        ),
      ),
    );
    return outcome ?? OnbExitOutcome.stay;
  }

  @override
  State<OnboardingExitScreen> createState() => _OnboardingExitScreenState();
}

class _OnboardingExitScreenState extends State<OnboardingExitScreen> {
  static const List<String> _reasons = ['price', 'try_first', 'not_now'];

  String? _reason;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('paywall_exit_opened', parameters: {'plan': widget.plan});
  }

  /// Le motif choisi part une fois, quand on quitte la page : trois taps
  /// d'hésitation sur les trois cartes ne doivent pas écrire trois lignes.
  ///
  /// Seule une vraie réponse va en base. Ouvrir puis refermer la page compte
  /// comme un « non » — la prochaine visite verra l'offre de retour — mais ce
  /// n'est pas une objection, et ça n'a rien à faire dans la table.
  Future<void> _leave(OnbExitOutcome outcome) async {
    final reason = _reason;
    AnalyticsService.logEvent('paywall_exit', parameters: {
      'reason': reason ?? 'none',
      'outcome': outcome.name,
      'plan': widget.plan,
    });
    await OnbProgressStore.markExit(reason ?? 'other');
    if (reason != null) {
      unawaited(OnboardingRepository().recordPaywallExit(
        reason: reason,
        plan: widget.plan,
        lang: widget.s.lang,
        reminderSet: outcome == OnbExitOutcome.reminded,
      ));
    }
    if (mounted) Navigator.pop(context, outcome);
  }

  /// Le rappel n'est pas une promesse en l'air : il demande l'autorisation, et
  /// si elle est refusée il le dit au lieu de faire semblant.
  Future<void> _setReminder() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final s = widget.s;
    var ok = false;
    try {
      ok = await NotificationService().requestPermissions();
      if (ok) {
        ok = await NotificationService().scheduleWinBack(
          day1Title: s.t('wb1_title'),
          day1Body: s.t('wb1_body'),
          day3Title: s.t('wb3_title'),
          day3Body: s.t('wb3_body'),
        );
      }
    } catch (_) {
      ok = false;
    }
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) {
      HapticService.instance.lightImpact();
      setState(() => _error = s.t('exit_reminder_off'));
      return;
    }
    HapticService.instance.mediumImpact();
    await _leave(OnbExitOutcome.reminded);
  }

  /// La réponse au motif choisi : une phrase et un geste, jamais un mur.
  ({String text, String cta, VoidCallback onTap})? get _answer {
    final s = widget.s;
    switch (_reason) {
      case 'price':
        return (
          text: s.t('exit_a_price', {'p': widget.weeklyPrice, 'store': widget.store}),
          cta: s.t('exit_cta_price'),
          onTap: () => _leave(OnbExitOutcome.weekly),
        );
      case 'try_first':
        if (!widget.trialEligible) {
          return (
            text: s.t('exit_a_try_used', {'p': widget.weeklyPrice, 'store': widget.store}),
            cta: s.t('exit_cta_price'),
            onTap: () => _leave(OnbExitOutcome.weekly),
          );
        }
        return (
          text: s.t('exit_a_try', {'store': widget.store}),
          cta: s.t('exit_cta_try'),
          onTap: () => _leave(OnbExitOutcome.trial),
        );
      case 'not_now':
        return (
          text: s.t('exit_a_now'),
          cta: s.t('exit_cta_now'),
          onTap: _setReminder,
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final answer = _answer;

    return Scaffold(
      backgroundColor: OnbColors.paper,
      body: Stack(
        children: [
          const Positioned.fill(child: OnbBackground(scene: false)),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(context.vw(6), context.vh(2), context.vw(6), context.vh(2)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Round(
                      icon: LucideIcons.chevronLeft,
                      onTap: _busy ? null : () => _leave(OnbExitOutcome.stay),
                    ),
                  ),
                  SizedBox(height: context.vh(2)),
                  WipeText(s.t('exit_title'), style: OnbText.display(context, 7.2)),
                  SizedBox(height: context.vh(1.2)),
                  Text(s.t('exit_sub'), style: OnbText.body(context, 3.5, color: OnbColors.mute, height: 1.5)),
                  SizedBox(height: context.vh(2.6)),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, reason) in _reasons.indexed) ...[
                            if (i > 0) SizedBox(height: context.vw(2.6)),
                            OnbOptionCard(
                              title: s.t('exit_r_${_key(reason)}'),
                              subtitle: s.t('exit_r_${_key(reason)}_sub'),
                              selected: _reason == reason,
                              index: i,
                              onTap: () {
                                AnalyticsService.logEvent('paywall_exit_reason', parameters: {'reason': reason});
                                setState(() {
                                  _reason = reason;
                                  _error = null;
                                });
                              },
                            ),
                          ],
                          AnimatedSize(
                            duration: RyzeDurations.enter,
                            curve: OnbCurves.out,
                            alignment: Alignment.topCenter,
                            child: answer == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: EdgeInsets.only(top: context.vw(4.6)),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        OnbCard(
                                          child: Text(
                                            answer.text,
                                            style: OnbText.body(context, 3.6, height: 1.55),
                                          ),
                                        ),
                                        if (_error != null) ...[
                                          SizedBox(height: context.vw(2.6)),
                                          Text(
                                            _error!,
                                            style: OnbText.body(context, 3.2, color: OnbColors.danger, height: 1.45),
                                          ),
                                        ],
                                        SizedBox(height: context.vw(4.1)),
                                        OnbButton(
                                          label: answer.cta,
                                          onPressed: _busy ? null : answer.onTap,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: context.vh(1)),
                  Text(
                    s.t('exit_note'),
                    textAlign: TextAlign.center,
                    style: OnbText.body(context, 3.1, color: OnbColors.mute2, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Les clés du dictionnaire sont plus courtes que les motifs stockés.
  static String _key(String reason) => switch (reason) {
        'price' => 'price',
        'try_first' => 'try',
        _ => 'now',
      };
}

/// Le même bouton rond que partout : une icône, un cercle, rien d'autre.
class _Round extends StatelessWidget {
  const _Round({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap == null
          ? null
          : () {
              HapticService.instance.lightImpact();
              onTap!();
            },
      child: Container(
        width: context.vw(9.7),
        height: context.vw(9.7),
        decoration: BoxDecoration(
          color: OnbColors.surf,
          shape: BoxShape.circle,
          border: Border.all(color: OnbColors.line),
        ),
        child: Icon(icon, size: context.vw(4.6), color: OnbColors.ink),
      ),
    );
  }
}
