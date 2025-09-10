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
      
      Navigator.of(context).pushReplacementNamed('/main');
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
      Navigator.of(context).pushReplacementNamed('/main');
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
      Navigator.of(context).pushReplacementNamed('/main');
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  
                  // Logo and Welcome Text
                  Column(
                    children: [
                      // Logo Ryze propre et centré (même style que l'onboarding)
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF0B132B), // Bleu principal de l'app
                          boxShadow: [
                            // Ombre principale plus douce
                            BoxShadow(
                              color: const Color(0xFF0B132B).withOpacity(0.15),
                              blurRadius: 24,
                              spreadRadius: 0,
                              offset: const Offset(0, 8),
                            ),
                            // Ombre secondaire pour plus de profondeur
                            BoxShadow(
                              color: const Color(0xFF0B132B).withOpacity(0.08),
                              blurRadius: 12,
                              spreadRadius: -2,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: SvgPicture.asset(
                              'assets/images/logo_seul.svg',
                              colorFilter: const ColorFilter.mode(
                                Colors.white,
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          (_isReturningUser ? 'welcome_back' : 'welcome').tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'sign_in_subtitle'.tr(locService.currentLanguageCode),
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Login Form
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
                        const SizedBox(height: 16),
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
                        const SizedBox(height: 8),
                        
                        // Forgot Password
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
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
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
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
                  
                  const SizedBox(height: 32),
                  
                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Consumer<LocalizationService>(
                          builder: (context, locService, _) => Text(
                            'or_continue_with'.tr(locService.currentLanguageCode),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Social Login Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SocialLoginButton(
                          icon: 'assets/icons/google.png',
                          label: 'Google',
                          onPressed: authService.isLoading ? null : _handleGoogleLogin,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SocialLoginButton(
                          icon: 'assets/icons/apple.png',
                          label: 'Apple',
                          onPressed: authService.isLoading ? null : _handleAppleLogin,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'dont_have_account'.tr(locService.currentLanguageCode),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ),
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
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
} 