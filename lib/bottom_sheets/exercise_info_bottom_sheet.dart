import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/localized_exercise_service.dart';
import '../services/localization_service.dart';
import '../services/translations.dart';

/// Bottom sheet affichant les informations détaillées d'un exercice
/// (description, instructions étape par étape, lien tutoriel)
class ExerciseInfoBottomSheet {
  // Cache en mémoire pour les infos enrichies (persiste pendant la session)
  static final Map<String, Map<String, dynamic>> _cache = {};

  static void show(
    BuildContext context, {
    required String exerciseId,
    required String exerciseName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _ExerciseInfoContent(
        exerciseId: exerciseId,
        exerciseName: exerciseName,
        cachedData: _cache[exerciseId],
        onDataLoaded: (data) => _cache[exerciseId] = data,
      ),
    );
  }

  /// Vide le cache (à appeler lors du changement de langue)
  static void clearCache() {
    _cache.clear();
  }
}

class _ExerciseInfoContent extends StatefulWidget {
  final String exerciseId;
  final String exerciseName;
  final Map<String, dynamic>? cachedData;
  final void Function(Map<String, dynamic>)? onDataLoaded;

  const _ExerciseInfoContent({
    required this.exerciseId,
    required this.exerciseName,
    this.cachedData,
    this.onDataLoaded,
  });

  @override
  State<_ExerciseInfoContent> createState() => _ExerciseInfoContentState();
}

class _ExerciseInfoContentState extends State<_ExerciseInfoContent> {
  Map<String, dynamic>? _exerciseData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadExerciseInfo();
  }

  Future<void> _loadExerciseInfo() async {
    // Utiliser le cache si disponible
    if (widget.cachedData != null) {
      setState(() {
        _exerciseData = widget.cachedData;
        _isLoading = false;
      });
      return;
    }

    try {
      final data = await LocalizedExerciseService.getExerciseEnrichedDetails(
        widget.exerciseId,
      );

      if (mounted) {
        setState(() {
          _exerciseData = data;
          _isLoading = false;
        });

        // Sauvegarder dans le cache
        if (data != null) {
          widget.onDataLoaded?.call(data);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  List<String> _parseInstructions(String? instructions) {
    if (instructions == null || instructions.isEmpty) {
      return [];
    }
    return instructions.split('|').map((s) => s.trim()).toList();
  }

  Future<void> _openTutorialLink(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      // Fallback: essayer avec platformDefault
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        debugPrint('Impossible d\'ouvrir le lien: $e2');
      }
    }
  }

  String _translate(String key) {
    final lang = LocalizationService.instance.currentLanguageCode;
    return key.tr(lang);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5E5),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Header
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.transparent,
                          ),
                          child: const Icon(
                            LucideIcons.chevronLeft,
                            size: 20,
                            color: Color(0xFF0B132B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.exerciseName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Contenu principal
                  if (_isLoading)
                    _buildLoadingState()
                  else if (_error != null)
                    _buildErrorState()
                  else
                    _buildContent(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF0B132B),
              strokeWidth: 2,
            ),
            const SizedBox(height: 16),
            Text(
              _translate('exercise_loading'),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
const Icon(
              LucideIcons.circleAlert,
              size: 48,
              color: Color(0xFFEF4444),
            ),
            const SizedBox(height: 16),
            Text(
              _translate('exercise_error'),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final description = _exerciseData?['localized_description'] as String?;
    final instructions = _exerciseData?['localized_instructions'] as String?;
    final searchUrl = _exerciseData?['localized_search_url'] as String?;
    final muscleGroup = _exerciseData?['localized_muscle_group'] as String?;
    final equipment = _exerciseData?['equipment'] as String?;

    final steps = _parseInstructions(instructions);
    final hasContent = (description != null && description.isNotEmpty && description != 'Non disponible') ||
        steps.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Muscle group et equipment
        if (muscleGroup != null || equipment != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (muscleGroup != null && muscleGroup != 'Non disponible')
                  _buildTag(muscleGroup),
                if (equipment != null && equipment.isNotEmpty)
                  _buildTag(equipment),
              ],
            ),
          ),

        // Description
        if (description != null && description.isNotEmpty && description != 'Non disponible')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),

        // Instructions
        if (steps.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            _translate('exercise_how_to_perform'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          ...steps.asMap().entries.map((entry) => _buildStep(entry.key + 1, entry.value)),
        ],

        // Message si pas de contenu
        if (!hasContent)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  LucideIcons.info,
                  size: 32,
                  color: Color(0xFF64748B),
                ),
                const SizedBox(height: 12),
                Text(
                  _translate('exercise_no_instructions'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),

        // Bouton tutoriel
        if (searchUrl != null && searchUrl.isNotEmpty) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openTutorialLink(searchUrl),
              icon: const Icon(
                LucideIcons.externalLink,
                size: 18,
                color: Colors.white,
              ),
              label: Text(
                _translate('exercise_watch_tutorial'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
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
        ],

        // Padding bottom pour le safe area
        SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
      ],
    );
  }

  Widget _buildTag(String text) {
    // Design identique aux filter chips sélectionnés de exercise_selector_bottom_sheet.dart
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0B132B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF0B132B),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF0B132B),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
