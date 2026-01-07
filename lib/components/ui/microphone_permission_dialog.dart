import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

/// Dialog explaining microphone usage before requesting system permission
/// This helps users understand why we need the microphone and reduces fear
class MicrophonePermissionDialog {
  static const String _prefKey = 'microphone_permission_explained';

  /// Check if we've already shown the explanation dialog
  static Future<bool> hasShownExplanation() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  /// Mark that we've shown the explanation
  static Future<void> markExplanationShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, true);
  }

  /// Show the explanation dialog before requesting permission
  /// Returns true if user wants to continue, false if they declined
  /// Call this from a StatefulWidget and check mounted after awaiting
  static Future<bool> showExplanationIfNeeded(
    BuildContext context, {
    required bool Function() isMounted,
  }) async {
    // Check if we've already explained
    final hasShown = await hasShownExplanation();
    if (hasShown) return true;

    if (!isMounted()) return false;

    // Show explanation dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _MicrophoneExplanationDialog(),
    );

    if (result == true) {
      await markExplanationShown();
    }

    return result ?? false;
  }

  /// Force show the explanation dialog (for settings or retry)
  static Future<bool> showExplanation(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _MicrophoneExplanationDialog(),
    );

    return result ?? false;
  }
}

class _MicrophoneExplanationDialog extends StatelessWidget {
  const _MicrophoneExplanationDialog();

  @override
  Widget build(BuildContext context) {
    final lang = LocalizationService.instance.currentLanguageCode;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Microphone icon with friendly styling
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B132B).withValues(alpha: 0.1),
                    const Color(0xFF1C2951).withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.mic,
                size: 36,
                color: Color(0xFF0B132B),
              ),
            ),
            const SizedBox(height: 20),

            // Title
            Text(
              'mic_permission_title'.tr(lang),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0B132B),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Description
            Text(
              'mic_permission_description'.tr(lang),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF64748B),
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Features list
            _buildFeatureItem(
              icon: LucideIcons.messageCircle,
              text: 'mic_permission_feature_chat'.tr(lang),
            ),
            const SizedBox(height: 12),
            _buildFeatureItem(
              icon: LucideIcons.dumbbell,
              text: 'mic_permission_feature_workout'.tr(lang),
            ),
            const SizedBox(height: 24),

            // Privacy note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    LucideIcons.shieldCheck,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'mic_permission_privacy'.tr(lang),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Text(
                      'mic_permission_not_now'.tr(lang),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'mic_permission_continue'.tr(lang),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            size: 16,
            color: const Color(0xFF0B132B),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
