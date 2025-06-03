import 'package:flutter/material.dart';
import 'dart:ui';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool withBackdropBlur;
  final bool withHover;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? backgroundColor;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.withBackdropBlur = true,
    this.withHover = false,
    this.onTap,
    this.gradient,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardWidget = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        color: backgroundColor ?? Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: withBackdropBlur
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(12),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(12),
                child: child,
              ),
      ),
    );

    if (withHover) {
      cardWidget = TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 200),
        tween: Tween(begin: 1.0, end: 1.0),
        builder: (context, scale, child) {
          return Transform.scale(
            scale: scale,
            child: cardWidget,
          );
        },
      );
    }

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        onTapDown: withHover ? (_) => _animateScale(context, 1.05) : null,
        onTapUp: withHover ? (_) => _animateScale(context, 1.0) : null,
        onTapCancel: withHover ? () => _animateScale(context, 1.0) : null,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  void _animateScale(BuildContext context, double scale) {
    // Note: This would need to be implemented with a StatefulWidget for proper hover animation
    // For now, using the basic gesture feedback
  }
} 