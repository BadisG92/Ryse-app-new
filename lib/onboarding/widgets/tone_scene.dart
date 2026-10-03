import 'package:flutter/material.dart';

import '../../components/ui/motion.dart' show TypingDots;
import '../../design/sheet.dart';
import '../../services/coach_personality_service.dart';
import '../../services/haptic_service.dart';
import '../onboarding_strings.dart';
import '../onboarding_theme.dart';
import 'choices.dart';
import 'onb_widgets.dart';

/// L'écran du ton : une excuse, celle de la personne, et six façons d'y
/// répondre. On choisit un ton, et seule la réponse change.
///
/// Il empilait avant deux questions de même poids, choisir un ton puis
/// tester une excuse, avec deux champs et trois blocs marine qui se
/// disputaient l'œil. Il n'en reste qu'une : la carte, au centre, est le
/// seul point focal, et le marine ne marque plus que ce qu'on choisit.
class OnbToneOption {
  const OnbToneOption({required this.key, required this.emoji, required this.label});
  final String key;
  final String emoji;
  final String label;
}

/// Six pastilles sur deux rangées de trois, emoji et nom sur une ligne. Elles
/// tiennent en 44 points de haut, ce qui laisse la place à la carte.
class OnbTonePills extends StatelessWidget {
  const OnbTonePills({super.key, required this.options, required this.value, required this.onChanged});
  final List<OnbToneOption> options;
  final String? value;
  final ValueChanged<String> onChanged;

  static const int _perRow = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var r = 0; r * _perRow < options.length; r++) ...[
          if (r > 0) SizedBox(height: context.vw(2)),
          Row(
            children: [
              for (var i = r * _perRow; i < (r + 1) * _perRow; i++) ...[
                if (i > r * _perRow) SizedBox(width: context.vw(2)),
                Expanded(child: i < options.length ? _pill(context, i) : const SizedBox()),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _pill(BuildContext context, int i) {
    final o = options[i];
    final on = o.key == value;
    return PopIn(
      delay: Duration(milliseconds: 320 + i * 45),
      duration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onTap: () {
          HapticService.instance.lightImpact();
          onChanged(o.key);
        },
        child: AnimatedSlide(
          offset: on ? const Offset(0, -0.045) : Offset.zero,
          duration: const Duration(milliseconds: 260),
          curve: OnbCurves.spring,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            height: context.vw(11.3),
            padding: EdgeInsets.symmetric(horizontal: context.vw(1)),
            decoration: BoxDecoration(
              color: on ? OnbColors.ink : OnbColors.surf,
              borderRadius: BorderRadius.circular(context.vw(3.4)),
              border: Border.all(color: on ? OnbColors.ink : OnbColors.line),
              boxShadow: on
                  ? [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.32), blurRadius: context.vw(3.2), offset: Offset(0, context.vw(1.2)))]
                  : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: on ? 1.15 : 1,
                  duration: const Duration(milliseconds: 260),
                  child: Text(o.emoji, style: TextStyle(fontSize: context.vw(4.2), height: 1)),
                ),
                SizedBox(width: context.vw(1.2)),
                Flexible(
                  child: Text(
                    o.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: OnbText.body(context, 3.2, weight: FontWeight.w600, color: on ? Colors.white : OnbColors.ink, height: 1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// La scène : l'excuse en haut, immobile, puis la réponse du coach. La carte
/// réserve trois lignes à la réponse pour que rien ne saute quand elle change.
class OnbToneCard extends StatelessWidget {
  const OnbToneCard({super.key, required this.label, required this.excuse, required this.idle, this.reply, this.thinking = false});
  final String label;
  final String excuse;
  final String idle;
  final String? reply;
  final bool thinking;

  @override
  Widget build(BuildContext context) {
    final replyStyle = OnbText.body(context, 4.6, weight: FontWeight.w500, height: 1.4);
    final Widget answer;
    if (thinking) {
      answer = Padding(padding: EdgeInsets.only(top: context.vw(1.6)), child: TypingDots(color: OnbColors.mute2));
    } else if (reply != null) {
      answer = WordStream(reply!, key: ValueKey(reply), style: replyStyle);
    } else {
      answer = Text(idle, style: replyStyle.copyWith(color: OnbColors.mute2));
    }
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(context.vw(5.2), context.vw(5), context.vw(5.2), context.vw(5.4)),
      decoration: BoxDecoration(
        color: OnbColors.surf,
        borderRadius: BorderRadius.circular(context.vw(5)),
        border: Border.all(color: OnbColors.ink.withValues(alpha: 0.06)),
        boxShadow: [BoxShadow(color: OnbColors.ink.withValues(alpha: 0.07), blurRadius: context.vw(4), offset: Offset(0, context.vw(1)))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: OnbText.body(context, 3, weight: FontWeight.w600, color: OnbColors.mute, height: 1.2)),
          SizedBox(height: context.vw(1.4)),
          Text(excuse, style: OnbText.body(context, 4.3, weight: FontWeight.w600, height: 1.3)),
          Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(4.2)),
            child: Container(height: 1, color: OnbColors.line),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: replyStyle.fontSize! * 1.4 * 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: context.vw(7.4),
                  height: context.vw(7.4),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: OnbColors.ink.withValues(alpha: 0.14)),
                  clipBehavior: Clip.antiAlias,
                  child: Image.asset(OnbAssets.sportAvatar, fit: BoxFit.cover, alignment: const Alignment(0, -0.6)),
                ),
                SizedBox(width: context.vw(3)),
                Expanded(child: Padding(padding: EdgeInsets.only(top: context.vw(0.6)), child: answer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// « À ta façon » : le seul clavier du parcours, dans une feuille pour ne
/// pas encombrer l'écran. Les trois exemples font ce qu'aucun ton prédéfini
/// ne sait faire : un sergent aurait refait le strict, un pote survolté le
/// bon pote. Rend le texte validé, ou `null` si on referme sans valider.
class OnbCustomToneSheet {
  OnbCustomToneSheet._();

  /// En dessous, ce n'est pas encore une consigne.
  static const int minLength = 10;

  static const List<String> examples = ['sister', 'caster', 'butler'];

  static Future<String?> show(BuildContext context, {required OnbStrings s, String initial = ''}) {
    return showRyzeSheet<String>(
      context,
      title: s.t('tone_sheet_title'),
      subtitle: s.t('tone_sheet_sub'),
      keyboard: true,
      builder: (_) => _CustomToneBody(s: s, initial: initial),
    );
  }
}

class _CustomToneBody extends StatefulWidget {
  const _CustomToneBody({required this.s, required this.initial});
  final OnbStrings s;
  final String initial;

  @override
  State<_CustomToneBody> createState() => _CustomToneBodyState();
}

class _CustomToneBodyState extends State<_CustomToneBody> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _use(String text) {
    setState(() {
      _ctrl.text = text;
      _ctrl.selection = TextSelection.collapsed(offset: text.length);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.s;
    final text = _ctrl.text.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          autofocus: widget.initial.isEmpty,
          onChanged: (_) => setState(() {}),
          minLines: 3,
          maxLines: 4,
          maxLength: CoachPersonalityService.maxCustomLength,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          style: OnbText.body(context, 3.9),
          cursorColor: OnbColors.ink,
          decoration: InputDecoration(
            hintText: s.t('tone_sheet_hint'),
            hintStyle: OnbText.body(context, 3.9, color: OnbColors.mute2),
            hintMaxLines: 2,
            counterText: '',
            filled: true,
            fillColor: OnbColors.surf,
            contentPadding: EdgeInsets.symmetric(horizontal: context.vw(4.2), vertical: context.vw(3.6)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.vw(4.2)), borderSide: BorderSide(color: OnbColors.line)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(context.vw(4.2)), borderSide: BorderSide(color: OnbColors.ink, width: 2)),
          ),
        ),
        SizedBox(height: context.vw(3)),
        Wrap(
          spacing: context.vw(2),
          runSpacing: context.vw(2),
          children: [
            for (final (i, k) in OnbCustomToneSheet.examples.indexed)
              OnbChip(
                index: i,
                label: s.t('tone_ex_${k}_label'),
                selected: text == s.t('tone_ex_$k'),
                onTap: () => _use(s.t('tone_ex_$k')),
              ),
          ],
        ),
        SizedBox(height: context.vw(5)),
        OnbButton(
          label: s.t('tone_sheet_try'),
          onPressed: text.length < OnbCustomToneSheet.minLength ? null : () => Navigator.of(context).pop(text),
        ),
      ],
    );
  }
}
