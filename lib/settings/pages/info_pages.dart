import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/design.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

const _site = 'https://coach-ryze.com';
const _support = 'support@coach-ryze.com';

/// La coquille des pages d'information : un rond de retour, un titre, des
/// groupes de lignes. Trois pages qui se ressemblaient au pixel près avaient
/// chacune sa propre `AppBar` et ses propres couleurs.
class InfoScaffold extends StatelessWidget {
  const InfoScaffold({super.key, required this.title, this.subtitle, required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final gutter = context.vw(5.1);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: RyzeColors.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: RyzeColors.paper,
        body: Stack(
          children: [
            const OnbBackground(scene: false),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(gutter, context.vw(1.5), gutter, context.vw(2.6)),
                    child: Row(
                      children: [
                        Pressable(
                          onTap: () => Navigator.of(context).pop(),
                          child: Container(
                            width: context.vw(9.7),
                            height: context.vw(9.7),
                            decoration: BoxDecoration(color: RyzeColors.surf, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
                            child: Icon(LucideIcons.chevronLeft, size: context.vw(4.6), color: RyzeColors.ink),
                          ),
                        ),
                        SizedBox(width: context.vw(3.1)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 4.1, weight: FontWeight.w600)),
                              if (subtitle != null)
                                Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(12)),
                      children: children,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _open(BuildContext context, String url) async {
  RyzeFeedback.tap();
  try {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  } catch (_) {
    if (context.mounted) {
      RyzeUndo.failed(context, message: 'error_generic'.tr(LocalizationService.instance.currentLanguageCode));
    }
  }
}

Future<void> _mail(BuildContext context, String subject) async {
  RyzeFeedback.tap();
  final uri = Uri(scheme: 'mailto', path: _support, query: 'subject=${Uri.encodeComponent(subject)}');
  try {
    await launchUrl(uri);
  } catch (_) {
    // Pas de client mail : on copie l'adresse plutôt que de laisser
    // l'utilisateur devant un bouton qui n'a rien fait.
    await Clipboard.setData(const ClipboardData(text: _support));
    if (context.mounted) {
      RyzeUndo.note(context, message: 'email_copied'.tr(LocalizationService.instance.currentLanguageCode));
    }
  }
}

/// Les documents légaux, chez leur hébergeur.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final fr = lang == 'fr';
    return InfoScaffold(
      title: 'privacy'.tr(lang),
      subtitle: 'privacy_subtitle'.tr(lang),
      children: [
        RyzeSheetGroup(
          children: [
            RyzeSheetRow(
              first: true,
              icon: LucideIcons.shield,
              label: 'privacy_policy'.tr(lang),
              hint: 'privacy_policy_desc'.tr(lang),
              onTap: () => _open(context, fr ? '$_site/privacy.html' : '$_site/privacy_en.html'),
            ),
            RyzeSheetRow(
              icon: LucideIcons.fileText,
              label: 'terms_of_service'.tr(lang),
              hint: 'terms_of_service_desc'.tr(lang),
              onTap: () => _open(context, fr ? '$_site/terms.html' : '$_site/terms_en.html'),
            ),
          ],
        ),
      ],
    );
  }
}

/// L'aide : les trois pannes qu'on nous signale, puis nous écrire.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    return InfoScaffold(
      title: 'help_support'.tr(lang),
      subtitle: 'help_support_subtitle'.tr(lang),
      children: [
        _Label('faq'.tr(lang)),
        RyzeSheetGroup(
          children: [
            RyzeSheetRow(
              first: true,
              icon: LucideIcons.camera,
              label: 'camera_issues'.tr(lang),
              hint: 'camera_issues_solution'.tr(lang),
              onTap: () => _open(context, '$_site/support#faq'),
            ),
            RyzeSheetRow(
              icon: LucideIcons.refreshCw,
              label: 'sync_issues'.tr(lang),
              hint: 'sync_issues_solution'.tr(lang),
              onTap: () => _open(context, '$_site/support#faq'),
            ),
            RyzeSheetRow(
              icon: LucideIcons.circleHelp,
              label: 'view_faq'.tr(lang),
              hint: 'view_faq_desc'.tr(lang),
              onTap: () => _open(context, '$_site/support#faq'),
            ),
          ],
        ),
        SizedBox(height: context.vw(5.1)),
        _Label('quick_contact'.tr(lang)),
        RyzeSheetGroup(
          children: [
            RyzeSheetRow(
              first: true,
              icon: LucideIcons.mail,
              label: 'contact_support'.tr(lang),
              hint: _support,
              onTap: () => _mail(context, 'support_email_subject'.tr(lang)),
            ),
            RyzeSheetRow(
              icon: LucideIcons.bug,
              label: 'report_bug'.tr(lang),
              hint: 'report_bug_desc'.tr(lang),
              onTap: () => _mail(context, 'report_bug'.tr(lang)),
            ),
            RyzeSheetRow(
              icon: LucideIcons.globe,
              label: 'website'.tr(lang),
              hint: 'coach-ryze.com',
              onTap: () => _open(context, _site),
            ),
          ],
        ),
      ],
    );
  }
}

/// À propos : la marque, la version, ce que l'app fait, et l'avertissement
/// de santé — qui n'est pas décoratif et reste en toutes lettres.
class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final features = [
      (LucideIcons.camera, 'feature_ai_scanner'),
      (LucideIcons.utensils, 'feature_nutrition'),
      (LucideIcons.dumbbell, 'feature_workouts'),
      (LucideIcons.trendingUp, 'feature_progress'),
      (LucideIcons.target, 'feature_goals'),
    ];

    return InfoScaffold(
      title: 'about'.tr(lang),
      children: [
        Center(
          child: Column(
            children: [
              SizedBox(height: context.vw(2.6)),
              RyzeMark(size: context.vw(18)),
              SizedBox(height: context.vw(3.6)),
              Text('about_app'.tr(lang), style: RyzeText.display(context, 6.7, weight: FontWeight.w600)),
              SizedBox(height: context.vw(1)),
              Text('about_slogan'.tr(lang), textAlign: TextAlign.center, style: RyzeText.body(context, 3.4, color: RyzeColors.mute)),
              if (_version.isNotEmpty) ...[
                SizedBox(height: context.vw(1.5)),
                Text(
                  '${'version'.tr(lang)} $_version',
                  style: RyzeText.body(context, 3.1, color: RyzeColors.mute2).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: context.vw(6)),
        Text('about_description'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute, height: 1.5)),
        SizedBox(height: context.vw(5.1)),
        _Label('key_features'.tr(lang)),
        RyzeSheetGroup(
          children: [
            for (var i = 0; i < features.length; i++)
              _Line(icon: features[i].$1, label: features[i].$2.tr(lang), first: i == 0),
          ],
        ),
        SizedBox(height: context.vw(5.1)),
        Container(
          padding: EdgeInsets.all(context.vw(4.1)),
          decoration: BoxDecoration(
            color: RyzeColors.accTint,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.triangleAlert, size: context.vw(4.6), color: RyzeColors.accInk),
                  SizedBox(width: context.vw(2.6)),
                  Expanded(
                    child: Text('health_disclaimer_title'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.accInk)),
                  ),
                ],
              ),
              SizedBox(height: context.vw(2.1)),
              Text('health_disclaimer_text'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.accInk, height: 1.5)),
            ],
          ),
        ),
        SizedBox(height: context.vw(5.1)),
        RyzeSheetGroup(
          children: [
            RyzeSheetRow(first: true, icon: LucideIcons.globe, label: 'website'.tr(lang), hint: 'coach-ryze.com', onTap: () => _open(context, _site)),
            RyzeSheetRow(
              icon: LucideIcons.mail,
              label: 'contact_email'.tr(lang),
              hint: _support,
              onTap: () => _mail(context, 'support_email_subject'.tr(lang)),
            ),
            RyzeSheetRow(
              icon: LucideIcons.fileText,
              label: 'terms_of_service'.tr(lang),
              onTap: () => _open(context, lang == 'fr' ? '$_site/terms.html' : '$_site/terms_en.html'),
            ),
            RyzeSheetRow(
              icon: LucideIcons.shield,
              label: 'privacy_policy'.tr(lang),
              onTap: () => _open(context, lang == 'fr' ? '$_site/privacy.html' : '$_site/privacy_en.html'),
            ),
          ],
        ),
        SizedBox(height: context.vw(6)),
        Center(child: Text('made_with_love'.tr(lang), style: RyzeText.body(context, 2.9, color: RyzeColors.mute2))),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: context.vw(1), bottom: context.vw(2.1)),
      child: Text(text, style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
    );
  }
}

/// Une ligne qui informe sans rien ouvrir : pas de chevron, pas de tap.
class _Line extends StatelessWidget {
  const _Line({required this.icon, required this.label, required this.first});

  final IconData icon;
  final String label;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: context.vw(13.3),
      padding: EdgeInsets.only(left: context.vw(2.6), right: context.vw(3.1)),
      decoration: BoxDecoration(border: first ? null : Border(top: BorderSide(color: RyzeColors.line))),
      child: Row(
        children: [
          Container(
            width: context.vw(9.7),
            height: context.vw(9.7),
            decoration: BoxDecoration(color: RyzeColors.paper, shape: BoxShape.circle, border: Border.all(color: RyzeColors.line)),
            child: Icon(icon, size: context.vw(4.6), color: RyzeColors.ink),
          ),
          SizedBox(width: context.vw(3.1)),
          Expanded(child: Text(label, style: RyzeText.body(context, 3.6, weight: FontWeight.w600))),
        ],
      ),
    );
  }
}
