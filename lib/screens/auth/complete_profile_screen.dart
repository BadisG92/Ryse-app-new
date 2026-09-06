import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';

import '../../design/design.dart';
import '../../services/auth_service.dart';
import '../../services/haptic_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import 'auth_kit.dart';

/// Rattrapage for an account that finished the onboarding without a first
/// name: a legacy account, or a social sign-in that gave nothing. A new user
/// never sees this screen — a coach asks the question in chapter 1.
class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _lang => Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;

  Future<void> _submit() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final name = _controller.text.trim();
    if (name.length < 2) {
      HapticService.instance.lightImpact();
      setState(() => _error = 'register.nameMinLength'.tr(_lang));
      return;
    }

    final authService = Provider.of<AuthService>(context, listen: false);
    final success = await authService.updateProfile(firstName: name);
    if (!mounted) return;

    if (success) {
      HapticService.instance.mediumImpact();
      widget.onComplete();
      return;
    }
    setState(() => _error = (authService.errorMessage ?? 'register.registrationFailed').tr(_lang));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthService, LocalizationService>(
      builder: (context, authService, locService, _) {
        final lang = locService.currentLanguageCode;
        return AuthScaffold(
          children: [
            SizedBox(height: context.vh(4)),
            const PopIn(delay: Duration(milliseconds: 120), child: AuthCoaches()),
            SizedBox(height: context.vh(2.4)),
            AuthTitle('complete_profile_title'.tr(lang)),
            SizedBox(height: context.vh(1.2)),
            PopIn(
              delay: const Duration(milliseconds: 360),
              dy: 8,
              child: Text(
                'complete_profile_subtitle'.tr(lang),
                style: RyzeText.body(context, 3.9, color: RyzeColors.mute, height: 1.45),
              ),
            ),
            SizedBox(height: context.vh(3.4)),
            PopIn(
              delay: const Duration(milliseconds: 460),
              child: AuthField(
                controller: _controller,
                hint: 'register.firstName'.tr(lang),
                icon: LucideIcons.user,
                error: _error,
                autofocus: true,
                maxLength: 24,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.givenName],
                autocorrect: false,
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _submit(),
              ),
            ),
            SizedBox(height: context.vh(3)),
            PopIn(
              delay: const Duration(milliseconds: 540),
              child: AuthCta(label: 'continue'.tr(lang), loading: authService.isLoading, onPressed: _submit),
            ),
            SizedBox(height: context.vh(1.6)),
            PopIn(
              delay: const Duration(milliseconds: 600),
              child: Text(
                'complete_profile_privacy'.tr(lang),
                textAlign: TextAlign.center,
                style: RyzeText.body(context, 3.2, color: RyzeColors.mute, height: 1.35),
              ),
            ),
          ],
        );
      },
    );
  }
}
