import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'custom_card.dart';
import 'custom_button.dart';
import 'custom_badge.dart';
import 'scrollable_fade_container.dart';
import 'dashboard_models.dart';
import 'dashboard_cards.dart';
import 'global_progress_models.dart';
import 'nutrition_widgets.dart';
import '../shared/workout_actions.dart';
import '../../screens/ai_scanner_screen.dart';
import '../../screens/barcode_scanner_screen.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../screens/select_recipe_screen.dart';
import '../../screens/weight_evolution_screen.dart';
import '../../bottom_sheets/manual_food_search_bottom_sheet.dart';
import '../../bottom_sheets/editable_food_details_bottom_sheet.dart';
import '../../bottom_sheets/meal_selection_bottom_sheet.dart';
import '../../bottom_sheets/new_meal_type_bottom_sheet.dart';
import '../../models/nutrition_models.dart' as nutrition_models;
import '../../services/water_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';
import '../../services/cardio_service.dart';
import 'cardio_models.dart';
import 'cardio_widgets.dart';
import '../../models/hiit_models.dart';
import '../../models/cardio_session_models.dart';
import '../../screens/hiit_session_screen.dart';
import 'custom_snackbar.dart';
import '../../screens/hiit_config_screen.dart';
import '../../screens/cardio_tracking_screen.dart';
import '../../screens/manual_cardio_entry_screen.dart';

// Section des actions rapides
class QuickActionsSection extends StatefulWidget {
  final List<QuickAction> actions;

  const QuickActionsSection({
    super.key,
    required this.actions,
  });

  @override
  State<QuickActionsSection> createState() => _QuickActionsSectionState();
}

class _QuickActionsSectionState extends State<QuickActionsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'what_today'.tr(locService.currentLanguageCode),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Actions - Ligne horizontale scrollable avec effet fade
          SizedBox(
            height: 120, // Hauteur généreuse pour éviter tout overflow de texte
            child: ScrollableFadeContainer(
              controller: _scrollController,
              fadeWidth: 24.0,
              fadeColor: Colors.white,
              child: ListView.builder(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: widget.actions.length,
                itemBuilder: (context, index) {
                  final action = widget.actions[index];
                  // Créer une copie de l'action avec le bon callback
                  final actionWithCallback = QuickAction(
                    id: action.id,
                    label: action.label,
                    icon: action.icon,
                    reward: action.reward,
                    isDisabled: action.isDisabled,
                    isPremiumRequired: action.isPremiumRequired,
                    onTap: () => _handleQuickAction(context, action),
                  );
                  return QuickActionButton(action: actionWithCallback);
                },
              ),
            ),
          ),
          
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  void _handleQuickAction(BuildContext context, QuickAction action) {
    if (action.isDisabled || action.isPremiumRequired) {
      final locService = context.read<LocalizationService>();
      CustomSnackbarService.showInfo(
        context,
        'premium_feature'.tr(locService.currentLanguageCode),
      );
      return;
    }

    switch (action.id) {
      case 'add_meal':
        _showAddMealBottomSheet(context);
        break;
      case 'add_water':
        _handleAddWater(context);
        break;
      case 'take_photo':
        _showPhotoScanOptions(context);
        break;
      case 'cardio':
        _showCardioOptions(context);
        break;
      case 'musculation':
        _showMusculationOptions(context);
        break;
      case 'workout':
        _showWorkoutSelectionBottomSheet(context);
        break;
      case 'weight_tracking':
        _navigateToWeightEvolution(context);
        break;
    }
  }

  void _handleAddWater(BuildContext context) {
    // Utiliser exactement le même bottom sheet que le bouton + d'hydratation du dashboard nutrition
    NutritionBottomSheetHelper.showWaterSheet(context, _addWaterAmount);
  }

  void _addWaterAmount(int milliliters) async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      final locService = context.read<LocalizationService>();
      CustomSnackbarService.showError(
        context,
        'must_be_connected'.tr(locService.currentLanguageCode),
      );
      return;
    }

    try {
      // Ajouter l'entrée d'eau en base de données (même logique que le dashboard nutrition)
      final success = await WaterService.addWaterEntry(
        amount: milliliters,
        sourceType: _getSourceTypeFromAmount(milliliters),
      );

      if (!success) {
        throw Exception('Échec de l\'ajout d\'eau');
      }

      // Feedback visuel instantané
      final locService = context.read<LocalizationService>();
      CustomSnackbarService.showSuccess(
        context,
        '$milliliters ${'water_added'.tr(locService.currentLanguageCode)}',
      );
    } catch (e) {
      debugPrint('Erreur lors de l\'ajout d\'eau: $e');
      final locService = context.read<LocalizationService>();
      CustomSnackbarService.showError(
        context,
        'water_add_error'.tr(locService.currentLanguageCode),
      );
    }
  }

  // Méthode utilitaire pour déterminer le type de source selon la quantité (même que dashboard nutrition)
  String _getSourceTypeFromAmount(int milliliters) {
    switch (milliliters) {
      case 250:
        return 'glass';
      case 500:
        return 'bottle';
      case 750:
        return 'sports_bottle';
      case 200:
        return 'cup';
      case 1000:
        return 'bottle';
      default:
        return 'manual';
    }
  }

  void _showAddMealBottomSheet(BuildContext context) {
    // Utiliser exactement le même flux que le bouton + repas du dashboard nutrition
    NutritionQuickActionsSection.showMealSelectionForDashboard(context);
  }

  void _showPhotoScanOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'scan_food'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'scan_food_subtitle'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Les 2 boutons côte à côte
              Row(
                children: [
                  // Bouton Scanner un plat
                  Expanded(
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, child) => _buildScanOption(
                        context,
                        icon: LucideIcons.camera,
                        title: 'scan_dish'.tr(locService.currentLanguageCode),
                        subtitle: 'scan_dish_subtitle'.tr(locService.currentLanguageCode),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToAIScanner(context);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Bouton Scanner un code-barre
                  Expanded(
                    child: Consumer<LocalizationService>(
                      builder: (context, locService, child) => _buildScanOption(
                        context,
                        icon: LucideIcons.scan,
                        title: 'scan_barcode'.tr(locService.currentLanguageCode),
                        subtitle: 'scan_barcode_subtitle'.tr(locService.currentLanguageCode),
                        onTap: () {
                          Navigator.pop(context);
                          _navigateToBarcodeScannerScreen(context);
                        },
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScanOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 20,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 32,
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAIScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AIScannerScreen(isFromDashboard: true),
      ),
    );
  }

  void _navigateToBarcodeScannerScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );
  }

  void _showCardioOptions(BuildContext context) {
    // Utiliser exactement le même bottom sheet que dans le dashboard sport
    _showCardioBottomSheet(context);
  }

  void _showWorkoutSelectionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'training'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'training_choose_type'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 2 boutons côte à côte pour cardio et musculation
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Row(
                  children: [
                    Expanded(
                      child: _buildWorkoutTypeOption(
                        context,
                        icon: LucideIcons.activity,
                        title: 'training_cardio'.tr(locService.currentLanguageCode),
                        subtitle: 'training_cardio_subtitle'.tr(locService.currentLanguageCode),
                        onTap: () {
                          Navigator.pop(context);
                          _showCardioOptions(context);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildWorkoutTypeOption(
                        context,
                        icon: LucideIcons.dumbbell,
                        title: 'training_musculation'.tr(locService.currentLanguageCode),
                        subtitle: 'training_musculation_subtitle'.tr(locService.currentLanguageCode),
                        onTap: () {
                          Navigator.pop(context);
                          _showMusculationOptions(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutTypeOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B132B).withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B132B).withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showMusculationOptions(BuildContext context) {
    // Utiliser exactement le même bottom sheet que dans le dashboard sport
    WorkoutActions.showMusculationBottomSheet(context);
  }

  void _showCardioBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'training_cardio'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              
              const SizedBox(height: 8),
              
              Consumer<LocalizationService>(
                builder: (context, locService, child) => Text(
                  'cardio_choose_activity'.tr(locService.currentLanguageCode),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Utiliser les vraies activités cardio depuis Supabase
              _buildCardioActivitiesFromSupabase(context),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardioOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCardioActivitiesFromSupabase(BuildContext context) {
    return FutureBuilder<List<CardioActivityType>>(
      future: CardioService.getCardioActivities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return Consumer<LocalizationService>(
            builder: (context, locService, child) => Center(
              child: Text(
                'cardio_no_activities_available'.tr(locService.currentLanguageCode),
                style: const TextStyle(color: Color(0xFF64748B)),
              ),
            ),
          );
        }
        
        final activities = snapshot.data!;
        
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: activities.map((activity) {
            return SizedBox(
              width: (MediaQuery.of(context).size.width - 48 - 16) / 2, // (container width - padding - spacing) / 2
              child: _buildCardioOption(
                context,
                icon: _getIconFromName(activity.iconName),
                title: activity.name,
                onTap: () => _handleActivitySelection(context, activity),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'activity':
        return LucideIcons.activity;
      case 'bike':
        return LucideIcons.bike;
      case 'footprints':
        return LucideIcons.footprints;
      case 'flame':
        return LucideIcons.flame;
      case 'zap':
        return LucideIcons.zap;
      case 'target':
        return LucideIcons.target;
      case 'clock':
        return LucideIcons.clock;
      case 'mountain':
        return LucideIcons.mountain;
      case 'trending-up':
        return LucideIcons.trendingUp;
      case 'timer':
        return LucideIcons.timer;
      default:
        return LucideIcons.activity;
    }
  }

  void _handleActivitySelection(BuildContext context, CardioActivityType activity) {
    Navigator.pop(context); // Fermer le bottom sheet cardio
    _showActivityFormatsModal(context, activity);
  }

  void _showActivityFormatsModal(BuildContext context, CardioActivityType activity) {
    final formats = activity.formats.map((supabaseFormat) {
      return ActivityFormat(
        icon: _getIconFromName(supabaseFormat.iconName),
        title: supabaseFormat.name,
        description: supabaseFormat.description ?? '',
        trackable: supabaseFormat.isTrackable,
        configurable: supabaseFormat.isConfigurable,
        configType: supabaseFormat.configType ?? '',
        supabaseFormat: supabaseFormat,
      );
    }).toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityFormatsModal(
        activityTitle: activity.name,
        formats: formats,
        onFormatSelected: (format) {
          Navigator.pop(context);
          
          if (activity.activityKey == 'hiit') {
            _handleHiitSelection(context, format);
          } else if (format.configurable) {
            _showConfigurationModal(context, format, activity);
          } else {
            _showRecordingChoiceModal(context, format.title, format.trackable, activity: activity);
          }
        },
      ),
    );
  }

  void _handleHiitSelection(BuildContext context, ActivityFormat format) {
    if (format.configurable && format.configType == 'hiit') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const HiitConfigScreen(),
        ),
      );
    } else {
      HiitWorkout? workout;
      
      final supabaseFormat = format.supabaseFormat;
      if (supabaseFormat != null && supabaseFormat.isHiit) {
        workout = HiitWorkout(
          id: supabaseFormat.id,
          title: format.title,
          description: format.description,
          workDuration: supabaseFormat.hiitWorkSeconds ?? 30,
          restDuration: supabaseFormat.hiitRestSeconds ?? 30,
          totalDuration: supabaseFormat.defaultDurationMinutes ?? 15,
          totalRounds: supabaseFormat.hiitRounds ?? 15,
        );
      }
      
      if (workout != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HiitSessionScreen(workout: workout!),
          ),
        );
      }
    }
  }

  void _showConfigurationModal(BuildContext context, ActivityFormat format, CardioActivityType activity) {
    final locService = LocalizationService.instance;
    final config = CardioData.getLocalizedActivityConfigs(locService.currentLanguageCode)[format.configType];
    if (config == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ActivityConfigModal(
        config: config,
        onConfigSubmitted: (value) {
          Navigator.pop(context);
          
          CardioObjective? objective;
          if (config.type == 'distance') {
            objective = CardioObjective(
              type: 'distance',
              targetDistance: double.tryParse(value) ?? 0.0,
              activityType: format.title.toLowerCase(),
              formatTitle: '${format.title} ($value ${config.unit})',
            );
          } else if (config.type == 'duration') {
            objective = CardioObjective(
              type: 'duration',
              targetDuration: Duration(minutes: int.tryParse(value) ?? 0),
              activityType: format.title.toLowerCase(),
              formatTitle: '${format.title} ($value ${config.unit})',
            );
          }
          
          if (objective != null) {
            _showRecordingChoiceModal(context, objective.formatTitle, format.trackable, 
                objective: objective, activity: activity);
          }
        },
      ),
    );
  }

  void _showRecordingChoiceModal(BuildContext context, String formatTitle, bool isTrackable, 
      {CardioObjective? objective, required CardioActivityType activity}) {
    final locService = LocalizationService.instance;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Text(
                formatTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'cardio_choose_recording_method'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              if (isTrackable) ...[
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CardioTrackingScreen(
                            activityType: activity.activityKey,
                            activityTitle: activity.name,
                            formatTitle: formatTitle,
                            objective: objective,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.play, color: Colors.white),
                    label: Text(
                      'cardio_track_my_session'.tr(locService.currentLanguageCode),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
              ],
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ManualCardioEntryScreen(
                          activityType: activity.activityKey,
                          activityTitle: activity.name,
                          formatTitle: formatTitle,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.pencil, color: Color(0xFF0B132B)),
                  label: Text(
                    'cardio_declare_my_session'.tr(locService.currentLanguageCode),
                    style: const TextStyle(color: Color(0xFF0B132B), fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToWeightEvolution(BuildContext context) {
    final now = DateTime.now();
    final sampleEntries = [
      WeightEntry(date: now.subtract(const Duration(days: 30)), weight: 72.5),
      WeightEntry(date: now.subtract(const Duration(days: 25)), weight: 71.8),
      WeightEntry(date: now.subtract(const Duration(days: 20)), weight: 71.2),
      WeightEntry(date: now.subtract(const Duration(days: 15)), weight: 70.9),
      WeightEntry(date: now.subtract(const Duration(days: 10)), weight: 70.5),
      WeightEntry(date: now.subtract(const Duration(days: 5)), weight: 70.1),
      WeightEntry(date: now, weight: 69.8),
    ];

    final weightProgress = WeightProgress(
      currentWeight: 69.8,
      previousWeight: 72.5,
      initialWeight: 75.0,
      targetWeight: 68.0,
      entries: sampleEntries,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const WeightEvolutionScreen(),
      ),
    );
  }

  void _showManualEntryBottomSheet(BuildContext context) {
    ManualFoodSearchBottomSheet.show(
      context,
      isFromDashboard: true,
      onFoodCreated: (foodItem) {
        _handleDashboardFoodSelectionFromDetails(context, foodItem);
      },
    );
  }

  void _handleDashboardFoodSelectionFromDetails(BuildContext context, nutrition_models.FoodItem foodItem) {
    // Utiliser le nouveau flux unifié pour les aliments détectés
    NutritionQuickActionsSection.showMealSelectionWithDetectedFood(context, foodItem);
  }
}

// Section des objectifs journaliers
class DailyGoalsSection extends StatelessWidget {
  final List<DailyGoal> goals;
  final bool isPremium;

  const DailyGoalsSection({
    super.key,
    required this.goals,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    // Calculer les stats
    final completedGoals = goals.where((goal) => goal.completed).length;
    final totalGoals = goals.length;
    final completionRate = (completedGoals / totalGoals * 100).round();
    
    // Les objectifs sont considérés comme atteints si 3 sur 4 sont complétés
    final isGoalsAchieved = completedGoals >= 3;

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      LucideIcons.target, 
                      size: 20, 
                      color: Color(0xFF0B132B),
                    ),
                    const SizedBox(width: 12),
                    Consumer<LocalizationService>(
                      builder: (context, locService, child) => Text(
                        'dashboard_daily_goals'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  '$completedGoals/$totalGoals',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0B132B),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Goals list
            ...goals.map((goal) => DailyGoalItem(
              goal: goal,
              isPremium: isPremium,
            )).toList(),
          ],
        ),
      ),
    );
  }
}

// Section preview nutrition & sport
class ModulesPreviewSection extends StatelessWidget {
  final List<ModulePreview> modules;
  final Function(String moduleTitle)? onModuleTap;

  const ModulesPreviewSection({
    super.key,
    required this.modules,
    this.onModuleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: modules.map((module) => 
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(
              right: modules.indexOf(module) < modules.length - 1 ? 16 : 0,
            ),
            child: ModulePreviewCard(
              module: module,
              onTap: onModuleTap != null 
                ? () => onModuleTap!(module.title)
                : null,
            ),
          ),
        )
      ).toList(),
    );
  }
}

// Section statistiques communautaires
class CommunityStatsSection extends StatelessWidget {
  final CommunityStats stats;

  const CommunityStatsSection({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.users, 
                  size: 20, 
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Text(
                    'ryze_community'.tr(locService.currentLanguageCode),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => _buildCommunityStat(
                    stats.activeUsersText,
                    'active_members'.tr(locService.currentLanguageCode),
                    LucideIcons.users,
                  ),
                ),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => _buildCommunityStat(
                    stats.completedGoalsToday.toString(),
                    'goals_achieved'.tr(locService.currentLanguageCode),
                    LucideIcons.target,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.trendingUp, size: 16, color: Color(0xFF0B132B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '🔥 Challenge populaire : ${stats.topChallenge}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF1A1A1A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommunityStat(String value, String label, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: const Color(0xFF64748B)),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0B132B),
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF64748B),
          ),
        ),
      ],
    );
  }
}

// CTA Premium
class PremiumCTASection extends StatelessWidget {
  final VoidCallback? onUpgrade;

  const PremiumCTASection({
    super.key,
    this.onUpgrade,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.crown, 
                  size: 20, 
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          locService.currentLanguageCode == 'fr' 
                            ? 'Débloquez votre potentiel'
                            : 'Unlock your potential',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                      Consumer<LocalizationService>(
                        builder: (context, locService, child) => Text(
                          locService.currentLanguageCode == 'fr' 
                            ? 'Photos illimitées + Coach IA personnel'
                            : 'Unlimited photos + Personal AI Coach',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: DashboardData.premiumFeatures.map((feature) =>
                PremiumFeatureItem(
                  value: feature['value']!,
                  label: feature['label']!,
                )
              ).toList(),
            ),
            
            const SizedBox(height: 16),
            
            Consumer<LocalizationService>(
              builder: (context, locService, child) => CustomButton(
                text: 'try_7_days_free'.tr(locService.currentLanguageCode),
                icon: const Icon(LucideIcons.sparkles, size: 16, color: Colors.white),
                width: double.infinity,
                onPressed: onUpgrade,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Consumer<LocalizationService>(
              builder: (context, locService, child) => Text(
                'then_price_monthly'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Section Premium Insights (pour utilisateurs premium)
class PremiumInsightsSection extends StatelessWidget {
  final VoidCallback? onViewAnalytics;

  const PremiumInsightsSection({
    super.key,
    this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    return CustomCard(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0B132B).withOpacity(0.05),
              const Color(0xFF1C2951).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  LucideIcons.sparkles, 
                  size: 20, 
                  color: Color(0xFF0B132B),
                ),
                const SizedBox(width: 12),
                Consumer<LocalizationService>(
                  builder: (context, locService, child) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ai_coach'.tr(locService.currentLanguageCode),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                CustomBadge(
                  text: 'Premium',
                  backgroundColor: const Color(0xFF0B132B).withOpacity(0.1),
                  textColor: const Color(0xFF0B132B),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '🎯 Analyse personnalisée : Votre métabolisme est optimal entre 14h-16h. C\'est le moment idéal pour votre collation protéinée !',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF1A1A1A),
                  height: 1.4,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            CustomButton(
              text: 'Voir mes analytics avancés',
              icon: const Icon(LucideIcons.trendingUp, size: 16, color: Colors.white),
              width: double.infinity,
              onPressed: onViewAnalytics,
            ),
          ],
        ),
      ),
    );
  }
} 
