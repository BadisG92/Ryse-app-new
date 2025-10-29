import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../services/auth_service.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/social_login_button.dart';
import '../../pages/ryze_app.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('register.pleaseAcceptTerms'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (success && mounted) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('register.successMessage'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Navigate back to login
      Navigator.of(context).pop();
    } else if (mounted) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'register.registrationFailed'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGoogleRegister() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithGoogle();

    if (success && mounted) {
      // Laisser RyzeApp gérer le routing automatique (onboarding ou app)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RyzeApp()),
      );
    } else if (mounted) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'register.googleFailed'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleAppleRegister() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.signInWithApple();

    if (success && mounted) {
      // Laisser RyzeApp gérer le routing automatique (onboarding ou app)
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const RyzeApp()),
      );
    } else if (mounted) {
      final locService = Provider.of<LocalizationService>(context, listen: false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authService.errorMessage ?? 'register.appleFailed'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Fond gris cohérent avec onboarding
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0B132B)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Consumer2<AuthService, LocalizationService>(
          builder: (context, authService, locService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                  Text(
                    'register.title'.tr(locService.currentLanguageCode),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0B132B),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 40),
                  
                  // Registration Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: CustomTextField(
                                controller: _firstNameController,
                                label: 'register.firstName'.tr(locService.currentLanguageCode),
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'register.firstNameRequired'.tr(locService.currentLanguageCode);
                                  }
                                  if (value.length < 2) {
                                    return 'register.nameMinLength'.tr(locService.currentLanguageCode);
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: CustomTextField(
                                controller: _lastNameController,
                                label: 'register.lastName'.tr(locService.currentLanguageCode),
                                prefixIcon: Icons.person_outline,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'register.lastNameRequired'.tr(locService.currentLanguageCode);
                                  }
                                  if (value.length < 2) {
                                    return 'register.nameMinLength'.tr(locService.currentLanguageCode);
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _emailController,
                          label: 'register.email'.tr(locService.currentLanguageCode),
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.email_outlined,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'register.emailRequired'.tr(locService.currentLanguageCode);
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                              return 'register.emailInvalid'.tr(locService.currentLanguageCode);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _passwordController,
                          label: 'register.password'.tr(locService.currentLanguageCode),
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
                              return 'register.passwordRequired'.tr(locService.currentLanguageCode);
                            }
                            if (value.length < 8) {
                              return 'register.passwordMinLength'.tr(locService.currentLanguageCode);
                            }
                            if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
                              return 'register.passwordComplexity'.tr(locService.currentLanguageCode);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _confirmPasswordController,
                          label: 'register.confirmPassword'.tr(locService.currentLanguageCode),
                          obscureText: _obscureConfirmPassword,
                          prefixIcon: Icons.lock_outline,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'register.confirmPasswordRequired'.tr(locService.currentLanguageCode);
                            }
                            if (value != _passwordController.text) {
                              return 'register.passwordsDoNotMatch'.tr(locService.currentLanguageCode);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        
                        // Terms and Conditions
                        Row(
                          children: [
                            Checkbox(
                              value: _acceptTerms,
                              onChanged: (value) {
                                setState(() {
                                  _acceptTerms = value ?? false;
                                });
                              },
                              activeColor: const Color(0xFF0B132B),
                            ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  children: [
                                    TextSpan(text: 'register.iAgreeTo'.tr(locService.currentLanguageCode)),
                                    TextSpan(
                                      text: 'register.termsOfService'.tr(locService.currentLanguageCode),
                                      style: const TextStyle(
                                        color: Color(0xFF0B132B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    TextSpan(text: 'register.and'.tr(locService.currentLanguageCode)),
                                    TextSpan(
                                      text: 'register.privacyPolicy'.tr(locService.currentLanguageCode),
                                      style: const TextStyle(
                                        color: Color(0xFF0B132B),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 24),

                        // Register Button
                        CustomButton(
                          text: 'register.createAccount'.tr(locService.currentLanguageCode),
                          onPressed: authService.isLoading ? null : _handleRegister,
                          isLoading: authService.isLoading,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'register.orSignUpWith'.tr(locService.currentLanguageCode),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),

                  const SizedBox(height: 24),
                  
                  // Social Registration Buttons
                  Row(
                    children: [
                      Expanded(
                        child: SocialLoginButton(
                          icon: 'assets/icons/google.png',
                          label: 'Google',
                          onPressed: authService.isLoading ? null : _handleGoogleRegister,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SocialLoginButton(
                          icon: 'assets/icons/apple.png',
                          label: 'Apple',
                          onPressed: authService.isLoading ? null : _handleAppleRegister,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 28),

                  // Sign In Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'register.alreadyHaveAccount'.tr(locService.currentLanguageCode),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'register.signIn'.tr(locService.currentLanguageCode),
                          style: const TextStyle(
                            color: Color(0xFF0B132B),
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
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