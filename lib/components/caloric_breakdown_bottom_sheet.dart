import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CaloricBreakdownBottomSheet extends StatefulWidget {
  final double bmr;
  final double activityFactor;
  final double objectiveDelta;

  const CaloricBreakdownBottomSheet({
    Key? key,
    required this.bmr,
    required this.activityFactor,
    required this.objectiveDelta,
  }) : super(key: key);

  @override
  State<CaloricBreakdownBottomSheet> createState() => _CaloricBreakdownBottomSheetState();
}

class _CaloricBreakdownBottomSheetState extends State<CaloricBreakdownBottomSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Calculs
    final activityCalories = widget.bmr * (widget.activityFactor - 1);
    final finalCalories = widget.bmr + activityCalories + widget.objectiveDelta;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre indicateur
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 20),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B132B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.calculator,
                          size: 20,
                          color: Color(0xFF0B132B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Détail du calcul',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Opération posée verticale
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0B132B).withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Ligne 1: BMR
                        _buildCalculationLine(
                          icon: LucideIcons.heart,
                          value: widget.bmr.round(),
                          label: 'Métabolisme de base (BMR)',
                          isFirst: true,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Ligne 2: Activité
                        _buildCalculationLine(
                          icon: LucideIcons.activity,
                          value: activityCalories.round(),
                          label: 'Activité physique (×${widget.activityFactor.toStringAsFixed(1)})',
                          isAddition: true,
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Ligne 3: Objectif
                        _buildCalculationLine(
                          icon: widget.objectiveDelta >= 0 
                              ? LucideIcons.trendingUp 
                              : LucideIcons.trendingDown,
                          value: widget.objectiveDelta.abs().round(),
                          label: widget.objectiveDelta >= 0 
                              ? 'Objectif (surplus)'
                              : 'Objectif (déficit)',
                          isAddition: widget.objectiveDelta >= 0,
                          isSubtraction: widget.objectiveDelta < 0,
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Ligne de séparation
                        Container(
                          height: 2,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0B132B),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Résultat final
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF0B132B),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                LucideIcons.target,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Résultat final :',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              '${finalCalories.round()} kcal/jour',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0B132B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationLine({
    required IconData icon,
    required int value,
    required String label,
    bool isFirst = false,
    bool isAddition = false,
    bool isSubtraction = false,
  }) {
    String prefix = '';
    if (isAddition) prefix = '+ ';
    if (isSubtraction) prefix = '- ';
    
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: const Color(0xFF0B132B),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ),
        Text(
          '$prefix$value kcal',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSubtraction 
                ? const Color(0xFFEF4444)
                : const Color(0xFF0B132B),
          ),
        ),
      ],
    );
  }
}

// Fonction helper pour afficher le bottom sheet
void showCaloricBreakdownBottomSheet({
  required BuildContext context,
  required double bmr,
  required double activityFactor,
  required double objectiveDelta,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => CaloricBreakdownBottomSheet(
      bmr: bmr,
      activityFactor: activityFactor,
      objectiveDelta: objectiveDelta,
    ),
  );
} 