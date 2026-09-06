import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import 'auth_kit.dart';

/// Password reset. Same ground and same type as the rest of the flow — and,
/// unlike the screen it replaces, it speaks the three languages of the app.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sent = false;
  String? _emailError;
  String? _banner;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('auth_screen_view', parameters: {'screen': 'forgot_password'});
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String get _lang => Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;

  Future<void> _handleReset() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final email = _emailController.text.trim();
    if (email.isEmpty || !isValidEmail(email)) {
      HapticService.instance.lightImpact();
      setState(() => _emailError = (email.isEmpty ? 'enter_email' : 'enter_valid_email').tr(_lang));
      return;
    }
    setState(() {
      _emailError = null;
      _banner = null;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.resetPassword(email);
    if (!mounted) return;

    if (success) {
      HapticService.instance.mediumImpact();
      AnalyticsService.logEvent('password_reset_sent');
      setState(() => _sent = true);
      return;
    }
    setState(() => _banner = (authService.errorMessage ?? 'forgot.failed').tr(_lang));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, LocalizationService>(
      builder: (context, authService, locService, _) {
        final lang = locService.currentLanguageCode;
        return AuthScaffold(
          onBack: () => Navigator.of(context).pop(),
          children: _sent ? _sentBody(context, lang) : _formBody(context, lang, authService),
        );
      },
    );
  }

  List<Widget> _formBody(BuildContext context, String lang, AuthService authService) {
    return [
      SizedBox(height: context.vh(2)),
      const PopIn(delay: Duration(milliseconds: 120), child: AuthCoaches(sizeVw: 12)),
      SizedBox(height: context.vh(2.2)),
      AuthTitle('forgot.title'.tr(lang)),
      SizedBox(height: context.vh(1.2)),
      PopIn(
        delay: const Duration(milliseconds: 360),
        dy: 8,
        child: Text('forgot.subtitle'.tr(lang), style: RyzeText.body(context, 3.9, color: RyzeColors.mute, height: 1.45)),
      ),
      SizedBox(height: context.vh(3.4)),
      PopIn(
        delay: const Duration(milliseconds: 460),
        child: AuthField(
          controller: _emailController,
          hint: 'email'.tr(lang),
          icon: LucideIcons.atSign,
          error: _emailError,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.username, AutofillHints.email],
          autocorrect: false,
          onChanged: (_) {
            if (_emailError == null && _banner == null) return;
            setState(() {
              _emailError = null;
              _banner = null;
            });
          },
          onSubmitted: (_) => _handleReset(),
        ),
      ),
      if (_banner != null) ...[
        SizedBox(height: context.vh(2)),
        AuthBanner(message: _banner!),
      ],
      SizedBox(height: context.vh(3)),
      PopIn(
        delay: const Duration(milliseconds: 540),
        child: AuthCta(label: 'forgot.cta'.tr(lang), loading: authService.isLoading, onPressed: _handleReset),
      ),
    ];
  }

  List<Widget> _sentBody(BuildContext context, String lang) {
    return [
      SizedBox(height: context.vh(4)),
      PopIn(
        child: Container(
          width: context.vw(18),
          height: context.vw(18),
          decoration: BoxDecoration(
            color: RyzeColors.accTint,
            shape: BoxShape.circle,
            border: Border.all(color: RyzeColors.acc.withValues(alpha: 0.5)),
          ),
          child: Icon(LucideIcons.mailCheck, size: context.vw(9), color: RyzeColors.accInk),
        ),
      ),
      SizedBox(height: context.vh(2.6)),
      AuthTitle('forgot.sentTitle'.tr(lang)),
      SizedBox(height: context.vh(1.2)),
      PopIn(
        delay: const Duration(milliseconds: 320),
        dy: 8,
        child: Text(
          'forgot.sentBody'.tr(lang).replaceAll('{email}', _emailController.text.trim()),
          style: RyzeText.body(context, 3.9, color: RyzeColors.mute, height: 1.45),
        ),
      ),
      SizedBox(height: context.vh(4)),
      PopIn(
        delay: const Duration(milliseconds: 420),
        child: OnbButton(label: 'forgot.backToLogin'.tr(lang), onPressed: () => Navigator.of(context).pop()),
      ),
      SizedBox(height: context.vh(1.6)),
      PopIn(
        delay: const Duration(milliseconds: 480),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => setState(() => _sent = false),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: context.vw(2)),
            child: Text(
              'forgot.resend'.tr(lang),
              textAlign: TextAlign.center,
              style: RyzeText.body(context, 3.5, weight: FontWeight.w600, color: RyzeColors.ink),
            ),
          ),
        ),
      ),
    ];
  }
}
