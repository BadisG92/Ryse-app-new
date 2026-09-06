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
import 'forgot_password_screen.dart';
import 'register_screen.dart';

/// Sign in. Reached by someone who already has an account — from the account
/// screen, or straight at launch once this device has signed in before.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
    AnalyticsService.logEvent('auth_screen_view', parameters: {'screen': 'login'});
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
    String? emailError;
    String? passwordError;

    if (email.isEmpty) {
      emailError = 'enter_email'.tr(_lang);
    } else if (!isValidEmail(email)) {
      emailError = 'enter_valid_email'.tr(_lang);
    }
    if (_passwordController.text.isEmpty) {
      passwordError = 'enter_password'.tr(_lang);
    }

    setState(() {
      _emailError = emailError;
      _passwordError = passwordError;
      _banner = null;
    });
    return emailError == null && passwordError == null;
  }

  Future<void> _enterApp() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_logged_in_before', true);
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const RyzeApp()),
      (route) => false,
    );
  }

  Future<void> _handleLogin() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!_validate()) {
      HapticService.instance.lightImpact();
      return;
    }

    AnalyticsService.logEvent('sign_in_started', parameters: {'method': 'email'});
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return;

    if (success) {
      HapticService.instance.mediumImpact();
      await _enterApp();
      return;
    }

    AnalyticsService.logEvent('sign_in_failed', parameters: {'method': 'email', 'reason': authService.errorMessage ?? 'unknown'});
    HapticService.instance.lightImpact();
    setState(() => _banner = (authService.errorMessage ?? 'login_failed').tr(_lang));
  }

  Future<void> _handleSocial(String provider) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    AnalyticsService.logEvent('sign_in_started', parameters: {'method': provider});
    final success = provider == 'apple' ? await authService.signInWithApple() : await authService.signInWithGoogle();
    if (!mounted) return;

    if (success) {
      HapticService.instance.mediumImpact();
      await _enterApp();
      return;
    }

    final reason = authService.errorMessage;
    AnalyticsService.logEvent('sign_in_failed', parameters: {'method': provider, 'reason': reason ?? 'unknown'});
    if (reason == 'auth_error_apple_cancelled' || reason == 'auth_error_google_cancelled') return;
    setState(() => _banner = (reason ?? '${provider}_login_failed').tr(_lang));
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
            AuthTitle('auth.loginTitle'.tr(lang)),
            SizedBox(height: context.vh(1.2)),
            PopIn(
              delay: const Duration(milliseconds: 380),
              dy: 8,
              child: Text(
                'auth.loginSubtitle'.tr(lang),
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
                      hint: 'email'.tr(lang),
                      icon: LucideIcons.atSign,
                      error: _emailError,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.username, AutofillHints.email],
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
                      hint: 'password'.tr(lang),
                      icon: LucideIcons.lock,
                      error: _passwordError,
                      obscure: _obscure,
                      autocorrect: false,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.password],
                      onChanged: (_) => _clearErrors(),
                      onSubmitted: (_) => _handleLogin(),
                      trailing: AuthEyeButton(
                        obscured: _obscure,
                        onTap: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: context.vw(2)),
            PopIn(
              delay: const Duration(milliseconds: 790),
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: context.vw(1.6)),
                    child: Text(
                      'forgot_password'.tr(lang),
                      style: RyzeText.body(context, 3.5, weight: FontWeight.w600, color: RyzeColors.ink),
                    ),
                  ),
                ),
              ),
            ),
            if (_banner != null) ...[
              SizedBox(height: context.vh(1.4)),
              AuthBanner(message: _banner!),
            ],
            SizedBox(height: context.vh(2.2)),
            PopIn(
              delay: const Duration(milliseconds: 820),
              child: AuthCta(
                label: 'sign_in'.tr(lang),
                loading: busy,
                onPressed: _handleLogin,
              ),
            ),
            SizedBox(height: context.vh(1.8)),
            PopIn(delay: const Duration(milliseconds: 880), child: AuthConsent(lang: lang)),
            SizedBox(height: context.vh(2.4)),
            PopIn(
              delay: const Duration(milliseconds: 940),
              child: AuthSwitchLine(
                question: 'dont_have_account'.tr(lang),
                action: 'sign_up'.tr(lang),
                onTap: () {
                  if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop();
                  } else {
                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const RegisterScreen()));
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
