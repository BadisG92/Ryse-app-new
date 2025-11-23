import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/global_state_manager.dart';
import '../services/header_cache_service.dart';
import 'auth/login_screen.dart';

/// Écran de suppression de compte (OBLIGATOIRE Apple App Store)
///
/// Selon la guideline App Store Review 5.1.1:
/// "Apps that allow for account creation must also allow users to initiate
/// deletion of their account from within the app"
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  // Couleurs de l'app
  static const Color _primaryDark = Color(0xFF0B132B);
  static const Color _secondary = Color(0xFF1C2951);
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _warningRed = Color(0xFFDC2626); // Rouge plus sombre et professionnel

  final _confirmationController = TextEditingController();
  bool _isDeleting = false;
  bool _confirmChecked = false;
  bool _understandChecked = false;

  @override
  void dispose() {
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    final locService = LocalizationService.instance;
    final lang = locService.currentLanguageCode;

    // Vérifications de sécurité
    if (!_confirmChecked || !_understandChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('confirm_checkboxes_required'.tr(lang)),
          backgroundColor: _secondary,
        ),
      );
      return;
    }

    if (_confirmationController.text.toUpperCase() != 'DELETE') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('type_delete_to_confirm'.tr(lang)),
          backgroundColor: _warningRed,
        ),
      );
      return;
    }

    // Dialog de confirmation finale
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: _borderColor),
        ),
        title: Row(
          children: [
            Icon(LucideIcons.triangleAlert, color: _warningRed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'final_confirmation'.tr(lang),
                style: const TextStyle(
                  fontSize: 18,
                  color: _primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'final_confirmation_message'.tr(lang),
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: _secondary),
            child: Text('cancel'.tr(lang)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _warningRed,
              foregroundColor: Colors.white,
            ),
            child: Text('delete_permanently'.tr(lang)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;
      final accessToken = supabase.auth.currentSession?.accessToken;

      if (userId == null || accessToken == null) {
        throw Exception('User not authenticated');
      }

      // Étape 1: Appeler l'Edge Function pour suppression complète
      // Cette fonction supprime:
      // - public.users (avec CASCADE sur toutes les données)
      // - auth.users (compte d'authentification)
      debugPrint('🗑️ Suppression complète du compte utilisateur: $userId');

      final response = await supabase.functions.invoke(
        'delete-user',
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.status != 200) {
        final errorData = response.data;
        throw Exception(errorData?['error'] ?? 'Failed to delete account');
      }

      debugPrint('✅ Compte utilisateur complètement supprimé (public.users + auth.users)');

      // Étape 2: Déconnexion locale (le compte auth n'existe plus)
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signOut();

      // Réinitialiser les caches
      GlobalStateManager.instance.reset();
      HeaderCacheService.clearCache();

      if (mounted) {
        // Afficher un message de succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('account_deleted_success'.tr(lang)),
            backgroundColor: _secondary,
            duration: const Duration(seconds: 3),
          ),
        );

        // Retour à la page de login
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression du compte: $e');

      if (mounted) {
        setState(() => _isDeleting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('error_deleting_account'.tr(lang)),
            backgroundColor: _warningRed,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final lang = locService.currentLanguageCode;

        return Scaffold(
          backgroundColor: _lightBackground,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(LucideIcons.chevronLeft, color: _primaryDark),
              onPressed: _isDeleting ? null : () => Navigator.pop(context),
            ),
            title: Text(
              'delete_account'.tr(lang),
              style: const TextStyle(
                color: _primaryDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: _borderColor,
              ),
            ),
          ),
          body: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Avertissement principal
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _warningRed.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _warningRed.withOpacity(0.3), width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        LucideIcons.triangleAlert,
                        color: _warningRed,
                        size: 48,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'delete_account_warning'.tr(lang),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _warningRed,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'delete_account_warning_desc'.tr(lang),
                        style: TextStyle(
                          fontSize: 14,
                          color: _primaryDark,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Ce qui sera supprimé
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              LucideIcons.trash2,
                              color: _secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'data_to_be_deleted'.tr(lang),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildDataItem(LucideIcons.user, 'profile_data'.tr(lang)),
                      _buildDataItem(LucideIcons.utensils, 'nutrition_data'.tr(lang)),
                      _buildDataItem(LucideIcons.dumbbell, 'workout_data'.tr(lang)),
                      _buildDataItem(LucideIcons.target, 'goals_data'.tr(lang)),
                      _buildDataItem(LucideIcons.trendingUp, 'progress_data'.tr(lang)),
                      _buildDataItem(LucideIcons.heart, 'health_data'.tr(lang)),
                      _buildDataItem(LucideIcons.trophy, 'achievements_data'.tr(lang)),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _secondary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.info,
                              color: _secondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'subscription_info'.tr(lang),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _primaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Confirmations
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'confirm_deletion'.tr(lang),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _primaryDark,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Checkbox 1: Comprendre la permanence
                      CheckboxListTile(
                        value: _understandChecked,
                        onChanged: _isDeleting
                            ? null
                            : (value) {
                                setState(() => _understandChecked = value ?? false);
                              },
                        title: Text(
                          'understand_permanent'.tr(lang),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _secondary,
                      ),

                      // Checkbox 2: Accepter la perte de données
                      CheckboxListTile(
                        value: _confirmChecked,
                        onChanged: _isDeleting
                            ? null
                            : (value) {
                                setState(() => _confirmChecked = value ?? false);
                              },
                        title: Text(
                          'accept_data_loss'.tr(lang),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        controlAffinity: ListTileControlAffinity.leading,
                        contentPadding: EdgeInsets.zero,
                        activeColor: _secondary,
                      ),

                      const SizedBox(height: 16),

                      // Champ de confirmation
                      Text(
                        'type_delete_to_confirm_label'.tr(lang),
                        style: const TextStyle(
                          fontSize: 14,
                          color: _primaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _confirmationController,
                        enabled: !_isDeleting,
                        decoration: InputDecoration(
                          hintText: 'DELETE',
                          hintStyle: TextStyle(color: Colors.grey.shade400),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _warningRed, width: 2),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _warningRed.withOpacity(0.3), width: 2),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: _warningRed, width: 2),
                          ),
                          filled: true,
                          fillColor: _lightBackground,
                        ),
                        textCapitalization: TextCapitalization.characters,
                        style: const TextStyle(
                          color: _primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Bouton de suppression
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isDeleting ? null : _deleteAccount,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _warningRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isDeleting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(LucideIcons.trash2, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'delete_my_account'.tr(lang),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
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

  Widget _buildDataItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: _secondary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Icon(LucideIcons.x, color: _warningRed, size: 16),
        ],
      ),
    );
  }
}
