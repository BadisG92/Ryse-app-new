import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/localization_service.dart';

/// Simple success screen after signing the pact
class PactSuccessScreen extends StatelessWidget {
  final VoidCallback onContinue;

  const PactSuccessScreen({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final locService = Provider.of<LocalizationService>(context, listen: false);
    final langCode = locService.currentLanguageCode;

    String title;
    String subtitle;
    String buttonText;

    if (langCode == 'de') {
      title = 'Abgemacht! 🤝';
      subtitle = 'Nur noch ein paar Details und wir sind startklar.';
      buttonText = 'Weiter';
    } else if (langCode == 'en') {
      title = 'Deal! 🤝';
      subtitle = 'Just a few more details and we\'re set.';
      buttonText = 'Continue';
    } else {
      title = 'Deal ! 🤝';
      subtitle = 'Plus que quelques infos et on est bons.';
      buttonText = 'Continuer';
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Panda fist bump
              Image.asset(
                'assets/images/coach_ryze fistbump.png',
                height: 180,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B132B),
                ),
              ),
              const SizedBox(height: 16),

              // Subtitle
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),

              const Spacer(flex: 3),

              // Continue button
              GestureDetector(
                onTap: onContinue,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      buttonText,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: MediaQuery.of(context).padding.bottom + 32),
            ],
          ),
        ),
      ),
    );
  }
}
