import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../design/design.dart';
import '../../screens/auth/auth_kit.dart';
import '../../screens/auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/global_state_manager.dart';
import '../../services/header_cache_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import 'info_pages.dart';

/// Changer son mot de passe, ou s'en faire envoyer un lien.
///
/// Les champs sont ceux de l'authentification (`AuthField`, `AuthCta`) :
/// c'est le même geste que se connecter, il n'y a pas de raison qu'il ait
/// une autre apparence. Un compte Google ou Apple n'a pas de mot de passe
/// chez nous, et l'écran le dit au lieu de proposer un formulaire inerte.
class AccountManagementScreen extends StatefulWidget {
  const AccountManagementScreen({super.key});

  @override
  State<AccountManagementScreen> createState() => _AccountManagementScreenState();
}

class _AccountManagementScreenState extends State<AccountManagementScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();

  String? _email;
  bool _oauth = false;
  bool _busy = false;
  bool _sending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final identities = user.identities ?? [];
      _email = user.email;
      _oauth = !identities.any((i) => i.provider == 'email') && identities.isNotEmpty;
    }
  }

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    final lang = LocalizationService.instance.currentLanguageCode;
    final email = _email;
    if (email == null || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'https://coach-ryze.com/reset-password',
      );
      if (!mounted) return;
      RyzeFeedback.success();
      RyzeUndo.note(context, message: 'reset_link_sent'.tr(lang));
    } catch (_) {
      if (mounted) RyzeUndo.failed(context, message: 'error_sending_reset_link'.tr(lang));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _change() async {
    final lang = LocalizationService.instance.currentLanguageCode;
    if (_busy) return;

    // La validation vit dans le champ, pas dans une bannière rouge.
    if (_current.text.isEmpty || _next.text.isEmpty) {
      setState(() => _error = 'field_required'.tr(lang));
      return;
    }
    if (_next.text.length < 6) {
      setState(() => _error = 'password_min_length'.tr(lang));
      return;
    }
    if (_next.text != _confirm.text) {
      setState(() => _error = 'passwords_dont_match'.tr(lang));
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // Le mot de passe actuel se vérifie en s'en servant : Supabase n'offre
      // pas de « vérifier sans se connecter ».
      final email = _email;
      if (email != null) {
        try {
          await Supabase.instance.client.auth.signInWithPassword(email: email, password: _current.text);
        } catch (_) {
          if (mounted) {
            setState(() {
              _busy = false;
              _error = 'current_password_incorrect'.tr(lang);
            });
          }
          return;
        }
      }
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: _next.text));
      if (!mounted) return;
      RyzeFeedback.success();
      Navigator.of(context).pop();
      RyzeUndo.note(context, message: 'password_changed_success'.tr(lang));
    } catch (_) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = 'error_changing_password'.tr(lang);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;

    return InfoScaffold(
      title: 'email_password'.tr(lang),
      subtitle: _email,
      children: [
        if (_oauth)
          Container(
            padding: EdgeInsets.all(context.vw(4.1)),
            decoration: BoxDecoration(
              color: RyzeColors.surf,
              borderRadius: BorderRadius.circular(RyzeRadius.md),
              border: Border.all(color: RyzeColors.line),
            ),
            child: Text('oauth_no_password'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute, height: 1.5)),
          )
        else ...[
          Text('change_password'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
          SizedBox(height: context.vw(2.6)),
          AuthField(controller: _current, hint: 'current_password'.tr(lang), icon: LucideIcons.lock, obscure: true, error: _error),
          SizedBox(height: context.vw(2.6)),
          AuthField(controller: _next, hint: 'new_password'.tr(lang), icon: LucideIcons.lock, obscure: true),
          SizedBox(height: context.vw(2.6)),
          AuthField(
            controller: _confirm,
            hint: 'confirm_password'.tr(lang),
            icon: LucideIcons.lock,
            obscure: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _change(),
          ),
          SizedBox(height: context.vw(4.1)),
          AuthCta(label: 'change_password'.tr(lang), loading: _busy, onPressed: _change),
          SizedBox(height: context.vw(6)),
          Text('forgot_password_title'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
          SizedBox(height: context.vw(1)),
          Text('forgot_password_desc'.tr(lang), style: RyzeText.body(context, 3.4, color: RyzeColors.mute, height: 1.4)),
          SizedBox(height: context.vw(2.6)),
          Pressable(
            onTap: _sending ? null : _sendLink,
            child: Container(
              height: context.vw(12.3),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(RyzeRadius.sm),
                border: Border.all(color: RyzeColors.idle),
              ),
              child: _sending
                  ? SizedBox(
                      width: context.vw(4.6),
                      height: context.vw(4.6),
                      child: CircularProgressIndicator(color: RyzeColors.mute, strokeWidth: 2),
                    )
                  : Text('send_reset_link'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600)),
            ),
          ),
        ],
      ],
    );
  }
}

/// Supprimer son compte : ce qui part, deux cases, le mot tapé, puis une
/// dernière question. Aucune de ces étapes n'est décorative — après, il n'y
/// a plus rien à récupérer.
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  static const _dataKeys = [
    'profile_data',
    'nutrition_data',
    'workout_data',
    'progress_data',
    'goals_data',
    'health_data',
    'achievements_data',
  ];

  final _typed = TextEditingController();
  bool _understand = false;
  bool _accept = false;
  bool _deleting = false;

  @override
  void initState() {
    super.initState();
    _typed.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  /// Le mot à taper est « DELETE » dans les trois langues — c'est ce que
  /// disent les trois traductions de l'invite, et c'est ce que l'ancien écran
  /// comparait. Le traduire rendrait le bouton impossible à activer.
  static const _word = 'DELETE';

  bool get _ready => _understand && _accept && _typed.text.trim().toUpperCase() == _word;

  Future<void> _delete() async {
    final lang = LocalizationService.instance.currentLanguageCode;
    if (!_ready || _deleting) return;

    final sure = await showRyzeSheet<bool>(
      context,
      title: 'final_confirmation'.tr(lang),
      subtitle: 'final_confirmation_message'.tr(lang),
      dismissible: false,
      builder: (sheet) => RyzeSheetGroup(
        children: [
          RyzeSheetRow(first: true, icon: LucideIcons.x, label: 'cancel'.tr(lang), onTap: () => Navigator.pop(sheet, false)),
          RyzeSheetRow(icon: LucideIcons.trash2, label: 'delete_my_account'.tr(lang), danger: true, onTap: () => Navigator.pop(sheet, true)),
        ],
      ),
    );
    if (sure != true || !mounted) return;

    setState(() => _deleting = true);
    final auth = Provider.of<AuthService>(context, listen: false);
    try {
      final supabase = Supabase.instance.client;
      final token = supabase.auth.currentSession?.accessToken;
      if (supabase.auth.currentUser?.id == null || token == null) {
        throw Exception('not authenticated');
      }
      // L'Edge Function supprime public.users (CASCADE sur toutes les données)
      // puis auth.users. Rien n'est effacé côté client avant sa réponse.
      final response = await supabase.functions.invoke('delete-user', headers: {'Authorization': 'Bearer $token'});
      if (response.status != 200) {
        throw Exception(response.data?['error'] ?? 'delete failed');
      }
      await auth.signOut();
      GlobalStateManager.instance.reset();
      HeaderCacheService.clearCache();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _deleting = false);
        RyzeUndo.failed(context, message: 'error_deleting_account'.tr(lang));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LocalizationService>().currentLanguageCode;

    return InfoScaffold(
      title: 'delete_account'.tr(lang),
      children: [
        Container(
          padding: EdgeInsets.all(context.vw(4.1)),
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.danger, width: 1.4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.triangleAlert, size: context.vw(4.6), color: RyzeColors.danger),
                  SizedBox(width: context.vw(2.6)),
                  Expanded(
                    child: Text('delete_account_warning'.tr(lang), style: RyzeText.body(context, 3.6, weight: FontWeight.w600, color: RyzeColors.danger)),
                  ),
                ],
              ),
              SizedBox(height: context.vw(2.1)),
              Text('delete_account_warning_desc'.tr(lang), style: RyzeText.body(context, 3.1, color: RyzeColors.mute, height: 1.5)),
            ],
          ),
        ),
        SizedBox(height: context.vw(5.1)),
        Text('data_to_be_deleted'.tr(lang), style: RyzeText.body(context, 3.1, weight: FontWeight.w600, color: RyzeColors.mute)),
        SizedBox(height: context.vw(2.1)),
        Container(
          decoration: BoxDecoration(
            color: RyzeColors.surf,
            borderRadius: BorderRadius.circular(RyzeRadius.md),
            border: Border.all(color: RyzeColors.line),
          ),
          child: Column(
            children: [
              for (var i = 0; i < _dataKeys.length; i++)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: context.vw(4.1), vertical: context.vw(2.6)),
                  decoration: BoxDecoration(border: i == 0 ? null : Border(top: BorderSide(color: RyzeColors.line))),
                  child: Row(
                    children: [
                      Icon(LucideIcons.minus, size: context.vw(3.6), color: RyzeColors.mute2),
                      SizedBox(width: context.vw(2.6)),
                      Expanded(child: Text(_dataKeys[i].tr(lang), style: RyzeText.body(context, 3.4))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: context.vw(2.1)),
        Text('subscription_info'.tr(lang), style: RyzeText.body(context, 2.9, color: RyzeColors.mute2, height: 1.4)),
        SizedBox(height: context.vw(5.1)),
        _Check(label: 'understand_permanent'.tr(lang), value: _understand, onChanged: (v) => setState(() => _understand = v)),
        _Check(label: 'accept_data_loss'.tr(lang), value: _accept, onChanged: (v) => setState(() => _accept = v)),
        SizedBox(height: context.vw(4.1)),
        Text(
          'type_delete_to_confirm_label'.tr(lang),
          style: RyzeText.body(context, 3.4, color: RyzeColors.mute, height: 1.4),
        ),
        SizedBox(height: context.vw(2.1)),
        AuthField(
          controller: _typed,
          hint: _word,
          icon: LucideIcons.keyboard,
          textCapitalization: TextCapitalization.characters,
          autocorrect: false,
          textInputAction: TextInputAction.done,
        ),
        SizedBox(height: context.vw(5.1)),
        Pressable(
          onTap: _ready && !_deleting ? _delete : null,
          child: AnimatedContainer(
            duration: RyzeDurations.tap,
            height: context.vw(13.3),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _ready && !_deleting ? RyzeColors.danger : RyzeColors.idle,
              borderRadius: BorderRadius.circular(RyzeRadius.sm),
            ),
            child: _deleting
                ? SizedBox(
                    width: context.vw(4.6),
                    height: context.vw(4.6),
                    child: CircularProgressIndicator(color: RyzeColors.surf, strokeWidth: 2),
                  )
                : Text(
                    'delete_my_account'.tr(lang),
                    style: RyzeText.body(context, 3.9, weight: FontWeight.w600, color: _ready ? RyzeColors.surf : RyzeColors.mute),
                  ),
          ),
        ),
      ],
    );
  }
}

class _Check extends StatelessWidget {
  const _Check({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        RyzeFeedback.select();
        onChanged(!value);
      },
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: context.vw(2.1)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: RyzeDurations.tap,
              width: context.vw(6.2),
              height: context.vw(6.2),
              margin: EdgeInsets.only(top: context.vw(0.4)),
              decoration: BoxDecoration(
                color: value ? RyzeColors.ink : Colors.transparent,
                borderRadius: BorderRadius.circular(RyzeRadius.xs),
                border: Border.all(color: value ? RyzeColors.ink : RyzeColors.line, width: 1.4),
              ),
              child: value ? Icon(LucideIcons.check, size: context.vw(4.1), color: RyzeColors.surf) : null,
            ),
            SizedBox(width: context.vw(3.1)),
            Expanded(child: Text(label, style: RyzeText.body(context, 3.4, height: 1.4))),
          ],
        ),
      ),
    );
  }
}
