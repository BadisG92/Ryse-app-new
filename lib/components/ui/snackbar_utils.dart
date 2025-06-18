import 'package:flutter/material.dart';

class SnackBarUtils {
  /// Affiche un message en haut de l'écran en utilisant un Overlay
  static OverlayEntry? _currentOverlay;

  static void showTopSnackBar(
    BuildContext context, {
    required String message,
    Color? backgroundColor,
    Color? textColor,
    Duration? duration,
    IconData? icon,
  }) {
    // Fermer le message précédent s'il existe
    _currentOverlay?.remove();
    
    // Créer l'overlay
    _currentOverlay = OverlayEntry(
      builder: (context) => _TopSnackBar(
        message: message,
        backgroundColor: backgroundColor ?? const Color(0xFF374151),
        textColor: textColor ?? Colors.white,
        icon: icon,
        duration: duration ?? const Duration(seconds: 3),
        onDismiss: () {
          _currentOverlay?.remove();
          _currentOverlay = null;
        },
      ),
    );

    // Insérer l'overlay
    Overlay.of(context).insert(_currentOverlay!);
  }

  /// Affiche un SnackBar d'erreur en haut
  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFDC2626), // Rouge
      icon: Icons.error_outline,
      duration: duration,
    );
  }

  /// Affiche un SnackBar de succès en haut
  static void showSuccessSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF10B981), // Vert
      icon: Icons.check_circle_outline,
      duration: duration,
    );
  }

  /// Affiche un SnackBar d'information en haut
  static void showInfoSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFF3B82F6), // Bleu
      icon: Icons.info_outline,
      duration: duration,
    );
  }

  /// Affiche un SnackBar d'avertissement en haut
  static void showWarningSnackBar(
    BuildContext context, {
    required String message,
    Duration? duration,
  }) {
    showTopSnackBar(
      context,
      message: message,
      backgroundColor: const Color(0xFFF59E0B), // Orange
      icon: Icons.warning_outlined,
      duration: duration,
    );
  }
}

class _TopSnackBar extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _TopSnackBar({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_TopSnackBar> createState() => _TopSnackBarState();
}

class _TopSnackBarState extends State<_TopSnackBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    // Démarrer l'animation d'entrée
    _controller.forward();

    // Programmer la fermeture automatique
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16, // Juste sous la status bar
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _opacityAnimation,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.backgroundColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      color: widget.textColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: widget.textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      color: widget.textColor.withOpacity(0.7),
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 