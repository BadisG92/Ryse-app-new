import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design/design.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

/// Pourquoi Ryze demande le micro, avant que le système ne le demande.
///
/// C'était un `AlertDialog` — la dernière boîte Material atteignable depuis le
/// chat. C'est une feuille maintenant, comme toutes les questions de
/// l'application. Le nom de la classe ne change pas : ses deux appelants n'ont
/// rien à savoir de la forme.
class MicrophonePermissionDialog {
  static const String _prefKey = 'microphone_permission_explained';

  /// Vrai si l'explication a déjà été donnée une fois.
  static Future<bool> hasShownExplanation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> markExplanationShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// L'explication, une seule fois dans la vie de l'application. Rend vrai
  /// quand l'utilisateur veut continuer.
  static Future<bool> showExplanationIfNeeded(
    BuildContext context, {
    required bool Function() isMounted,
  }) async {
    if (await hasShownExplanation()) return true;
    if (!isMounted()) return false;

    final ok = await showExplanation(context);
    if (ok) await markExplanationShown();
    return ok;
  }

  /// La même feuille, forcée : depuis les réglages, ou pour réessayer.
  static Future<bool> showExplanation(BuildContext context) async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final result = await showRyzeSheet<bool>(
      context,
      title: 'mic_permission_title'.tr(lang),
      dismissible: false,
      builder: (sheet) => _Body(lang: lang),
      actions: [
        Row(
          children: [
            Expanded(
              child: OnbButton(
                label: 'mic_permission_not_now'.tr(lang),
                ghost: true,
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
            SizedBox(width: context.vw(2.6)),
            Expanded(
              flex: 2,
              child: OnbButton(
                label: 'mic_permission_continue'.tr(lang),
                onPressed: () => Navigator.pop(context, true),
              ),
            ),
          ],
        ),
      ],
    );
    return result ?? false;
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.lang});

  final String lang;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'mic_permission_description'.tr(lang),
          style: RyzeText.body(context, 3.6, color: RyzeColors.mute, height: 1.5),
        ),
        SizedBox(height: context.vw(5.1)),
        _Line(icon: LucideIcons.messageCircle, text: 'mic_permission_feature_chat'.tr(lang)),
        SizedBox(height: context.vw(3.1)),
        _Line(icon: LucideIcons.dumbbell, text: 'mic_permission_feature_workout'.tr(lang)),
        SizedBox(height: context.vw(5.1)),
        // La promesse sur les données : elle a sa propre surface, parce que
        // c'est elle qui décide la réponse plus souvent que le reste.
        Container(
          padding: EdgeInsets.all(context.vw(3.6)),
          decoration: BoxDecoration(
            color: RyzeColors.paper2,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(LucideIcons.shieldCheck, size: context.vw(4.6), color: RyzeColors.ink),
              SizedBox(width: context.vw(3.1)),
              Expanded(
                child: Text(
                  'mic_permission_privacy'.tr(lang),
                  style: RyzeText.body(context, 3.2, color: RyzeColors.mute, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: context.vw(9.2),
          height: context.vw(9.2),
          decoration: BoxDecoration(
            color: RyzeColors.paper2,
            borderRadius: BorderRadius.circular(RyzeRadius.sm),
          ),
          child: Icon(icon, size: context.vw(4.4), color: RyzeColors.ink),
        ),
        SizedBox(width: context.vw(3.1)),
        Expanded(
          child: Text(text, style: RyzeText.body(context, 3.4, height: 1.4)),
        ),
      ],
    );
  }
}
