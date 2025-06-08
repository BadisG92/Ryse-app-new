import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'onboarding_models.dart';

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
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
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
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
                      !_isValid ? LucideIcons.alertCircle : LucideIcons.info,
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

// Écran de bienvenue avec stats
class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key});

  static const List<StatCard> _stats = [
    StatCard(value: '94%', label: 'Succès'),
    StatCard(value: '2.1M', label: 'Utilisateurs'),
    StatCard(value: '4.9★', label: 'Note App'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo stylisé
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF0B132B).withOpacity(0.1),
                    const Color(0xFF1C2951).withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.brain,
                size: 48,
                color: Colors.white,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 32),
        
        // Stats grid
        Row(
          children: _stats.map((stat) => 
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: stat == _stats.first ? 0 : 6,
                  right: stat == _stats.last ? 0 : 6,
                ),
                child: OnboardingStatCard(
                  value: stat.value,
                  label: stat.label,
                ),
              ),
            ),
          ).toList(),
        ),
        
        const SizedBox(height: 24),
        
        const Text(
          'En 5 minutes, créons votre plan nutrition personnalisé basé sur vos besoins réels',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF64748B),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
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
              // Icône stylisée
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0B132B).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.cpu,
                  size: 56,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '🧠 Ryze IA prépare votre plan...',
                style: TextStyle(
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
              const Text(
                'Personnalisation en cours...',
                style: TextStyle(
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