import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

/// Écran pour compléter le profil après un login social
/// Affiché uniquement si le nom n'a pas pu être récupéré depuis le provider
class CompleteProfileScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const CompleteProfileScreen({
    Key? key,
    required this.onComplete,
  }) : super(key: key);

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.updateProfile(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (success && mounted) {
      widget.onComplete();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            authService.errorMessage ?? 'Failed to update profile',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Consumer<AuthService>(
          builder: (context, authService, child) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 40),

                  // Icon de profil
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0B132B).withOpacity(0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_outline,
                        size: 50,
                        color: Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Titre
                  Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'complete_profile_title'.tr(locService.currentLanguageCode),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Sous-titre
                  Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'complete_profile_subtitle'.tr(locService.currentLanguageCode),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Formulaire
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Consumer<LocalizationService>(
                          builder: (context, locService, _) => CustomTextField(
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
                        const SizedBox(height: 16),
                        Consumer<LocalizationService>(
                          builder: (context, locService, _) => CustomTextField(
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
                  ),

                  const SizedBox(height: 32),

                  // Bouton continuer
                  Consumer<LocalizationService>(
                    builder: (context, locService, _) => CustomButton(
                      text: 'continue'.tr(locService.currentLanguageCode),
                      onPressed: authService.isLoading ? null : _handleSubmit,
                      isLoading: authService.isLoading,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Note de confidentialité
                  Consumer<LocalizationService>(
                    builder: (context, locService, _) => Text(
                      'complete_profile_privacy'.tr(locService.currentLanguageCode),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
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
