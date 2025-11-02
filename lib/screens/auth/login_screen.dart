import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_login_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import '../../pages/ryze_app.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isReturningUser = false;

  @override
  void initState() {
    super.initState();
    _checkIfReturningUser();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkIfReturningUser() async {
    final prefs = await SharedPreferences.getInstance();
    // Vérifier s'il y a une indication qu'un utilisateur s'est déjà connecté
    final hasLoggedInBefore = prefs.getBool('has_logged_in_before') ?? false;
    setState(() {
      _isReturningUser = hasLoggedInBefore;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      // Marquer que l'utilisateur s'est connecté
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_logged_in_before', true);

      // Laisser RyzeApp gérer le routing automatique (onboarding ou app)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RyzeApp()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'login_failed'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithGoogle();

    if (success && mounted) {
      // Laisser RyzeApp gérer le routing automatique (onboarding ou app)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RyzeApp()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'google_login_failed'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAppleLogin() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithApple();

    if (success && mounted) {
      // Laisser RyzeApp gérer le routing automatique (onboarding ou app)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RyzeApp()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'apple_login_failed'.tr(Provider.of<LocalizationService>(context, listen: false).currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fond gris cohérent avec onboarding
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Logo + Nom Ryze
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo carré avec dégradé
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: SvgPicture.asset(
                              'assets/images/logo_solo.svg',
                              width: 28,
                              height: 28,
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Nom "Ryze"
                        const Text(
                          'Ryze',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0B132B),
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Titre principal
                  Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      (_isReturningUser ? 'welcome_back' : 'welcome').tr(locService.currentLanguageCode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B132B),
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // 🔥 SOCIAL LOGINS EN PREMIER - PRIORITÉ
                  SocialLoginButton(
                    provider: 'apple',
                    isLarge: true,
                    onPressed: authService.isLoading ? null : _handleAppleLogin,
                  ),

                  const SizedBox(height: 12),

                  SocialLoginButton(
                    provider: 'google',
                    isLarge: true,
                    onPressed: authService.isLoading ? null : _handleGoogleLogin,
                  ),

                  const SizedBox(height: 32),

                  // Divider subtil
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => Text(
                            'or_continue_with'.tr(locService.currentLanguageCode),
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Login Form - Secondaire et discret
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Consumer<LocalizationService>(
                          builder: (context, locService, _) => CustomTextField(
                            controller: _emailController,
                            label: 'email'.tr(locService.currentLanguageCode),
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'enter_email'.tr(locService.currentLanguageCode);
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'enter_valid_email'.tr(locService.currentLanguageCode);
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Consumer<LocalizationService>(
                          builder: (context, locService, _) => CustomTextField(
                            controller: _passwordController,
                            label: 'password'.tr(locService.currentLanguageCode),
                          obscureText: _obscurePassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'enter_password'.tr(locService.currentLanguageCode);
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 4),

                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: Consumer<LocalizationService>(
                              builder: (context, locService, _) => Text(
                                'forgot_password'.tr(locService.currentLanguageCode),
                                style: const TextStyle(
                                  color: Color(0xFF0B132B),
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Login Button
                        Consumer<LocalizationService>(
                          builder: (context, locService, _) => CustomButton(
                            text: 'sign_in'.tr(locService.currentLanguageCode),
                            onPressed: authService.isLoading ? null : _handleLogin,
                            isLoading: authService.isLoading,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'dont_have_account'.tr(locService.currentLanguageCode),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RegisterScreen(),
                            ),
                          );
                        },
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => Text(
                            'sign_up'.tr(locService.currentLanguageCode),
                            style: const TextStyle(
                              color: Color(0xFF0B132B),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 