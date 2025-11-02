import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SocialLoginButton extends StatelessWidget {
  final String provider; // 'google' or 'apple'
  final VoidCallback? onPressed;
  final bool isLarge; // true = bouton principal, false = bouton compact

  const SocialLoginButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isGoogle = provider.toLowerCase() == 'google';
    final isApple = provider.toLowerCase() == 'apple';

    // Couleurs officielles
    final Color backgroundColor = isGoogle
        ? Colors.white
        : (isApple ? Colors.black : Colors.white);

    final Color textColor = isGoogle
        ? const Color(0xFF3c4043)
        : (isApple ? Colors.white : const Color(0xFF0B132B));

    final Color borderColor = isGoogle
        ? const Color(0xFFdadce0)
        : (isApple ? Colors.black : Colors.grey.shade300);

    // Texte selon la taille
    final String buttonText = isLarge
        ? (isGoogle ? 'Continuer avec Google' : 'Continuer avec Apple')
        : (isGoogle ? 'Google' : 'Apple');

    return SizedBox(
      height: isLarge ? 56 : 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: isGoogle ? 1 : 0,
          shadowColor: Colors.black12,
          side: BorderSide(
            color: borderColor,
            width: isApple ? 0 : 1,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isLarge ? 12 : 10),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: isLarge ? 24 : 16,
            vertical: 12,
          ),
        ),
        child: Row(
          mainAxisAlignment: isLarge ? MainAxisAlignment.start : MainAxisAlignment.center,
          mainAxisSize: isLarge ? MainAxisSize.max : MainAxisSize.min,
          children: [
            // Logo officiel Font Awesome
            FaIcon(
              isGoogle ? FontAwesomeIcons.google : FontAwesomeIcons.apple,
              size: isLarge ? 20 : 18,
              color: isGoogle
                  ? const Color(0xFF4285F4) // Bleu Google officiel
                  : (isApple ? Colors.white : Colors.black),
            ),
            if (isLarge) ...[
              const SizedBox(width: 16),
              Flexible(
                child: Text(
                  buttonText,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                    letterSpacing: 0.25,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ] else ...[
              const SizedBox(width: 8),
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
