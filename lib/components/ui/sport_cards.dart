import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'custom_card.dart';
import 'sport_models.dart';
import '../../widgets/exercise/exercise_detail_page.dart';
import '../../services/translations.dart';
import '../../services/localization_service.dart';
import 'package:provider/provider.dart';

// Card pour les statistiques hebdomadaires individuelles
class WeeklyStatCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const WeeklyStatCard({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 85,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: _buildValueWithUnit(title),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildValueWithUnit(String value) {
    // Séparer la valeur de l'unité (ex: "150 kg" -> "150" + "kg")
    final parts = value.split(' ');
    if (parts.length >= 2) {
      final mainValue = parts[0];
      final unit = parts.sublist(1).join(' ');

      // Calculer la taille de police dynamiquement selon la longueur du nombre
      // Réduction des tailles pour que 233 kcal passe dans la boîte
      double fontSize = 20;
      if (mainValue.length >= 6) {
        fontSize = 12; // Très grands nombres (6+ chiffres)
      } else if (mainValue.length >= 5) {
        fontSize = 14; // Grands nombres (5 chiffres)
      } else if (mainValue.length >= 4) {
        fontSize = 16; // Nombres moyens (4 chiffres)
      } else if (mainValue.length >= 3) {
        fontSize = 18; // Nombres à 3 chiffres (comme 233)
      }

      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              mainValue,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0B132B),
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      );
    } else {
      // Pas d'unité, calculer la taille dynamiquement aussi
      double fontSize = 20;
      if (value.length >= 6) {
        fontSize = 12;
      } else if (value.length >= 5) {
        fontSize = 14;
      } else if (value.length >= 4) {
        fontSize = 16;
      } else if (value.length >= 3) {
        fontSize = 18;
      }

      return Flexible(
        child: Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0B132B),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

// Card principale pour les statistiques de la semaine
class WeeklyStatsCard extends StatelessWidget {
  final WeeklyStats stats;

  const WeeklyStatsCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.calendar,
                  size: 20,
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Consumer<LocalizationService>(
                  builder: (context, locService, _) => Text(
                    'workout_this_week'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => WeeklyStatCard(
                      title: stats.sessions,
                      subtitle: 'workout_sessions_short'.tr(locService.currentLanguageCode),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => WeeklyStatCard(
                      title: stats.weight,
                      subtitle: 'workout_lifted_short'.tr(locService.currentLanguageCode),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Consumer<LocalizationService>(
                    builder: (context, locService, _) => WeeklyStatCard(
                      title: stats.calories,
                      subtitle: 'workout_burned_short'.tr(locService.currentLanguageCode),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Card pour l'historique des séances
class WorkoutHistoryCard extends StatefulWidget {
  final WorkoutSession session;
  final Function(String)? onDelete; // Callback pour supprimer la séance

  const WorkoutHistoryCard({
    super.key,
    required this.session,
    this.onDelete,
  });

  @override
  State<WorkoutHistoryCard> createState() => _WorkoutHistoryCardState();
}

class _WorkoutHistoryCardState extends State<WorkoutHistoryCard> {
  bool _expanded = false;

  Future<void> _confirmDelete() async {
    final locService = LocalizationService.instance;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('delete_session'.tr(locService.currentLanguageCode)),
        content: Text('delete_session_confirm'.tr(locService.currentLanguageCode)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel'.tr(locService.currentLanguageCode)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr(locService.currentLanguageCode)),
          ),
        ],
      ),
    );

    if (confirmed == true && widget.session.sessionId != null) {
      widget.onDelete?.call(widget.session.sessionId!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec titre et icône d'expansion
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      session.day,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Bouton de suppression
              if (session.sessionId != null)
                GestureDetector(
                  onTap: _confirmDelete,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      LucideIcons.x,
                      size: 16,
                      color: Color(0xFF888888),
                    ),
                  ),
                ),
              const SizedBox(width: 8),
              // Bouton d'expansion
              IconButton(
                onPressed: () => setState(() => _expanded = !_expanded),
                icon: Icon(
                  _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 18,
                  color: const Color(0xFF64748B),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                splashRadius: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Ligne durée + volume + calories
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(LucideIcons.clock, size: 14, color: Color(0xFF1A1A1A)),
                    const SizedBox(width: 6),
                    Text('${session.durationMinutes} min', style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A))),
                    const SizedBox(width: 12),
                    const Icon(LucideIcons.dumbbell, size: 14, color: Color(0xFF1A1A1A)),
                    const SizedBox(width: 6),
                    Text('${session.totalVolumeKg.toStringAsFixed(0)} kg', style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A))),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.flame, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      '${session.calories} kcal',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Consumer<LocalizationService>(
              builder: (context, locService, _) => Row(
                children: [
                  Expanded(
                    child: Text(
                      'exercise'.tr(locService.currentLanguageCode),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))
                    ),
                  ),
                  Text(
                    'workout_best_set'.tr(locService.currentLanguageCode),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A))
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            ...session.items.map((it) {
              final right = (it.weightKg != null && it.weightKg! > 0)
                  ? '${it.weightKg!.toStringAsFixed(1)} kg × ${it.reps}'
                  : '${it.reps} reps';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${it.setsCount} × ${it.name}',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(right, style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A))),
                  ],
                ),
              );
            }).toList(),
          ],
          
          const SizedBox(height: 8),
          
          // Retiré: Dernière utilisation
        ],
      ),
    );
  }
}

// Helper function to get full exercise data from name
Map<String, dynamic>? _getExerciseDataByName(String exerciseName) {
  // Les mêmes données que dans ExerciseListBottomSheet
  final exercisesList = [
    {
      'id': 1,
      'name': 'Développé couché',
      'muscleGroup': 'Pectoraux',
      'icon': null,
      'sessions': 24,
      'lastWeight': '85kg',
      'progress': '+12%',
      'isPositive': true,
      'data': [68, 70, 72, 75, 78, 80, 82, 85],
      'sessionHistory': [
        {
          'date': '2024-01-15',
          'weight': '85kg',
          'reps': '3x8',
          'rpe': 7,
        },
        {
          'date': '2024-01-12',
          'weight': '82kg',
          'reps': '3x8',
          'rpe': 6,
        },
        {
          'date': '2024-01-10',
          'weight': '80kg',
          'reps': '3x8',
          'rpe': 7,
        },
      ],
    },
    {
      'id': 2,
      'name': 'Squat',
      'muscleGroup': 'Jambes',
      'icon': null,
      'sessions': 18,
      'lastWeight': '120kg',
      'progress': '+18%',
      'isPositive': true,
      'data': [85, 90, 95, 100, 105, 110, 115, 120],
      'sessionHistory': [
        {
          'date': '2024-01-14',
          'weight': '120kg',
          'reps': '4x6',
          'rpe': 8,
        },
        {
          'date': '2024-01-11',
          'weight': '115kg',
          'reps': '4x6',
          'rpe': 7,
        },
        {
          'date': '2024-01-09',
          'weight': '110kg',
          'reps': '4x6',
          'rpe': 6,
        },
      ],
    },
    {
      'id': 3,
      'name': 'Soulevé de terre',
      'muscleGroup': 'Dos',
      'icon': null,
      'sessions': 20,
      'lastWeight': '140kg',
      'progress': '+15%',
      'isPositive': true,
      'data': [100, 110, 115, 120, 125, 130, 135, 140],
      'sessionHistory': [
        {
          'date': '2024-01-13',
          'weight': '140kg',
          'reps': '3x5',
          'rpe': 9,
        },
        {
          'date': '2024-01-10',
          'weight': '135kg',
          'reps': '3x5',
          'rpe': 8,
        },
        {
          'date': '2024-01-08',
          'weight': '130kg',
          'reps': '3x5',
          'rpe': 8,
        },
      ],
    },
    {
      'id': 4,
      'name': 'Tractions',
      'muscleGroup': 'Dos',
      'icon': null,
      'sessions': 22,
      'lastWeight': '+15kg',
      'progress': '+25%',
      'isPositive': true,
      'data': [0, 2, 5, 7, 8, 10, 12, 15],
      'sessionHistory': [
        {
          'date': '2024-01-14',
          'weight': '+15kg',
          'reps': '4x6',
          'rpe': 8,
        },
        {
          'date': '2024-01-11',
          'weight': '+12kg',
          'reps': '4x6',
          'rpe': 7,
        },
        {
          'date': '2024-01-09',
          'weight': '+10kg',
          'reps': '4x6',
          'rpe': 7,
        },
      ],
    },
  ];

  try {
    return exercisesList.firstWhere((exercise) => exercise['name'] == exerciseName);
  } catch (e) {
    return null;
  }
}

// Card pour la progression des exercices
class ExerciseProgressCard extends StatelessWidget {
  final ExerciseProgress progress;

  const ExerciseProgressCard({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            // Charger les détails réels depuis Supabase via un écran qui sait interroger par nom
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailPage(exerciseName: progress.name),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        progress.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      Consumer<LocalizationService>(
                        builder: (context, locService, _) => Text(
                          'sessions_count'.tr(locService.currentLanguageCode)
                              .replaceAll('{count}', progress.sessions.toString()),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      progress.current,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0B132B),
                      ),
                    ),
                    Text(
                      progress.progress,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 
