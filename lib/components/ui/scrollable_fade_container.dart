import 'package:flutter/material.dart';

/// Widget réutilisable qui ajoute un effet de fade sur les côtés
/// pour indiquer qu'un contenu est scrollable horizontalement
class ScrollableFadeContainer extends StatefulWidget {
  final Widget child;
  final double fadeWidth;
  final Color fadeColor;
  final ScrollController? controller;

  const ScrollableFadeContainer({
    Key? key,
    required this.child,
    this.fadeWidth = 24.0,
    this.fadeColor = Colors.white,
    this.controller,
  }) : super(key: key);

  @override
  State<ScrollableFadeContainer> createState() => _ScrollableFadeContainerState();
}

class _ScrollableFadeContainerState extends State<ScrollableFadeContainer> {
  late ScrollController _scrollController;
  bool _showLeftFade = false;
  bool _showRightFade = true;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.controller ?? ScrollController();
    _scrollController.addListener(_onScroll);
    
    // Vérifier l'état initial après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateFadeVisibility();
    });
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    _updateFadeVisibility();
  }

  void _updateFadeVisibility() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    
    setState(() {
      // Fade gauche : visible si on peut scroller vers la gauche
      _showLeftFade = position.pixels > 0;
      
      // Fade droite : visible si on peut scroller vers la droite
      _showRightFade = position.pixels < position.maxScrollExtent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Contenu principal
        widget.child,
        
        // Fade gauche
        if (_showLeftFade)
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: widget.fadeWidth,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      widget.fadeColor,
                      widget.fadeColor.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        
        // Fade droite
        if (_showRightFade)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            width: widget.fadeWidth,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      widget.fadeColor.withOpacity(0.0),
                      widget.fadeColor,
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
} 
