import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/cardio_session_models.dart';
import '../components/ui/numeric_text_field.dart';
import '../services/cardio_service.dart';
import '../services/celebration_service.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';
import '../services/global_state_manager.dart';
import '../services/unit_service.dart';
import '../services/weekly_planner_service.dart';

class ManualCardioEntryScreen extends StatefulWidget {
  final String activityType;
  final String activityTitle;
  final String formatTitle;
  final CardioObjective? objective;

  const ManualCardioEntryScreen({
    super.key,
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
    this.objective,
  });

  @override
  State<ManualCardioEntryScreen> createState() => _ManualCardioEntryScreenState();
}

class _ManualCardioEntryScreenState extends State<ManualCardioEntryScreen> {
  late final TextEditingController _durationHoursController;
  late final TextEditingController _durationMinutesController;
  late final TextEditingController _distanceController;
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Intensité de l'effort (1=Faible, 2=Modéré, 3=Élevé, 4=Très élevé)
  int _intensity = 2;

  // Protection contre les double-clics lors de la sauvegarde
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    // Pré-remplir selon l'objectif choisi
    if (widget.objective != null) {
      if (widget.objective!.type == 'duration' && widget.objective!.targetDuration != null) {
        // Objectif durée : pré-remplir la durée, laisser distance vide
        final duration = widget.objective!.targetDuration!;
        _durationHoursController = TextEditingController(text: duration.inHours.toString());
        _durationMinutesController = TextEditingController(text: (duration.inMinutes % 60).toString());
        _distanceController = TextEditingController(); // Vide
      } else if (widget.objective!.type == 'distance' && widget.objective!.targetDistance != null) {
        // Objectif distance : pré-remplir la distance, laisser durée vide
        // Convertir de km (stockage) vers l'unité d'affichage
        final displayDistance = UnitService.instance.displayDistance(widget.objective!.targetDistance!);
        _durationHoursController = TextEditingController(); // Vide
        _durationMinutesController = TextEditingController(); // Vide
        _distanceController = TextEditingController(text: displayDistance.toStringAsFixed(1));
      } else {
        // Pas d'objectif spécifique, laisser vide
        _durationHoursController = TextEditingController();
        _durationMinutesController = TextEditingController();
        _distanceController = TextEditingController();
      }
    } else {
      // Pas d'objectif, laisser vide
      _durationHoursController = TextEditingController();
      _durationMinutesController = TextEditingController();
      _distanceController = TextEditingController();
    }

    // Écouter les changements pour mettre à jour le calcul en temps réel
    _durationHoursController.addListener(() => setState(() {}));
    _durationMinutesController.addListener(() => setState(() {}));
    _distanceController.addListener(() => setState(() {}));
  }
  
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _durationHoursController.dispose();
    _durationMinutesController.dispose();
    _distanceController.dispose();
    _stepsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveEntry() {
    // Protection contre les clics multiples
    if (_isSaving) {
      debugPrint('⚠️ Sauvegarde déjà en cours, ignoré');
      return;
    }

    final locService = LocalizationService.instance;
    final hours = int.tryParse(_durationHoursController.text) ?? 0;
    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
    // Convertir la distance saisie en km pour le stockage
    final distanceInput = double.tryParse(_distanceController.text) ?? 0.0;
    final distance = UnitService.instance.storageDistance(distanceInput);
    final steps = int.tryParse(_stepsController.text) ?? 0;

    // IMPORTANT: La durée est obligatoire pour calculer les calories
    // La distance est optionnelle (améliore la précision si fournie)
    if (minutes == 0 && hours == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_duration_required'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validation selon l'objectif si présent
    final bool isDurationObjective = widget.objective?.type == 'duration';
    final bool isDistanceObjective = widget.objective?.type == 'distance';

    // Si objectif distance spécifique, vérifier que la distance est renseignée
    if (isDistanceObjective && distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_distance_required'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pour la marche, vérifier aussi les pas si renseignés
    if (widget.activityType == 'walking' && steps <= 0 && _stepsController.text.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_steps_required'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final entry = ManualCardioEntry(
      activityType: widget.activityType,
      activityTitle: widget.activityTitle,
      formatTitle: widget.formatTitle,
      duration: Duration(hours: hours, minutes: minutes),
      distance: distance,
      steps: steps,
      date: _selectedDate,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      intensity: _intensity,
    );

    // Afficher le résumé
    _showEntrySummary(entry);
  }

  void _showEntrySummary(ManualCardioEntry entry) {
    final locService = LocalizationService.instance;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône de succès
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      LucideIcons.check,
                      size: 32,
                      color: Color(0xFF10B981),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'manual_session_saved'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'workout_session_summary'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF64748B),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),

                  // Métriques de la session cardio
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        // Activité + Format
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetricInDialog(
                                'manual_activity_label'.tr(locService.currentLanguageCode),
                                entry.activityTitle,
                                _getActivityIcon(),
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _buildSummaryMetricInDialog(
                                'manual_format_label'.tr(locService.currentLanguageCode),
                                entry.formatTitle,
                                LucideIcons.target,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),

                        // Durée + Distance
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetricInDialog(
                                'manual_duration_label'.tr(locService.currentLanguageCode),
                                _formatDuration(entry.duration),
                                LucideIcons.clock,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _buildSummaryMetricInDialog(
                                'manual_distance_label'.tr(locService.currentLanguageCode),
                                UnitService.instance.formatDistance(entry.distance),
                                LucideIcons.navigation,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                        const Divider(height: 1, color: Color(0xFFE2E8F0)),
                        const SizedBox(height: 16),

                        // Vitesse moyenne + Calories
                        Row(
                          children: [
                            Expanded(
                              child: _buildSummaryMetricInDialog(
                                widget.activityType == 'walking'
                                    ? 'manual_steps_label_result'.tr(locService.currentLanguageCode)
                                    : 'manual_avg_speed'.tr(locService.currentLanguageCode),
                                widget.activityType == 'walking'
                                    ? '${entry.steps}'
                                    : UnitService.instance.formatSpeed(entry.calculateAverageSpeed()),
                                widget.activityType == 'walking'
                                    ? LucideIcons.footprints
                                    : LucideIcons.gauge,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 40,
                              color: const Color(0xFFE2E8F0),
                            ),
                            Expanded(
                              child: _buildSummaryMetricInDialog(
                                'calories'.tr(locService.currentLanguageCode),
                                '${entry.calculateCalories()} kcal',
                                LucideIcons.flame,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton Terminer la séance
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : () async {
                        // Protection contre les double-clics
                        if (_isSaving) return;

                        setState(() {
                          _isSaving = true;
                        });

                        // Historiser la session dans Supabase
                        var savedSuccessfully = false;
                        String? sessionId;
                        try {
                          sessionId = await _saveManualSessionToSupabase(entry);
                          debugPrint('✅ Session manuelle cardio sauvegardée (id: $sessionId)');
                          savedSuccessfully = true;

                          // UNE SEULE mise à jour du GlobalState pour éviter les doublons
                          GlobalStateManager.instance.updateWorkout(true);
                          debugPrint('✅ GlobalStateManager: Cardio manuel marqué comme complété');

                          // WEEKLY PLANNER SYNC: Synchroniser avec le planificateur
                          try {
                            await WeeklyPlannerService.syncCardioSessionToPlanner(
                              sessionId: sessionId,
                              activityType: widget.activityType,
                              activityTitle: widget.activityTitle,
                              sessionDate: _selectedDate,
                              durationMinutes: entry.duration.inMinutes,
                              distanceKm: entry.distance > 0 ? entry.distance : null,
                            );
                            if (kDebugMode) debugPrint('✅ Weekly Planner: Cardio manuel sync effectuée');
                          } catch (plannerError) {
                            if (kDebugMode) debugPrint('⚠️ Erreur sync Weekly Planner: $plannerError');
                          }
                        } catch (e) {
                          debugPrint('❌ Erreur sauvegarde session manuelle: $e');
                          if (mounted) {
                            setState(() {
                              _isSaving = false;
                            });
                          }
                          // Continuer même en cas d'erreur pour ne pas bloquer l'utilisateur
                        }

                        // Fermer le dialog de synthèse
                        if (Navigator.canPop(dialogContext)) {
                          Navigator.pop(dialogContext);
                        }

                        // Retourner au cardio screen
                        if (mounted && Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }

                        // Afficher le CelebrationPopup (même design que les workouts)
                        if (savedSuccessfully) {
                          CelebrationService().celebrateCardioCompletionGlobal(
                            activityTitle: entry.activityTitle,
                            duration: entry.duration,
                            distanceKm: entry.distance,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0B132B),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              'session_end_session'.tr(locService.currentLanguageCode),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
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

  Widget _buildSummaryMetricInDialog(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF0B132B),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  void _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// Sauvegarde la session manuelle dans Supabase
  /// Retourne l'ID de la session créée
  Future<String> _saveManualSessionToSupabase(ManualCardioEntry entry) async {
    try {
      // Convertir l'entrée manuelle en CardioSessionData
      final sessionData = CardioSessionData(
        activityType: widget.activityType,
        activityTitle: widget.activityTitle,
        formatTitle: widget.formatTitle,
        startTime: _selectedDate.subtract(entry.duration),
        endTime: _selectedDate,
        duration: entry.duration,
        distance: entry.distance,
        steps: entry.steps,
        calories: entry.calculateCalories(),
        averageSpeed: entry.calculateAverageSpeed(),
        currentSpeed: entry.calculateAverageSpeed(),
      );

      // Utiliser l'intensité du slider pour la sauvegarde
      final locService = LocalizationService.instance;
      final intensityLabels = [
        'workout_intensity_low'.tr(locService.currentLanguageCode),      // 1
        'workout_intensity_moderate'.tr(locService.currentLanguageCode), // 2
        'workout_intensity_high'.tr(locService.currentLanguageCode),     // 3
        'workout_intensity_very_high'.tr(locService.currentLanguageCode),// 4
      ];

      final sessionId = await CardioService.saveCompletedCardioSession(
        sessionData: sessionData,
        intensity: intensityLabels[entry.intensity - 1],
        notes: entry.notes,
      );

      // Invalider le cache pour rafraîchir les données
      CardioService.invalidateCache();

      return sessionId;
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde manuelle: $e');
      rethrow;
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    
    if (duration.inHours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  Color _getActivityColor() {
    switch (widget.activityType) {
      case 'running':
      case 'bike':
      case 'walking':
        return const Color(0xFF1C2951); // Bleu secondaire pour toutes les activités
      default:
        return const Color(0xFF64748B); // Gris du thème
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, _) => Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            LucideIcons.arrowLeft,
            color: Color(0xFF1A1A1A),
          ),
        ),
        title: Text(
          '${'manual_entry_title'.tr(locService.currentLanguageCode)} ${widget.activityTitle.toLowerCase()}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _getActivityColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getActivityColor().withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _getActivityColor(),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getActivityIcon(),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.activityTitle,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          Text(
                            widget.formatTitle,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Date
              _buildSection(
                title: 'manual_session_date'.tr(locService.currentLanguageCode),
                child: GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.calendar,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          LucideIcons.chevronRight,
                          color: Color(0xFF64748B),
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Durée
              _buildSection(
                title: 'manual_session_duration'.tr(locService.currentLanguageCode),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTimeField(
                        controller: _durationHoursController,
                        label: 'manual_hours'.tr(locService.currentLanguageCode),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeField(
                        controller: _durationMinutesController,
                        label: 'manual_minutes'.tr(locService.currentLanguageCode),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Distance
              _buildSection(
                title: 'manual_distance_covered'.tr(locService.currentLanguageCode),
                child: _buildTextField(
                  controller: _distanceController,
                  label: '${'manual_distance_km'.tr(locService.currentLanguageCode)} (${UnitService.instance.distanceUnit})',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: UnitService.instance.distanceUnit,
                ),
              ),

              const SizedBox(height: 24),

              // Slider d'intensité
              _buildIntensitySlider(locService),

              const SizedBox(height: 24),

              // Estimation des calories en temps réel
              _buildCaloriesEstimation(locService),

              const SizedBox(height: 24),

              // Nombre de pas (pour la marche uniquement)
              if (widget.activityType == 'walking') ...[
                _buildSection(
                  title: 'manual_steps_count'.tr(locService.currentLanguageCode),
                  child: _buildTextField(
                    controller: _stepsController,
                    label: 'manual_steps_label'.tr(locService.currentLanguageCode),
                    keyboardType: TextInputType.number,
                    suffix: 'manual_unit_steps'.tr(locService.currentLanguageCode),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Notes (optionnel)
              _buildSection(
                title: 'manual_notes_optional'.tr(locService.currentLanguageCode),
                child: _buildTextField(
                  controller: _notesController,
                  label: 'manual_notes_placeholder'.tr(locService.currentLanguageCode),
                  maxLines: 3,
                ),
              ),

              const SizedBox(height: 40),

              // Bouton de sauvegarde
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveEntry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getActivityColor(),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.save, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'manual_save_session'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    ),
    );
  }

  /// Construit le sélecteur d'intensité avec slider (style séances IA)
  /// Masqué si une distance est fournie (calcul basé sur vitesse réelle)
  Widget _buildIntensitySlider(LocalizationService locService) {
    // Masquer si distance fournie
    final distance = double.tryParse(_distanceController.text) ?? 0.0;
    if (distance > 0) {
      return const SizedBox.shrink();
    }

    // Obtenir le label d'intensité actuel
    String getIntensityLabel() {
      switch (_intensity) {
        case 1:
          return 'workout_intensity_low'.tr(locService.currentLanguageCode);
        case 2:
          return 'workout_intensity_moderate'.tr(locService.currentLanguageCode);
        case 3:
          return 'workout_intensity_high'.tr(locService.currentLanguageCode);
        case 4:
          return 'workout_intensity_very_high'.tr(locService.currentLanguageCode);
        default:
          return 'workout_intensity_moderate'.tr(locService.currentLanguageCode);
      }
    }

    return _buildSection(
      title: 'cardio_intensity_label'.tr(locService.currentLanguageCode),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text(
            'cardio_intensity_description'.tr(locService.currentLanguageCode),
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),

          // Slider d'intensité avec 4 niveaux (comme dans ai_workout_generator_screen)
          Slider(
            value: (_intensity - 1) / 3, // Convertir 1-4 en 0.0-1.0
            onChanged: (value) {
              setState(() {
                // Convertir 0.0-1.0 en 1-4 avec arrondi
                _intensity = (value * 3).round() + 1;
              });
            },
            activeColor: const Color(0xFF0B132B),
            inactiveColor: const Color(0xFFE2E8F0),
            divisions: 3, // 4 positions: 0, 0.33, 0.67, 1.0
            label: getIntensityLabel(),
          ),

          // Labels aux extrémités du slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'workout_intensity_low'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
                Text(
                  'workout_intensity_very_high'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Construit l'affichage de l'estimation des calories en temps réel
  Widget _buildCaloriesEstimation(LocalizationService locService) {
    final hours = int.tryParse(_durationHoursController.text) ?? 0;
    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
    // Convertir la distance en km pour le calcul des calories
    final distanceInput = double.tryParse(_distanceController.text) ?? 0.0;
    final distance = UnitService.instance.storageDistance(distanceInput);

    // Calculer seulement si durée > 0
    if (hours == 0 && minutes == 0) {
      return const SizedBox.shrink();
    }

    final entry = ManualCardioEntry(
      activityType: widget.activityType,
      activityTitle: widget.activityTitle,
      formatTitle: widget.formatTitle,
      duration: Duration(hours: hours, minutes: minutes),
      distance: distance,
      date: _selectedDate,
      intensity: _intensity,
    );

    final calories = entry.calculateCalories();
    final isBasedOnSpeed = distance > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getActivityColor(),
            _getActivityColor().withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getActivityColor().withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              LucideIcons.flame,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'cardio_estimated_calories_realtime'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$calories',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 4),
                      child: Text(
                        'kcal',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                // Indicateur de méthode de calcul
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isBasedOnSpeed ? LucideIcons.gauge : LucideIcons.activity,
                        color: Colors.white,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isBasedOnSpeed
                            ? 'cardio_based_on_speed'.tr(locService.currentLanguageCode)
                            : 'cardio_based_on_intensity'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildTimeField({
    required TextEditingController controller,
    required String label,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: _getActivityColor()),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    String? suffix,
    int maxLines = 1,
  }) {
    // Utiliser NumericTextField si c'est un type numérique
    if (keyboardType != null && 
        (keyboardType == TextInputType.number || 
         keyboardType.toString().contains('number'))) {
      
      final isDecimal = keyboardType.toString().contains('decimal: true');
      
      return NumericTextField(
        controller: controller,
        allowDecimals: isDecimal,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: const TextStyle(
            color: Color(0xFF94A3B8),
          ),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _getActivityColor()),
          ),
          contentPadding: const EdgeInsets.all(16),
          suffixText: suffix,
          suffixStyle: const TextStyle(
            color: Color(0xFF64748B),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }
    
    // TextField normal pour les autres cas
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1A1A1A),
      ),
      decoration: InputDecoration(
        hintText: label,
        hintStyle: const TextStyle(
          color: Color(0xFF94A3B8),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _getActivityColor()),
        ),
        contentPadding: const EdgeInsets.all(16),
        suffixText: suffix,
        suffixStyle: const TextStyle(
          color: Color(0xFF64748B),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  IconData _getActivityIcon() {
    switch (widget.activityType) {
      case 'running':
        return LucideIcons.activity;
      case 'bike':
        return LucideIcons.bike;
      case 'walking':
        return LucideIcons.footprints;
      default:
        return LucideIcons.activity;
    }
  }
} 
