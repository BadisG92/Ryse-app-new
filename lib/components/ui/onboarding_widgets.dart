import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'onboarding_models.dart';
import 'numeric_text_field.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

// Carte sélectionnable moderne avec animations fluides
class SelectableCard extends StatefulWidget {
  final String title;
  final String? description;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? selectedColor;

  const SelectableCard({
    super.key,
    required this.title,
    this.description,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.backgroundColor,
    this.selectedColor,
  });

  @override
  State<SelectableCard> createState() => _SelectableCardState();
}

class _SelectableCardState extends State<SelectableCard> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    if (widget.isSelected) {
      _animationController.forward();
    }
  }

  @override
  void didUpdateWidget(SelectableCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = widget.selectedColor ?? const Color(0xFF0B132B);
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? 0.96 : 1.0,
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: widget.isSelected 
                    ? selectedColor.withOpacity(0.08)
                    : widget.backgroundColor ?? Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: widget.isSelected 
                      ? selectedColor
                      : const Color(0xFFE2E8F0),
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: [
                  if (widget.isSelected)
                    BoxShadow(
                      color: selectedColor.withOpacity(0.15 * _glowAnimation.value),
                      blurRadius: 16 * _glowAnimation.value,
                      spreadRadius: 2 * _glowAnimation.value,
                      offset: const Offset(0, 4),
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                children: [
                  // Icône avec animation
                  if (widget.icon != null)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.isSelected 
                            ? selectedColor
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        widget.icon!,
                        size: 24,
                        color: widget.isSelected 
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                    ),
                  
                  if (widget.icon != null) const SizedBox(width: 16),
                  
                  // Contenu texte
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: widget.isSelected 
                                ? selectedColor
                                : const Color(0xFF1A1A1A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.description != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.description!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: widget.isSelected 
                                  ? selectedColor.withOpacity(0.7)
                                  : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Indicateur de sélection avec animation
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isSelected 
                          ? selectedColor
                          : Colors.transparent,
                      border: Border.all(
                        color: widget.isSelected 
                            ? selectedColor
                            : const Color(0xFFE2E8F0),
                        width: 2,
                      ),
                    ),
                    child: widget.isSelected
                        ? const Icon(
                            LucideIcons.check,
                            size: 14,
                            color: Colors.white,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// Card pour les statistiques
class OnboardingStatCard extends StatelessWidget {
  final String value;
  final String label;

  const OnboardingStatCard({
    super.key,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B132B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Expanded(
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Input numérique mobile moderne avec validation
class MobileNumberInput extends StatefulWidget {
  final String label;
  final String unit;
  final String value;
  final Function(String) onChanged;
  final IconData icon;
  final String? hint;
  final String? validationMessage;
  final int? minValue;
  final int? maxValue;

  const MobileNumberInput({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.hint,
    this.validationMessage,
    this.minValue,
    this.maxValue,
  });

  @override
  State<MobileNumberInput> createState() => _MobileNumberInputState();
}

class _MobileNumberInputState extends State<MobileNumberInput> 
    with SingleTickerProviderStateMixin {
  bool _isFocused = false;
  bool _hasValue = false;
  bool _isValid = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _colorAnimation;
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _hasValue = widget.value.isNotEmpty;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    
    _colorAnimation = ColorTween(
      begin: const Color(0xFF64748B),
      end: const Color(0xFF0B132B),
    ).animate(_animationController);
    
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
        if (_isFocused) {
          _animationController.forward();
        } else {
          _animationController.reverse();
        }
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateInput(String value) {
    setState(() {
      _hasValue = value.isNotEmpty;
      _isValid = true;
      
      if (value.isNotEmpty) {
        final numValue = int.tryParse(value);
        if (numValue != null) {
          if (widget.minValue != null && numValue < widget.minValue!) {
            _isValid = false;
          }
          if (widget.maxValue != null && numValue > widget.maxValue!) {
            _isValid = false;
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label avec animation
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: _isFocused 
                          ? const Color(0xFF0B132B).withOpacity(0.1)
                          : const Color(0xFF64748B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.icon, 
                      size: 16,
                      color: _colorAnimation.value,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _colorAnimation.value,
                    ),
                  ),
                  if (_hasValue && _isValid)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        LucideIcons.check,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Input field avec animations
            Transform.scale(
              scale: _scaleAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: !_isValid 
                        ? const Color(0xFFEF4444)
                        : _isFocused 
                            ? const Color(0xFF0B132B)
                            : _hasValue 
                                ? const Color(0xFF10B981)
                                : const Color(0xFFE2E8F0),
                    width: !_isValid || _isFocused ? 2 : 1,
                  ),
                  boxShadow: [
                    if (_isFocused)
                      BoxShadow(
                        color: const Color(0xFF0B132B).withOpacity(0.1),
                        blurRadius: 12,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      )
                    else
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: NumericTextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  allowDecimals: false,
                  onChanged: (value) {
                    _validateInput(value);
                    widget.onChanged(value);
                  },
                  decoration: InputDecoration(
                    hintText: widget.hint ?? 'Entrez votre ${widget.label.toLowerCase()}',
                    hintStyle: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade400,
                      fontWeight: FontWeight.w500,
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isFocused 
                            ? const Color(0xFF0B132B).withOpacity(0.1)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.unit,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _isFocused 
                              ? const Color(0xFF0B132B)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, 
                      vertical: 20,
                    ),
                  ),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            
            // Message de validation avec animation
            if (!_isValid || widget.validationMessage != null)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    Icon(
                      !_isValid ? LucideIcons.info : LucideIcons.info,
                      size: 14,
                      color: !_isValid 
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        !_isValid 
                            ? 'Valeur non valide'
                            : widget.validationMessage ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: !_isValid 
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

// Écran de bienvenue avec stats et animations
class WelcomeStep extends StatefulWidget {
  const WelcomeStep({super.key});

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep> 
    with TickerProviderStateMixin {
  late AnimationController _titleController;
  late AnimationController _logoController;
  late AnimationController _statsController;
  late Animation<double> _titleAnimation;
  late Animation<double> _logoAnimation;
  late Animation<double> _statsAnimation;
  late Animation<Offset> _titleSlideAnimation;

  @override
  void initState() {
    super.initState();
    
    _titleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _statsController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _titleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    ));
    
    _titleSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _titleController,
      curve: Curves.easeOut,
    ));
    
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));
    
    _statsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOut,
    ));
    
    // Démarrer les animations en cascade
    Future.delayed(const Duration(milliseconds: 200), () {
      _logoController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 400), () {
      _titleController.forward();
    });
    
    Future.delayed(const Duration(milliseconds: 800), () {
      _statsController.forward();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _logoController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) {
        final languageCode = locService.currentLanguageCode;
        
        final stats = [
          StatCard(value: '94%', label: 'onboarding_stats_success'.tr(languageCode)),
          StatCard(value: '2.1M', label: 'onboarding_stats_users'.tr(languageCode)),
          StatCard(value: '4.9★', label: 'onboarding_stats_rating'.tr(languageCode)),
        ];
        
        return Column(
          children: [
            // Logo Ryze avec animation
            AnimatedBuilder(
              animation: _logoAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _logoAnimation.value,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF0B132B),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0B132B).withOpacity(0.15 * _logoAnimation.value),
                          blurRadius: 24 * _logoAnimation.value,
                          spreadRadius: 0,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFF0B132B).withOpacity(0.08 * _logoAnimation.value),
                          blurRadius: 12 * _logoAnimation.value,
                          spreadRadius: -2,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(26),
                        child: SvgPicture.asset(
                          'assets/images/logo_solo.svg',
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            const SizedBox(height: 16),
            
            // Titre et tagline avec animation
            AnimatedBuilder(
              animation: _titleAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _titleAnimation,
                  child: SlideTransition(
                    position: _titleSlideAnimation,
                    child: Column(
                      children: [
                        Text(
                          'onboarding_welcome_title'.tr(languageCode),
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0B132B),
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'onboarding_welcome_tagline'.tr(languageCode),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Stats grid avec animation
            AnimatedBuilder(
              animation: _statsAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _statsAnimation,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - _statsAnimation.value)),
                    child: Row(
                      children: [
                        // Boîte 1: 94%
                        Expanded(
                          child: Container(
                            height: 80,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B132B).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '94%',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'onboarding_stats_success'.tr(languageCode),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Boîte 2: 2.1M
                        Expanded(
                          child: Container(
                            height: 80,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B132B).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '2.1M',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'onboarding_stats_users'.tr(languageCode),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Boîte 3: 4.9★
                        Expanded(
                          child: Container(
                            height: 80,
                            margin: const EdgeInsets.only(left: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0B132B).withOpacity(0.05),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '4.9★',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0B132B),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'onboarding_stats_rating'.tr(languageCode),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF64748B),
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 32),
            
            // Sous-titre en bas avec animation
            AnimatedBuilder(
              animation: _titleAnimation,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _titleAnimation,
                  child: SlideTransition(
                    position: _titleSlideAnimation,
                    child: Text(
                      'onboarding_welcome_subtitle'.tr(languageCode),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF0B132B),
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

// Écran de chargement avec animation et messages
class LoadingStep extends StatefulWidget {
  final String currentMessage;

  const LoadingStep({super.key, required this.currentMessage});

  @override
  State<LoadingStep> createState() => _LoadingStepState();
}

class _LoadingStepState extends State<LoadingStep> {
  @override
  Widget build(BuildContext context) {
    final languageCode = Provider.of<LocalizationService>(context, listen: false).currentLanguageCode;
    final isFrench = languageCode == 'fr';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8FAFC),
            Color(0xFFF1F5F9),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Panda statique mignon
              Image.asset(
                'assets/images/coach_ryze_loading.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 40),
              Text(
                isFrench ? 'Coach Ryze prépare ton plan...' : 'Coach Ryze is preparing your plan...',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return FadeTransition(opacity: animation, child: child);
                },
                child: Text(
                  widget.currentMessage,
                  key: ValueKey<String>(widget.currentMessage),
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF64748B),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 40),
              LinearProgressIndicator(
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0B132B)),
                backgroundColor: const Color(0xFF0B132B).withOpacity(0.2),
                minHeight: 6,
                borderRadius: BorderRadius.circular(3),
              ),
              const SizedBox(height: 16),
              Text(
                isFrench ? 'Encore quelques secondes...' : 'Just a few more seconds...',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Row pour affichage de macros
class MacroRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const MacroRow({
    super.key,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

// Row pour détails métaboliques
class DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHighlight;

  const DetailRow({
    super.key,
    required this.label,
    required this.value,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF64748B),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isHighlight ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }
} 
