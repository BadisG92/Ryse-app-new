import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Service pour afficher des snackbars personnalisés sous le header
class CustomSnackbarService {
  static final CustomSnackbarService _instance = CustomSnackbarService._internal();
  static CustomSnackbarService get instance => _instance;
  CustomSnackbarService._internal();

  static OverlayEntry? _currentSnackbar;

  /// Affiche un snackbar personnalisé sous le header
  static void show(
    BuildContext context, {
    required String message,
    Color backgroundColor = const Color(0xFF0B132B),
    Color textColor = Colors.white,
    IconData? icon,
    Duration duration = const Duration(seconds: 3),
    bool isError = false,
  }) {
    // Fermer le snackbar actuel s'il existe
    hide();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _currentSnackbar = OverlayEntry(
      builder: (context) => _CustomSnackbarWidget(
        message: message,
        backgroundColor: isError ? Colors.red : backgroundColor,
        textColor: textColor,
        icon: icon ?? (isError ? LucideIcons.x : LucideIcons.check),
        duration: duration,
        onDismiss: hide,
      ),
    );

    overlay.insert(_currentSnackbar!);
  }

  /// Affiche un snackbar de succès
  static void showSuccess(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF10B981),
      icon: LucideIcons.check,
    );
  }

  /// Affiche un snackbar d'erreur
  static void showError(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: Colors.red,
      icon: LucideIcons.x,
      isError: true,
    );
  }

  /// Affiche un snackbar d'information
  static void showInfo(BuildContext context, String message) {
    show(
      context,
      message: message,
      backgroundColor: const Color(0xFF0B132B),
      icon: LucideIcons.info,
    );
  }

  /// Ferme le snackbar actuel
  static void hide() {
    _currentSnackbar?.remove();
    _currentSnackbar = null;
  }
}

/// Widget snackbar personnalisé
class _CustomSnackbarWidget extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismiss;

  const _CustomSnackbarWidget({
    required this.message,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_CustomSnackbarWidget> createState() => _CustomSnackbarWidgetState();
}

class _CustomSnackbarWidgetState extends State<_CustomSnackbarWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Animation d'entrée (slide down)
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_fadeController);

    // Démarrer les animations
    _slideController.forward();
    _fadeController.forward();

    // Auto-dismiss après duration
    Future.delayed(widget.duration, () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _slideController.reverse();
    await _fadeController.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60, // Sous le header
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            // Swipe vers le haut pour fermer
            onPanUpdate: (details) {
              if (details.delta.dy < -5) {
                _dismiss();
              }
            },
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: widget.backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.icon,
                      color: widget.textColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
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
                    // Indicateur swipe
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: widget.textColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.chevronUp,
                        color: widget.textColor.withOpacity(0.7),
                        size: 16,
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