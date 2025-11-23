import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

/// Écran de gestion du compte (Mot de passe uniquement)
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isChangingPassword = false;
  bool _isSendingResetLink = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  String? _currentEmail;
  bool _isOAuthUser = false;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Vérifier si l'utilisateur utilise OAuth (Google, Apple)
      // Les utilisateurs OAuth n'ont pas de provider "email" dans leurs identités
      final identities = user.identities ?? [];
      final hasEmailProvider = identities.any((id) => id.provider == 'email');

      setState(() {
        _currentEmail = user.email;
        // Si pas de provider email, c'est un utilisateur OAuth
        _isOAuthUser = !hasEmailProvider && identities.isNotEmpty;
      });
    }
  }

  Future<void> _sendPasswordResetLink() async {
    final locService = LocalizationService.instance;
    final lang = locService.currentLanguageCode;

    if (_currentEmail == null) return;

    setState(() => _isSendingResetLink = true);

    try {
      debugPrint('📧 Sending password reset email to: $_currentEmail');

      await Supabase.instance.client.auth.resetPasswordForEmail(
        _currentEmail!,
        redirectTo: 'https://coach-ryze.com/reset-password', // Page web pour reset
      );

      debugPrint('✅ Password reset email sent successfully');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('reset_link_sent'.tr(lang)),
            backgroundColor: const Color(0xFF0B132B),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending password reset email: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${'error_sending_reset_link'.tr(lang)}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSendingResetLink = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    final locService = LocalizationService.instance;
    final lang = locService.currentLanguageCode;

    setState(() => _isChangingPassword = true);

    try {
      // Vérifier le mot de passe actuel en tentant de se reconnecter
      if (_currentEmail != null) {
        try {
          await Supabase.instance.client.auth.signInWithPassword(
            email: _currentEmail!,
            password: _currentPasswordController.text,
          );
        } catch (e) {
          if (mounted) {
            setState(() => _isChangingPassword = false);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('current_password_incorrect'.tr(lang)),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      // Changer le mot de passe
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('password_changed_success'.tr(lang)),
            backgroundColor: const Color(0xFF0B132B),
          ),
        );

        // Réinitialiser les champs
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_changing_password'.tr(lang)),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final lang = locService.currentLanguageCode;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0B132B),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'change_password'.tr(lang),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Message pour les utilisateurs OAuth (Google/Apple)
                if (_isOAuthUser)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.info,
                          color: Color(0xFFD97706),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'oauth_no_password'.tr(lang),
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF92400E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_isOAuthUser) const SizedBox(height: 8),

                // Section Mot de passe oublié (cachée pour OAuth)
                if (!_isOAuthUser)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B132B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              LucideIcons.mail,
                              color: Color(0xFF0B132B),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'forgot_password_title'.tr(lang),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'forgot_password_desc'.tr(lang),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSendingResetLink ? null : _sendPasswordResetLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0B132B),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isSendingResetLink
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('send_reset_link'.tr(lang)),
                        ),
                      ),
                    ],
                  ),
                ),

                if (!_isOAuthUser) const SizedBox(height: 24),

                // Section Changer le mot de passe (cachée pour OAuth)
                if (!_isOAuthUser)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B132B).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.lock,
                                color: Color(0xFF0B132B),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'change_password'.tr(lang),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Mot de passe actuel
                        TextFormField(
                          controller: _currentPasswordController,
                          obscureText: _obscureCurrentPassword,
                          decoration: InputDecoration(
                            labelText: 'current_password'.tr(lang),
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: const Icon(LucideIcons.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureCurrentPassword
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureCurrentPassword = !_obscureCurrentPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'field_required'.tr(lang);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Nouveau mot de passe
                        TextFormField(
                          controller: _newPasswordController,
                          obscureText: _obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'new_password'.tr(lang),
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: const Icon(LucideIcons.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureNewPassword
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureNewPassword = !_obscureNewPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'field_required'.tr(lang);
                            }
                            if (value.length < 6) {
                              return 'password_min_length'.tr(lang);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Confirmer le mot de passe
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'confirm_password'.tr(lang),
                            labelStyle: TextStyle(color: Colors.grey[600]),
                            prefixIcon: const Icon(LucideIcons.lock, size: 20),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? LucideIcons.eyeOff
                                    : LucideIcons.eye,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureConfirmPassword = !_obscureConfirmPassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8FAFC),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'field_required'.tr(lang);
                            }
                            if (value != _newPasswordController.text) {
                              return 'passwords_dont_match'.tr(lang);
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Bouton de confirmation
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isChangingPassword ? null : _changePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0B132B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: _isChangingPassword
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text('change_password'.tr(lang)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
