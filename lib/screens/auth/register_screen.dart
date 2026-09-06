import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../design/design.dart';
import '../../pages/ryze_app.dart';
import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import 'auth_kit.dart';
import 'login_screen.dart';

/// Create an account: two providers, or two fields.
///
/// The name is no longer asked here — a coach asks for it in the first chapter,
/// where it means something. A successful sign-up walks straight into the
/// onboarding; it never sends the user back to a login form.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordNode = FocusNode();

  bool _obscure = true;
  String? _emailError;
  String? _passwordError;
  String? _banner;

  @override
  void initState() {
    super.initState();
    AnalyticsService.logEvent('auth_screen_view', parameters: {'screen': 'register'});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordNode.dispose();
    super.dispose();
  }

  String get _lang => Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;

  void _clearErrors() {
    if (_emailError == null && _passwordError == null && _banner == null) return;
    setState(() {
      _emailError = null;
      _passwordError = null;
      _banner = null;
    });
  }

  bool _validate() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    String? emailError;
    String? passwordError;

    if (email.isEmpty) {
      emailError = 'register.emailRequired'.tr(_lang);
    } else if (!isValidEmail(email)) {
      emailError = 'register.emailInvalid'.tr(_lang);
    }
    if (password.isEmpty) {
      passwordError = 'register.passwordRequired'.tr(_lang);
    } else if (password.length < 8) {
      passwordError = 'register.passwordMinLength'.tr(_lang);
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _banner = null;
    });
    return emailError == null && passwordError == null;
  }

  /// The session created by the sign-up is used as it is: RyzeApp routes to
  /// the onboarding. Only a project with email confirmation turned on lands in
  /// the `else`, and then the message says exactly that.
  Future<void> _enterApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_logged_in_before', true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RyzeApp()),
      (route) => false,
    );
  }

  Future<void> _handleRegister() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) {
      HapticService.instance.lightImpact();
      return;
    }

    AnalyticsService.logEvent('sign_up_started', parameters: {'method': 'email'});
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (success && authService.isAuthenticated) {
      HapticService.instance.mediumImpact();
      AnalyticsService.logEvent('sign_up_succeeded', parameters: {'method': 'email'});
      await _enterApp();
      return;
    }

    if (success) {
      // account created, no session: the project asks for a confirmation email
      AnalyticsService.logEvent('sign_up_succeeded', parameters: {'method': 'email', 'needs_confirmation': 1});
      setState(() => _banner = 'auth.confirmEmailSent'.tr(_lang));
      return;
    }

    AnalyticsService.logEvent('sign_up_failed', parameters: {'method': 'email', 'reason': authService.errorMessage ?? 'unknown'});
    HapticService.instance.lightImpact();
    setState(() => _banner = (authService.errorMessage ?? 'register.registrationFailed').tr(_lang));
  }

  Future<void> _handleSocial(String provider) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    AnalyticsService.logEvent('sign_up_started', parameters: {'method': provider});
    final success = provider == 'apple' ? await authService.signInWithApple() : await authService.signInWithGoogle();
    if (!mounted) return;

    if (success) {
      HapticService.instance.mediumImpact();
      AnalyticsService.logEvent('sign_up_succeeded', parameters: {'method': provider});
      await _enterApp();
      return;
    }

    final reason = authService.errorMessage;
    AnalyticsService.logEvent('sign_up_failed', parameters: {'method': provider, 'reason': reason ?? 'unknown'});
    // a cancelled sheet is not an error worth a red panel
    if (reason == 'auth_error_apple_cancelled' || reason == 'auth_error_google_cancelled') return;
    setState(() => _banner = (reason ?? 'register.${provider}Failed').tr(_lang));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, LocalizationService>(
      builder: (context, authService, locService, _) {
        final lang = locService.currentLanguageCode;
        final busy = authService.isLoading;
        return AuthScaffold(
          onBack: Navigator.of(context).canPop() ? () => Navigator.of(context).pop() : null,
          children: [
            SizedBox(height: context.vh(1.2)),
            const PopIn(delay: Duration(milliseconds: 120), child: AuthCoaches()),
            SizedBox(height: context.vh(2.2)),
            AuthTitle('auth.createTitle'.tr(lang)),
            SizedBox(height: context.vh(1.2)),
            PopIn(
              delay: const Duration(milliseconds: 380),
              dy: 8,
              child: Text(
                'auth.createSubtitle'.tr(lang),
                style: RyzeText.body(context, 3.9, color: RyzeColors.mute, height: 1.45),
              ),
            ),
            SizedBox(height: context.vh(3)),
            PopIn(
              delay: const Duration(milliseconds: 480),
              child: AuthSocialButton(
                provider: 'apple',
                label: 'auth.continueApple'.tr(lang),
                onPressed: busy ? null : () => _handleSocial('apple'),
              ),
            ),
            SizedBox(height: context.vw(3)),
            PopIn(
              delay: const Duration(milliseconds: 550),
              child: AuthSocialButton(
                provider: 'google',
                label: 'auth.continueGoogle'.tr(lang),
                onPressed: busy ? null : () => _handleSocial('google'),
              ),
            ),
            SizedBox(height: context.vh(2.6)),
            PopIn(delay: const Duration(milliseconds: 620), child: AuthDivider(label: 'auth.orEmail'.tr(lang))),
            SizedBox(height: context.vh(2.2)),
            AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PopIn(
                    delay: const Duration(milliseconds: 690),
                    child: AuthField(
                      controller: _emailController,
                      hint: 'register.email'.tr(lang),
                      icon: LucideIcons.atSign,
                      error: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email, AutofillHints.newUsername],
                      autocorrect: false,
                      onChanged: (_) => _clearErrors(),
                      onSubmitted: (_) => _passwordNode.requestFocus(),
                    ),
                  ),
                  SizedBox(height: context.vw(3)),
                  PopIn(
                    delay: const Duration(milliseconds: 750),
                    child: AuthField(
                      controller: _passwordController,
                      focusNode: _passwordNode,
                      hint: 'auth.passwordHint'.tr(lang),
                      icon: LucideIcons.lock,
                      error: _passwordError,
                      obscure: _obscure,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onChanged: (_) => _clearErrors(),
                      onSubmitted: (_) => _handleRegister(),
                      trailing: AuthEyeButton(
                        obscured: _obscure,
                        onTap: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_banner != null) ...[
              SizedBox(height: context.vh(2)),
              AuthBanner(message: _banner!),
            ],
            SizedBox(height: context.vh(2.6)),
            PopIn(
              delay: const Duration(milliseconds: 820),
              child: AuthCta(
                label: 'auth.createCta'.tr(lang),
                loading: busy,
                onPressed: _handleRegister,
              ),
            ),
            SizedBox(height: context.vh(1.8)),
            PopIn(delay: const Duration(milliseconds: 880), child: AuthConsent(lang: lang)),
            SizedBox(height: context.vh(2.4)),
            PopIn(
              delay: const Duration(milliseconds: 940),
              child: AuthSwitchLine(
                question: 'auth.haveAccount'.tr(lang),
                action: 'register.signIn'.tr(lang),
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
                  }
                },
              ),
            ),
            SizedBox(height: context.vh(1)),
          ],
        );
      },
    );
  }
}
