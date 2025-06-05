import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'onboarding_models.dart';

// Card de sélection réutilisable améliorée
class SelectableCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? description;
  final bool isSelected;
  final VoidCallback onTap;

  const SelectableCard({
    super.key,
    required this.title,
    this.icon,
    this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B132B).withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B132B) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, size: 28, color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF64748B)),
            if (icon != null)
              const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A),
                    ),
                  ),
                  if (description != null && description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        description!,
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected ? const Color(0xFF0B132B).withOpacity(0.8) : const Color(0xFF64748B),
                          height: 1.3,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (isSelected)
              const SizedBox(width: 12),
            if (isSelected)
              const Icon(LucideIcons.checkCircle, color: Color(0xFF0B132B), size: 20),
          ],
        ),
      ),
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

// Input numérique optimisé mobile avec validation
class MobileNumberInput extends StatelessWidget {
  final String label;
  final String unit;
  final String value;
  final ValueChanged<String> onChanged;
  final IconData icon;
  final String? hint;

  const MobileNumberInput({
    super.key,
    required this.label,
    required this.unit,
    required this.value,
    required this.onChanged,
    required this.icon,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: TextEditingController(text: value)..selection = TextSelection.fromPosition(TextPosition(offset: value.length)),
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // CHIFFRES UNIQUEMENT
            ],
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: hint ?? 'Entrez votre $label',
              prefixIcon: Icon(icon, color: const Color(0xFF64748B)),
              suffixText: unit,
              suffixStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
      ],
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