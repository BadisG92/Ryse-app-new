import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

/// Écran d'aide et support
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  // Couleurs de l'app
  static const Color _primaryDark = Color(0xFF0B132B);
  static const Color _secondary = Color(0xFF1C2951);
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _borderColor = Color(0xFFE2E8F0);

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _sendSupportEmail(BuildContext context, String lang) async {
    // Récupérer les infos système pour faciliter le debug
    final userId = 'USER_ID'; // TODO: Remplacer par le vrai User ID depuis AuthService
    final appVersion = '1.0.0'; // TODO: Utiliser package_info_plus pour récupérer la vraie version

    final subject = lang == 'fr' ? 'Support - Ryze' : 'Support - Ryze';
    final body = lang == 'fr'
        ? 'Bonjour,\n\nJe vous contacte concernant :\n\n[Décrivez votre problème ici]\n\n---\nInfos système (ne pas supprimer) :\nUser ID: $userId\nVersion: $appVersion\nPlateforme: iOS'
        : 'Hello,\n\nI am contacting you regarding:\n\n[Describe your issue here]\n\n---\nSystem info (do not delete):\nUser ID: $userId\nVersion: $appVersion\nPlatform: iOS';

    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@coach-ryze.com',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      // Essayer d'ouvrir l'app Mail native
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else {
        // Mail n'est pas configuré sur l'appareil
        if (context.mounted) {
          _showEmailNotConfiguredDialog(context, lang);
        }
      }
    } catch (e) {
      // Erreur lors de l'ouverture de Mail
      if (context.mounted) {
        _showEmailNotConfiguredDialog(context, lang);
      }
    }
  }

  Future<void> _sendBugReportEmail(BuildContext context, String lang) async {
    // Récupérer les infos système pour faciliter le debug
    final userId = 'USER_ID'; // TODO: Remplacer par le vrai User ID depuis AuthService
    final appVersion = '1.0.0'; // TODO: Utiliser package_info_plus pour récupérer la vraie version

    final subject = lang == 'fr' ? 'Bug - Ryze' : 'Bug - Ryze';
    final body = lang == 'fr'
        ? 'Bonjour,\n\nJe rencontre le bug suivant :\n\n[Décrivez le bug ici]\n\n---\nÉtapes pour reproduire :\n1. [Première étape]\n2. [Deuxième étape]\n3. [Troisième étape]\n\n---\nComportement attendu :\n[Ce qui devrait se passer]\n\n---\nComportement observé :\n[Ce qui se passe réellement]\n\n---\nInfos système (ne pas supprimer) :\nUser ID: $userId\nVersion: $appVersion\nPlateforme: iOS'
        : 'Hello,\n\nI am experiencing the following bug:\n\n[Describe the bug here]\n\n---\nSteps to reproduce:\n1. [First step]\n2. [Second step]\n3. [Third step]\n\n---\nExpected behavior:\n[What should happen]\n\n---\nObserved behavior:\n[What actually happens]\n\n---\nSystem info (do not delete):\nUser ID: $userId\nVersion: $appVersion\nPlatform: iOS';

    final emailUri = Uri(
      scheme: 'mailto',
      path: 'support@coach-ryze.com',
      query: 'subject=${Uri.encodeComponent(subject)}&body=${Uri.encodeComponent(body)}',
    );

    try {
      // Essayer d'ouvrir l'app Mail native
      final canLaunch = await canLaunchUrl(emailUri);
      if (canLaunch) {
        await launchUrl(emailUri);
      } else {
        // Mail n'est pas configuré sur l'appareil
        if (context.mounted) {
          _showEmailNotConfiguredDialog(context, lang);
        }
      }
    } catch (e) {
      // Erreur lors de l'ouverture de Mail
      if (context.mounted) {
        _showEmailNotConfiguredDialog(context, lang);
      }
    }
  }

  void _showEmailNotConfiguredDialog(BuildContext context, String lang) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          lang == 'fr' ? 'Mail non configuré' : 'Mail not configured',
          style: const TextStyle(
            color: _primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          lang == 'fr'
              ? 'L\'application Mail n\'est pas configurée sur votre appareil.\n\nVous pouvez copier notre adresse email et nous contacter via votre client email préféré.'
              : 'The Mail app is not configured on your device.\n\nYou can copy our email address and contact us via your preferred email client.',
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: Text(lang == 'fr' ? 'Annuler' : 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _copyEmail(context, lang);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _secondary,
              foregroundColor: Colors.white,
            ),
            child: Text(lang == 'fr' ? 'Copier l\'email' : 'Copy email'),
          ),
        ],
      ),
    );
  }

  void _copyEmail(BuildContext context, String lang) {
    Clipboard.setData(const ClipboardData(text: 'support@coach-ryze.com'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('email_copied'.tr(lang)),
        backgroundColor: _secondary,
        duration: const Duration(seconds: 2),
      ),
    );
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
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'help_support'.tr(lang),
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

                // En-tête
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          LucideIcons.headset,
                          color: _secondary,
                          size: 48,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'help_support_title'.tr(lang),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'help_support_subtitle'.tr(lang),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contact rapide
                _buildSection(
                  context,
                  lang,
                  icon: LucideIcons.messageCircle,
                  title: 'quick_contact'.tr(lang),
                  items: [
                    _HelpItem(
                      icon: LucideIcons.mail,
                      title: lang == 'fr' ? 'Contacter le support' : 'Contact support',
                      subtitle: 'support@coach-ryze.com',
                      onTap: () => _sendSupportEmail(context, lang),
                      trailing: IconButton(
                        icon: const Icon(LucideIcons.copy, size: 18, color: _secondary),
                        onPressed: () => _copyEmail(context, lang),
                        tooltip: 'copy_email'.tr(lang),
                      ),
                    ),
                    _HelpItem(
                      icon: LucideIcons.globe,
                      title: 'website'.tr(lang),
                      subtitle: 'coach-ryze.com',
                      onTap: () => _launchURL('https://coach-ryze.com'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // FAQ
                _buildSection(
                  context,
                  lang,
                  icon: LucideIcons.circleHelp,
                  title: 'faq'.tr(lang),
                  items: [
                    _HelpItem(
                      icon: LucideIcons.bookOpen,
                      title: 'view_faq'.tr(lang),
                      subtitle: 'view_faq_desc'.tr(lang),
                      onTap: () => _launchURL('https://coach-ryze.com/support#faq'),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Problèmes techniques
                _buildSection(
                  context,
                  lang,
                  icon: LucideIcons.wrench,
                  title: 'technical_issues'.tr(lang),
                  items: [
                    _HelpItem(
                      icon: LucideIcons.refreshCw,
                      title: 'sync_issues'.tr(lang),
                      subtitle: 'sync_issues_desc'.tr(lang),
                      onTap: () => _showTroubleshootingDialog(
                        context,
                        lang,
                        'sync_issues'.tr(lang),
                        'sync_issues_solution'.tr(lang),
                      ),
                    ),
                    _HelpItem(
                      icon: LucideIcons.camera,
                      title: 'camera_issues'.tr(lang),
                      subtitle: 'camera_issues_desc'.tr(lang),
                      onTap: () => _showTroubleshootingDialog(
                        context,
                        lang,
                        'camera_issues'.tr(lang),
                        'camera_issues_solution'.tr(lang),
                      ),
                    ),
                    _HelpItem(
                      icon: LucideIcons.bug,
                      title: 'report_bug'.tr(lang),
                      subtitle: 'report_bug_desc'.tr(lang),
                      onTap: () => _sendBugReportEmail(context, lang),
                    ),
                  ],
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSection(
    BuildContext context,
    String lang, {
    required IconData icon,
    required String title,
    required List<_HelpItem> items,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _secondary, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _primaryDark,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: _borderColor),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Column(
              children: [
                _buildListTile(
                  icon: item.icon,
                  title: item.title,
                  subtitle: item.subtitle,
                  onTap: item.onTap,
                  trailing: item.trailing,
                ),
                if (index < items.length - 1)
                  const Divider(height: 1, indent: 56, color: _borderColor),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: _secondary, size: 20),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      color: _primaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ??
                const Icon(
                  LucideIcons.chevronRight,
                  size: 18,
                  color: Colors.grey,
                ),
          ],
        ),
      ),
    );
  }

  void _showFAQDialog(BuildContext context, String lang, String question, String answer) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          question,
          style: const TextStyle(
            color: _primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            answer,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: _secondary),
            child: Text('close'.tr(lang)),
          ),
        ],
      ),
    );
  }

  void _showTroubleshootingDialog(BuildContext context, String lang, String issue, String solution) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          issue,
          style: const TextStyle(
            color: _primaryDark,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: SingleChildScrollView(
          child: Text(
            solution,
            style: const TextStyle(color: Colors.black87),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: Text('close'.tr(lang)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendSupportEmail(context, lang);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _secondary,
              foregroundColor: Colors.white,
            ),
            child: Text('contact_support'.tr(lang)),
          ),
        ],
      ),
    );
  }
}

class _HelpItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  _HelpItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });
}
