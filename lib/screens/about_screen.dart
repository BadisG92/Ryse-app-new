import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

/// Écran À propos de l'application
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // Couleurs de l'app
  static const Color _primaryDark = Color(0xFF0B132B);
  static const Color _secondary = Color(0xFF1C2951);
  static const Color _lightBackground = Color(0xFFF8FAFC);
  static const Color _borderColor = Color(0xFFE2E8F0);

  String _appVersion = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = '1.0.0';
        _buildNumber = '1';
      });
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _copyText(BuildContext context, String text, String message) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: _secondary,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _sendEmail(BuildContext context, String lang) async {
    // Récupérer les infos système pour faciliter le debug
    final userId = 'USER_ID'; // TODO: Remplacer par le vrai User ID depuis AuthService
    final appVersion = _appVersion.isNotEmpty ? _appVersion : '1.0.0';

    final subject = 'support_email_subject'.tr(lang);
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
              _copyText(context, 'support@coach-ryze.com', 'email_copied'.tr(lang));
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
              'about'.tr(lang),
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

                // Logo et informations principales
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      // Logo de l'app (vrai logo)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _primaryDark,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: SvgPicture.asset(
                          'assets/images/logo_seul.svg',
                          width: 56,
                          height: 56,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nom de l'app
                      const Text(
                        'Ryze',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _primaryDark,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Slogan
                      Text(
                        'about_slogan'.tr(lang),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Version
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: _secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _borderColor),
                        ),
                        child: Text(
                          'version'.tr(lang) + ' $_appVersion ($_buildNumber)',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _secondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description de l'app
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
                            child: const Icon(
                              LucideIcons.info,
                              color: _secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'about_app'.tr(lang),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'about_description'.tr(lang),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Fonctionnalités principales
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
                            child: const Icon(
                              LucideIcons.sparkles,
                              color: _secondary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'key_features'.tr(lang),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _primaryDark,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildFeature(LucideIcons.camera, 'feature_ai_scanner'.tr(lang)),
                      _buildFeature(LucideIcons.utensils, 'feature_nutrition'.tr(lang)),
                      _buildFeature(LucideIcons.dumbbell, 'feature_workouts'.tr(lang)),
                      _buildFeature(LucideIcons.target, 'feature_goals'.tr(lang)),
                      _buildFeature(LucideIcons.trendingUp, 'feature_progress'.tr(lang)),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Liens
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      _buildLinkTile(
                        icon: LucideIcons.globe,
                        title: 'website'.tr(lang),
                        subtitle: 'coach-ryze.com',
                        onTap: () => _launchURL('https://coach-ryze.com'),
                      ),
                      const Divider(height: 1, color: _borderColor),
                      _buildLinkTile(
                        icon: LucideIcons.mail,
                        title: 'contact_email'.tr(lang),
                        subtitle: 'support@coach-ryze.com',
                        onTap: () => _copyText(
                          context,
                          'support@coach-ryze.com',
                          lang == 'fr' ? 'Email copié' : 'Email copied',
                        ),
                      ),
                      const Divider(height: 1, color: _borderColor),
                      _buildLinkTile(
                        icon: LucideIcons.fileText,
                        title: 'terms_of_service'.tr(lang),
                        onTap: () => _launchURL(
                          lang == 'fr'
                              ? 'https://coach-ryze.com/terms.html'
                              : 'https://coach-ryze.com/terms_en.html',
                        ),
                      ),
                      const Divider(height: 1, color: _borderColor),
                      _buildLinkTile(
                        icon: LucideIcons.shield,
                        title: 'privacy_policy'.tr(lang),
                        onTap: () => _launchURL(
                          lang == 'fr'
                              ? 'https://coach-ryze.com/privacy.html'
                              : 'https://coach-ryze.com/privacy_en.html',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Health Disclaimer (Required by Apple for health/fitness apps)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCD34D)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              LucideIcons.triangleAlert,
                              color: Color(0xFFD97706),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'health_disclaimer_title'.tr(lang),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'health_disclaimer_text'.tr(lang),
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF92400E),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Crédits
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: _borderColor),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'made_with_love'.tr(lang),
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '© 2025 Ryze',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
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

  Widget _buildFeature(IconData icon, String text) {
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
        ],
      ),
    );
  }

  Widget _buildLinkTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
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
                      fontWeight: FontWeight.w500,
                      color: _primaryDark,
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
            const Icon(
              LucideIcons.externalLink,
              size: 18,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
