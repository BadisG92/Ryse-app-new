import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../../models/weekly_planner_models.dart';
import '../../services/weekly_planner_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import 'activity_chip_widget.dart';

/// Bottom sheet pour ajouter une activité au planner
class AddActivityBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final VoidCallback onActivityAdded;

  const AddActivityBottomSheet({
    super.key,
    required this.selectedDate,
    required this.onActivityAdded,
  });

  @override
  State<AddActivityBottomSheet> createState() => _AddActivityBottomSheetState();
}

class _AddActivityBottomSheetState extends State<AddActivityBottomSheet> {
  PlannedActivityType? _selectedMealType;
  bool _isWorkoutSelected = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final locService = context.watch<LocalizationService>();
    final langCode = locService.currentLanguageCode;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    // Vérifier si la date est éditable (pas dans le passé)
    final isEditable = isDateEditable(widget.selectedDate);

    return Container(
      padding: EdgeInsets.only(bottom: bottomPadding),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B132B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      LucideIcons.plus,
                      size: 20,
                      color: Color(0xFF0B132B),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'planner_add_activity'.tr(langCode),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                        Text(
                          _formatDate(widget.selectedDate, langCode),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(LucideIcons.x, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),

            if (!isEditable) ...[
              // Message pour jour passé
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.triangleAlert, size: 18, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'planner_past_day_warning'.tr(langCode),
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Section Repas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'planner_meals_section'.tr(langCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Options repas
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMealOption(PlannedActivityType.breakfast, 'planner_breakfast'.tr(langCode), isEditable),
                  _buildMealOption(PlannedActivityType.lunch, 'planner_lunch'.tr(langCode), isEditable),
                  _buildMealOption(PlannedActivityType.dinner, 'planner_dinner'.tr(langCode), isEditable),
                  _buildMealOption(PlannedActivityType.snack, 'planner_snack'.tr(langCode), isEditable),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Section Sport
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'planner_sport_section'.tr(langCode),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Options sport
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMealOption(PlannedActivityType.cardio, 'planner_cardio'.tr(langCode), isEditable),
                  _buildWorkoutOption('planner_workout'.tr(langCode), isEditable),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Bouton confirmer
            if (isEditable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_selectedMealType != null || _isWorkoutSelected) && !_isLoading
                        ? _handleAdd
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: const Color(0xFFE2E8F0),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'planner_confirm'.tr(langCode),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMealOption(PlannedActivityType type, String label, bool isEditable) {
    final isSelected = _selectedMealType == type;
    final color = type.color;

    return GestureDetector(
      onTap: isEditable
          ? () {
              setState(() {
                if (_selectedMealType == type) {
                  _selectedMealType = null;
                } else {
                  _selectedMealType = type;
                  _isWorkoutSelected = false;
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(0.15)
              : isEditable
                  ? Colors.white
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? color
                : const Color(0xFFE2E8F0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type.icon,
              size: 18,
              color: isEditable ? color : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isEditable
                    ? (isSelected ? color : const Color(0xFF0B132B))
                    : const Color(0xFF94A3B8),
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 6),
              Icon(Icons.check_circle, size: 16, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutOption(String label, bool isEditable) {
    const color = Color(0xFF0B132B);

    return GestureDetector(
      onTap: isEditable
          ? () {
              setState(() {
                _isWorkoutSelected = !_isWorkoutSelected;
                if (_isWorkoutSelected) {
                  _selectedMealType = null;
                }
              });
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isWorkoutSelected
              ? color.withOpacity(0.1)
              : isEditable
                  ? Colors.white
                  : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isWorkoutSelected
                ? color
                : const Color(0xFFE2E8F0),
            width: _isWorkoutSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center,
              size: 18,
              color: isEditable ? color : const Color(0xFF94A3B8),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: _isWorkoutSelected ? FontWeight.w600 : FontWeight.w500,
                color: isEditable
                    ? (_isWorkoutSelected ? color : const Color(0xFF0B132B))
                    : const Color(0xFF94A3B8),
              ),
            ),
            if (_isWorkoutSelected) ...[
              const SizedBox(width: 6),
              const Icon(Icons.check_circle, size: 16, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdd() async {
    setState(() => _isLoading = true);

    try {
      if (_selectedMealType != null) {
        // Ajouter une activité repas/cardio
        await WeeklyPlannerService.addPlannedActivity(
          plannedDate: widget.selectedDate,
          activityType: _selectedMealType!,
          activityData: {},
          isAiGenerated: false,
        );
      } else if (_isWorkoutSelected) {
        // Pour workout, on redirige vers la génération IA ou template
        // Pour l'instant, on crée un workout vide
        // TODO: Intégrer avec AIWorkoutGenerationService
        Navigator.pop(context);
        widget.onActivityAdded();
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onActivityAdded();
      }
    } catch (e) {
      debugPrint('Error adding activity: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatDate(DateTime date, String langCode) {
    final dayName = 'day_${date.weekday}'.tr(langCode);
    final monthName = 'month_${date.month}'.tr(langCode);
    return '$dayName ${date.day} $monthName';
  }
}
