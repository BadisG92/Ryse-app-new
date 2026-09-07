import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../design/design.dart';
import '../screens/auth/login_screen.dart';
import '../services/auth_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';
import '../services/unit_service.dart';
import 'settings_data.dart';
import 'pages/account_pages.dart';
import 'pages/info_pages.dart';
import 'sheets/app_sheets.dart';
import 'sheets/nutrition_sheet.dart';
import 'sheets/profile_sheets.dart';

/// Les réglages, en trois groupes : toi, l'app, le compte.
///
/// L'ancien écran empilait huit sections dépliables dans 4 090 lignes, avec
/// chacune ses champs, ses interrupteurs et ses dialogues. Ici chaque ligne
/// dit sa valeur actuelle et ouvre une feuille — on voit tout son profil sans
/// rien déplier, et on n'ouvre que ce qu'on vient changer.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  SettingsProfile? _p;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SettingsData.load();
    if (mounted) setState(() => _p = p);
  }

  String get _lang => LocalizationService.instance.currentLanguageCode;

  /// Une feuille a modifié le profil : on écrit, et on le dit.
  Future<void> _persist() async {
    final p = _p;
    if (p == null || _saving) return;
    setState(() => _saving = true);
    final online = await SettingsData.save(p);
    if (!mounted) return;
    setState(() => _saving = false);
    RyzeUndo.note(context, message: online ? 'settings_saved'.tr(_lang) : 'error_save_changes_local'.tr(_lang));
  }

  Future<void> _push(Widget screen) async {
    RyzeFeedback.tap();
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _load();
  }

  Future<void> _logout() async {
    final lang = _lang;
    final sure = await showRyzeSheet<bool>(
      context,
      title: 'logout'.tr(lang),
      subtitle: 'logout_confirmation'.tr(lang),
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(first: true, icon: LucideIcons.logOut, label: 'logout'.tr(lang), danger: true, onTap: () => Navigator.pop(sheet, true)),
          RyzeSheetRow(icon: LucideIcons.x, label: 'cancel'.tr(lang), onTap: () => Navigator.pop(sheet, false)),
        ],
      ),
    );
    if (sure != true || !mounted) return;
    try {
      await AuthService().signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) RyzeUndo.failed(context, message: 'error_during_logout'.tr(lang));
    }
  }

  Future<void> _subscription() async {
    final lang = _lang;
    RyzeFeedback.tap();
    final uri = Uri.parse('https://apps.apple.com/account/subscriptions');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) RyzeUndo.failed(context, message: 'error_opening_subscriptions'.tr(lang));
    }
  }

  // ------------------------------------------------------------- résumés

  String _profileSummary(String lang) {
    final p = _p!;
    final units = UnitService.instance;
    final h = units.isMetric ? '${p.heightCm.round()} cm' : '${(p.heightCm / 2.54).round()} in';
    return '${p.gender.tr(lang)} · ${p.age} ${'settings_year_short'.tr(lang)} · $h';
  }

  String _goalSummary(String lang) {
    final p = _p!;
    final units = UnitService.instance;
    final goal = switch (p.mainGoal) {
      'lose' => 'weight_loss'.tr(lang),
      'gain' => 'weight_gain'.tr(lang),
      _ => 'maintenance'.tr(lang),
    };
    if (p.mainGoal == 'maintain') return goal;
    return '$goal · ${units.displayWeight(p.targetWeightKg).toStringAsFixed(1)} ${units.weightUnit}';
  }

  String _nutritionSummary(String lang) {
    final p = _p!;
    final numbers = NumberFormat.decimalPattern(lang);
    return '${numbers.format(p.calories)} ${'nutri_kcal'.tr(lang)} · ${p.protein}/${p.carbs}/${p.fat} g';
  }

  String _restrictionsSummary(String lang) {
    final p = _p!;
    if (p.restrictions.isEmpty) return 'no_restrictions'.tr(lang);
    return p.restrictions.map((r) => r.tr(lang)).join(' · ');
  }

  String _preferencesSummary(String lang) {
    final units = UnitService.instance;
    final language = switch (lang) {
      'en' => 'English',
      'de' => 'Deutsch',
      _ => 'Français',
    };
    return '$language · ${units.isMetric ? 'metric'.tr(lang) : 'imperial'.tr(lang)}';
  }

  // --------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;
    final gutter = context.vw(5.1);
    final p = _p;
    final user = AuthService().currentUser;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
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
                        Expanded(child: Text('settings'.tr(lang), style: RyzeText.body(context, 4.1, weight: FontWeight.w600))),
                        if (_saving)
                          SizedBox(
                            width: context.vw(4.6),
                            height: context.vw(4.6),
                            child: const CircularProgressIndicator(color: RyzeColors.mute, strokeWidth: 2),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: p == null
                        ? const Center(child: CircularProgressIndicator(color: RyzeColors.ink, strokeWidth: 2))
                        : ListView(
                            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, context.vw(12)),
                            children: [
                              if (user != null && (user.firstName.isNotEmpty || user.email.isNotEmpty)) ...[
                                PopIn(
                                  delay: const Duration(milliseconds: 40),
                                  dy: 8,
                                  child: _Identity(name: user.firstName, email: user.email),
                                ),
                                SizedBox(height: context.vw(5.1)),
                              ],
                              PopIn(
                                delay: const Duration(milliseconds: 120),
                                dy: 8,
                                child: _Group(
                                  title: 'settings_you'.tr(lang),
                                  rows: [
                                    (LucideIcons.user, 'settings_profile'.tr(lang), _profileSummary(lang), () async {
                                      if (await ProfileSheet.show(context, lang: lang, p: p)) {
                                        setState(() {});
                                        _persist();
                                      }
                                    }),
                                    (LucideIcons.target, 'settings_objectives'.tr(lang), _goalSummary(lang), () async {
                                      if (await GoalSettingsSheet.show(context, lang: lang, p: p)) {
                                        setState(() {});
                                        _persist();
                                      }
                                    }),
                                    (LucideIcons.flame, 'settings_nutrition'.tr(lang), _nutritionSummary(lang), () async {
                                      if (await NutritionSheet.show(context, lang: lang, p: p)) {
                                        setState(() {});
                                        _persist();
                                      }
                                    }),
                                    (LucideIcons.utensils, 'dietary_restrictions'.tr(lang), _restrictionsSummary(lang), () async {
                                      if (await RestrictionsSheet.show(context, lang: lang, p: p)) {
                                        setState(() {});
                                        _persist();
                                      }
                                    }),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.vw(5.1)),
                              PopIn(
                                delay: const Duration(milliseconds: 240),
                                dy: 8,
                                child: _Group(
                                  title: 'settings_app'.tr(lang),
                                  rows: [
                                    (null, 'settings_coach'.tr(lang), null, () => CoachSheet.show(context, lang: lang)),
                                    (LucideIcons.bell, 'settings_notifications'.tr(lang), null, () => NotificationsSheet.show(context, lang: lang)),
                                    (LucideIcons.settings2, 'settings_preferences'.tr(lang), _preferencesSummary(lang), () async {
                                      await PreferencesSheet.show(context, lang: lang);
                                      if (mounted) setState(() {});
                                    }),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.vw(5.1)),
                              PopIn(
                                delay: const Duration(milliseconds: 360),
                                dy: 8,
                                child: _Group(
                                  title: 'settings_account'.tr(lang),
                                  rows: [
                                    (LucideIcons.mail, 'email_password'.tr(lang), null, () => _push(const AccountManagementScreen())),
                                    (LucideIcons.creditCard, 'manage_subscription'.tr(lang), null, _subscription),
                                    (LucideIcons.shield, 'privacy'.tr(lang), null, () => _push(const PrivacyScreen())),
                                    (LucideIcons.circleHelp, 'help_support'.tr(lang), null, () => _push(const HelpSupportScreen())),
                                    (LucideIcons.info, 'about'.tr(lang), null, () => _push(const AboutScreen())),
                                  ],
                                ),
                              ),
                              SizedBox(height: context.vw(5.1)),
                              PopIn(
                                delay: const Duration(milliseconds: 460),
                                dy: 8,
                                child: RyzeSheetGroup(
                                  children: [
                                    RyzeSheetRow(first: true, icon: LucideIcons.logOut, label: 'logout'.tr(lang), onTap: _logout),
                                    RyzeSheetRow(
                                      icon: LucideIcons.trash2,
                                      label: 'delete_account'.tr(lang),
                                      danger: true,
                                      onTap: () => _push(const DeleteAccountScreen()),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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

/// Qui est connecté. Pas une commande : le compte se règle plus bas.
class _Identity extends StatelessWidget {
  const _Identity({required this.name, required this.email});

  final String name;
  final String email;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : (email.isNotEmpty ? email[0].toUpperCase() : '·');
    return Row(
      children: [
        Container(
          width: context.vw(13.3),
          height: context.vw(13.3),
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: RyzeColors.ink, shape: BoxShape.circle),
          child: Text(initial, style: RyzeText.display(context, 5.6, weight: FontWeight.w600, color: RyzeColors.surf)),
        ),
        SizedBox(width: context.vw(3.6)),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty) Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 4.1, weight: FontWeight.w600)),
              if (email.isNotEmpty) Text(email, maxLines: 1, overflow: TextOverflow.ellipsis, style: RyzeText.body(context, 3.1, color: RyzeColors.mute)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Un groupe de réglages : son titre, ses lignes. Une ligne dit sa valeur,
/// pour qu'on n'ait pas à l'ouvrir pour la connaître.
class _Group extends StatelessWidget {
  const _Group({required this.title, required this.rows});

  final String title;
  final List<(IconData?, String, String?, VoidCallback)> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(left: context.vw(1), bottom: context.vw(2.1)),
          child: Text(title, style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        ),
        RyzeSheetGroup(
          children: [
            for (var i = 0; i < rows.length; i++)
              RyzeSheetRow(
                first: i == 0,
                icon: rows[i].$1,
                // Coach Ryze parle en son nom : c'est sa marque, pas une icône.
                leading: rows[i].$1 == null ? RyzeMark(size: context.vw(5.8)) : null,
                label: rows[i].$2,
                hint: rows[i].$3,
                onTap: rows[i].$4,
              ),
          ],
        ),
      ],
    );
  }
}
