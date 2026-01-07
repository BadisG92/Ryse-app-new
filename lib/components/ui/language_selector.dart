import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) {
        return PopupMenuButton<String>(
          onSelected: (String languageCode) async {
            await locService.setLanguage(languageCode);
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'fr',
              child: Row(
                children: [
                  const Text('🇫🇷'),
                  const SizedBox(width: 8),
                  const Text('Français'),
                  const Spacer(),
                  if (locService.isFrench)
                    const Icon(LucideIcons.check, size: 16, color: Color(0xFF0B132B)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'en',
              child: Row(
                children: [
                  const Text('🇺🇸'),
                  const SizedBox(width: 8),
                  const Text('English'),
                  const Spacer(),
                  if (locService.isEnglish)
                    const Icon(LucideIcons.check, size: 16, color: Color(0xFF0B132B)),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'de',
              child: Row(
                children: [
                  const Text('🇩🇪'),
                  const SizedBox(width: 8),
                  const Text('Deutsch'),
                  const Spacer(),
                  if (locService.isGerman)
                    const Icon(LucideIcons.check, size: 16, color: Color(0xFF0B132B)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(locService.isFrench ? '🇫🇷' : locService.isGerman ? '🇩🇪' : '🇺🇸'),
                const SizedBox(width: 4),
                Text(
                  locService.isFrench ? 'FR' : locService.isGerman ? 'DE' : 'EN',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  LucideIcons.chevronDown,
                  size: 14,
                  color: Color(0xFF64748B),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}