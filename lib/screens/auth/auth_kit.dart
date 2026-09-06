import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/design.dart';
import '../../services/translations.dart';

/// Shared pieces of the account screens, in the onboarding's design system.
///
/// The account screen is the first interactive screen of the app, so it speaks
/// the same language as the flow right behind it: paper ground with the grid
/// and the warm corner, Archivo headline, navy for everything the user presses.
/// Amber stays reserved for what Ryze gives back — no gold button here.

/// Error red. The onboarding palette has no failure state; this is the one
/// place that needs one, and it is used for nothing else.
const Color kAuthDanger = RyzeColors.danger;

/// Permissive on purpose: a local part, an @, a domain with a dot, and no
/// spaces. The old `[\w-]{2,4}$` rejected `.fitness`, `.coach`, `.online` and
/// every `first+tag@` alias — on the three auth screens at once. Supabase
/// rejects what is really invalid.
final RegExp kEmailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

bool isValidEmail(String value) => kEmailPattern.hasMatch(value.trim());

String legalUrl({required String lang, required bool terms}) {
  final fr = lang == 'fr';
  if (terms) {
    return fr ? 'https://coach-ryze.com/terms.html' : 'https://coach-ryze.com/terms_en.html';
  }
  return fr ? 'https://coach-ryze.com/privacy.html' : 'https://coach-ryze.com/privacy_en.html';
}

Future<void> openLegal(String url) async {
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    // a missing browser must never break the sign-up
  }
}

/// Headline of an auth screen. Same rule as `_shell` in the onboarding: the
/// size follows the length, so a long German title never pushes the screen out.
class AuthTitle extends StatelessWidget {
  const AuthTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    final vw = text.length <= 30 ? 7.8 : (text.length <= 46 ? 6.9 : 6.1);
    return WipeText(text, style: RyzeText.display(context, vw, height: 1.08));
  }
}

/// Ground + status bar + scrolling column, identical to an onboarding step.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children, this.onBack});

  final List<Widget> children;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: RyzeColors.paper,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            const Positioned.fill(child: OnbBackground()),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(context.vw(6), context.vh(1.2), context.vw(6), context.vh(2)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (onBack != null)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(onTap: onBack!),
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.only(bottom: context.vh(2)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = context.vw(10);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: d,
        height: d,
        decoration: BoxDecoration(
          color: RyzeColors.surf,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: RyzeColors.ink.withValues(alpha: 0.06), blurRadius: context.vw(2.4), offset: Offset(0, context.vw(0.8)))],
          border: Border.all(color: RyzeColors.line),
        ),
        child: Icon(LucideIcons.chevronLeft, size: context.vw(4.4), color: RyzeColors.ink),
      ),
    );
  }
}

/// The two coaches, bobbing, exactly as they open the onboarding.
class AuthCoaches extends StatelessWidget {
  const AuthCoaches({super.key, this.sizeVw = 13});
  final double sizeVw;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Bob(child: CoachAvatar(RyzeAssets.sportAvatar, sizeVw: sizeVw)),
        Transform.translate(
          offset: Offset(-context.vw(sizeVw * 0.28), 0),
          child: Bob(phase: 0.5, child: CoachAvatar(RyzeAssets.nutriAvatar, sizeVw: sizeVw)),
        ),
      ],
    );
  }
}

/// Text field in the onboarding's language: white surface, navy focus ring,
/// error message under the field instead of a red bar at the bottom of the app.
class AuthField extends StatefulWidget {
  const AuthField({
    super.key,
    required this.controller,
    required this.hint,
    this.icon,
    this.error,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.autofillHints,
    this.textCapitalization = TextCapitalization.none,
    this.autocorrect = true,
    this.focusNode,
    this.onSubmitted,
    this.onChanged,
    this.trailing,
    this.maxLength,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final String? error;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final List<String>? autofillHints;
  final TextCapitalization textCapitalization;
  final bool autocorrect;
  final FocusNode? focusNode;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? trailing;
  final int? maxLength;
  final bool autofocus;

  @override
  State<AuthField> createState() => _AuthFieldState();
}

class _AuthFieldState extends State<AuthField> {
  late final FocusNode _node = widget.focusNode ?? FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _node.addListener(_onFocus);
  }

  void _onFocus() {
    if (mounted) setState(() => _focused = _node.hasFocus);
  }

  @override
  void dispose() {
    _node.removeListener(_onFocus);
    if (widget.focusNode == null) _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.error != null;
    final radius = BorderRadius.circular(context.vw(4.2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: RyzeCurves.out,
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: radius,
            border: Border.all(
              color: hasError ? kAuthDanger : (_focused ? RyzeColors.ink : RyzeColors.line),
              width: hasError || _focused ? 2 : 1,
            ),
            boxShadow: [
              if (_focused && !hasError)
                BoxShadow(color: RyzeColors.ink.withValues(alpha: 0.10), blurRadius: context.vw(3), offset: Offset(0, context.vw(0.8))),
            ],
          ),
          child: Row(
            children: [
              if (widget.icon != null)
                Padding(
                  padding: EdgeInsets.only(left: context.vw(4.2)),
                  child: Icon(widget.icon, size: context.vw(4.6), color: _focused ? RyzeColors.ink : RyzeColors.mute2),
                ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _node,
                  autofocus: widget.autofocus,
                  obscureText: widget.obscure,
                  keyboardType: widget.keyboardType,
                  textInputAction: widget.textInputAction,
                  autofillHints: widget.autofillHints,
                  textCapitalization: widget.textCapitalization,
                  autocorrect: widget.autocorrect,
                  enableSuggestions: widget.autocorrect,
                  maxLength: widget.maxLength,
                  onSubmitted: widget.onSubmitted,
                  onChanged: widget.onChanged,
                  onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                  scrollPadding: EdgeInsets.only(bottom: context.vh(18)),
                  cursorColor: RyzeColors.ink,
                  style: RyzeText.body(context, 4.1, weight: FontWeight.w500),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: RyzeText.body(context, 4.1, color: RyzeColors.mute2),
                    counterText: '',
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: context.vw(widget.icon == null ? 4.4 : 3),
                      vertical: context.vw(4),
                    ),
                  ),
                ),
              ),
              if (widget.trailing != null) Padding(padding: EdgeInsets.only(right: context.vw(2)), child: widget.trailing),
            ],
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: RyzeCurves.out,
          alignment: Alignment.topLeft,
          child: hasError
              ? Padding(
                  padding: EdgeInsets.only(top: context.vw(1.6), left: context.vw(1.6)),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(LucideIcons.circleAlert, size: context.vw(3.6), color: kAuthDanger),
                      SizedBox(width: context.vw(1.4)),
                      Expanded(
                        child: Text(widget.error!, style: RyzeText.body(context, 3.3, weight: FontWeight.w500, color: kAuthDanger, height: 1.3)),
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// Password visibility toggle, sized for the field.
class AuthEyeButton extends StatelessWidget {
  const AuthEyeButton({super.key, required this.obscured, required this.onTap});
  final bool obscured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.all(context.vw(2.4)),
        child: Icon(
          obscured ? LucideIcons.eye : LucideIcons.eyeOff,
          size: context.vw(5),
          color: RyzeColors.mute,
        ),
      ),
    );
  }
}

/// Apple and Google keep their brand shell (Apple's guidelines leave no room
/// for a navy pill), but take the onboarding's radius, height and type.
class AuthSocialButton extends StatefulWidget {
  const AuthSocialButton({super.key, required this.provider, required this.label, this.onPressed});

  final String provider; // 'apple' | 'google'
  final String label;
  final VoidCallback? onPressed;

  @override
  State<AuthSocialButton> createState() => _AuthSocialButtonState();
}

class _AuthSocialButtonState extends State<AuthSocialButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final isApple = widget.provider == 'apple';
    final enabled = widget.onPressed != null;
    final bg = isApple ? Colors.black : RyzeColors.surf;
    final fg = isApple ? Colors.white : const Color(0xFF3C4043);

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapUp: enabled ? (_) => setState(() => _down = false) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _down ? 0.975 : 1,
        duration: const Duration(milliseconds: 180),
        curve: RyzeCurves.spring,
        child: AnimatedOpacity(
          opacity: enabled ? 1 : 0.35,
          duration: const Duration(milliseconds: 250),
          child: Container(
            constraints: BoxConstraints(minHeight: context.vw(14)),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
              border: isApple ? null : Border.all(color: RyzeColors.line),
              boxShadow: [
                BoxShadow(
                  color: RyzeColors.ink.withValues(alpha: isApple ? 0.28 : 0.07),
                  blurRadius: context.vw(3.4),
                  offset: Offset(0, context.vw(1.1)),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isApple)
                  FaIcon(FontAwesomeIcons.apple, size: context.vw(5), color: Colors.white)
                else
                  SvgPicture.asset('assets/images/google_logo.svg', width: context.vw(5), height: context.vw(5)),
                SizedBox(width: context.vw(2.6)),
                Flexible(
                  child: Text(
                    widget.label,
                    style: RyzeText.body(context, 4.1, weight: FontWeight.w600, color: fg, height: 1.2),
                    textAlign: TextAlign.center,
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

/// Primary action of an auth screen: the onboarding pill, navy, with the
/// spinner inside it. Never gold — the amber button belongs to the trial.
class AuthCta extends StatelessWidget {
  const AuthCta({super.key, required this.label, required this.loading, this.onPressed});

  final String label;
  final bool loading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        AnimatedOpacity(
          opacity: loading ? 0.45 : 1,
          duration: const Duration(milliseconds: 200),
          child: OnbButton(label: label, onPressed: loading ? null : onPressed),
        ),
        if (loading)
          SizedBox(
            width: context.vw(5.6),
            height: context.vw(5.6),
            child: const CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          ),
      ],
    );
  }
}

/// "ou" between the providers and the email form.
class AuthDivider extends StatelessWidget {
  const AuthDivider({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final line = Expanded(child: Container(height: 1, color: RyzeColors.line));
    return Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.vw(3.4)),
          child: Text(label, style: RyzeText.body(context, 3.3, weight: FontWeight.w500, color: RyzeColors.mute)),
        ),
        line,
      ],
    );
  }
}

/// Consent under the buttons, with links that actually open. Replaces the
/// checkbox: the same sentence now covers Apple and Google too, which the
/// checkbox never did.
class AuthConsent extends StatefulWidget {
  const AuthConsent({super.key, required this.lang});
  final String lang;

  @override
  State<AuthConsent> createState() => _AuthConsentState();
}

class _AuthConsentState extends State<AuthConsent> {
  final _terms = TapGestureRecognizer();
  final _privacy = TapGestureRecognizer();

  @override
  void initState() {
    super.initState();
    _terms.onTap = () => openLegal(legalUrl(lang: widget.lang, terms: true));
    _privacy.onTap = () => openLegal(legalUrl(lang: widget.lang, terms: false));
  }

  @override
  void dispose() {
    _terms.dispose();
    _privacy.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = RyzeText.body(context, 3.1, color: RyzeColors.mute, height: 1.4);
    final link = base.copyWith(
      color: RyzeColors.ink,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
      decorationColor: RyzeColors.line,
    );
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: 'auth.consentPrefix'.tr(widget.lang)),
          TextSpan(text: 'auth.consentTerms'.tr(widget.lang), style: link, recognizer: _terms),
          TextSpan(text: 'auth.consentAnd'.tr(widget.lang)),
          TextSpan(text: 'auth.consentPrivacy'.tr(widget.lang), style: link, recognizer: _privacy),
          const TextSpan(text: '.'),
        ],
      ),
      style: base,
      textAlign: TextAlign.center,
    );
  }
}

/// Server error above the button: visible without covering the CTA, and it
/// leaves when the user edits the form.
class AuthBanner extends StatelessWidget {
  const AuthBanner({super.key, required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return PopIn(
      dy: 8,
      duration: const Duration(milliseconds: 320),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: context.vw(4), vertical: context.vw(3.2)),
        decoration: BoxDecoration(
          color: kAuthDanger.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(context.vw(4.2)),
          border: Border.all(color: kAuthDanger.withValues(alpha: 0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.circleAlert, size: context.vw(4.4), color: kAuthDanger),
            SizedBox(width: context.vw(2.4)),
            Expanded(
              child: Text(message, style: RyzeText.body(context, 3.5, weight: FontWeight.w500, color: kAuthDanger, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Tu as déjà un compte ? Se connecter" and its mirror.
class AuthSwitchLine extends StatelessWidget {
  const AuthSwitchLine({super.key, required this.question, required this.action, required this.onTap});

  final String question;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(2)),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(text: '$question '),
              TextSpan(
                text: action,
                style: RyzeText.body(context, 3.6, weight: FontWeight.w700, color: RyzeColors.ink),
              ),
            ],
          ),
          style: RyzeText.body(context, 3.6, weight: FontWeight.w500, color: RyzeColors.mute),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
