import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/localization_service.dart';

class LanguageSwitchButtons extends StatelessWidget {
  const LanguageSwitchButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) => Positioned(
        top: 50,
        right: 20,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bouton FR
            GestureDetector(
              onTap: () => locService.setLanguage('fr'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: locService.isFrench ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: locService.isFrench ? Colors.blue : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Text(
                  'FR',
                  style: TextStyle(
                    color: locService.isFrench ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bouton EN
            GestureDetector(
              onTap: () => locService.setLanguage('en'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: locService.isEnglish ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: locService.isEnglish ? Colors.blue : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Text(
                  'EN',
                  style: TextStyle(
                    color: locService.isEnglish ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Bouton DE
            GestureDetector(
              onTap: () => locService.setLanguage('de'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: locService.isGerman ? Colors.blue : Colors.grey,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: locService.isGerman ? Colors.blue : Colors.grey,
                    width: 2,
                  ),
                ),
                child: Text(
                  'DE',
                  style: TextStyle(
                    color: locService.isGerman ? Colors.white : Colors.black54,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}