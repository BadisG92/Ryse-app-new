import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool isPrimary;
  final bool isSecondary;
  final bool isDisabled;
  final bool isSmall;
  final EdgeInsetsGeometry? padding;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.isPrimary = true,
    this.isSecondary = false,
    this.isDisabled = false,
    this.isSmall = false,
    this.padding,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AnimatedScale(
        scale: 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          decoration: BoxDecoration(
            gradient: isPrimary && !isDisabled
                ? const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  )
                : null,
            color: isSecondary
                ? Colors.white.withOpacity(0.2)
                : isDisabled
                    ? const Color(0xFFF1F5F9)
                    : null,
            borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
            border: isSecondary
                ? Border.all(color: Colors.white.withOpacity(0.2))
                : null,
            boxShadow: isPrimary && !isDisabled
                ? [
                    BoxShadow(
                      color: const Color(0xFF0B132B).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isDisabled ? null : onPressed,
              borderRadius: BorderRadius.circular(isSmall ? 8 : 12),
              child: Padding(
                padding: padding ??
                    EdgeInsets.symmetric(
                      horizontal: isSmall ? 12 : 16,
                      vertical: isSmall ? 8 : 12,
                    ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[
                      icon!,
                      const SizedBox(width: 8),
                    ],
                    Text(
                      text,
                      style: TextStyle(
                        fontSize: isSmall ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        color: isPrimary && !isDisabled
                            ? Colors.white
                            : isSecondary
                                ? Colors.white
                                : isDisabled
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF0B132B),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
} 
