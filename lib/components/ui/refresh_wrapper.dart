import 'package:flutter/material.dart';

/// Wrapper réutilisable pour ajouter pull-to-refresh à n'importe quel widget
class RefreshWrapper extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final Color? backgroundColor;

  const RefreshWrapper({
    super.key,
    required this.child,
    required this.onRefresh,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor ?? Colors.white,
      color: const Color(0xFF0B132B),
      strokeWidth: 2.5,
      displacement: 40.0,
      child: child,
    );
  }
}

/// Extension pour ajouter facilement pull-to-refresh à n'importe quel widget
extension RefreshableWidget on Widget {
  Widget withRefresh(Future<void> Function() onRefresh, {Color? backgroundColor}) {
    return RefreshWrapper(
      onRefresh: onRefresh,
      backgroundColor: backgroundColor,
      child: this,
    );
  }
}