import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../services/localized_exercise_service.dart';
import '../../services/localization_service.dart';
import '../../services/translations.dart';

/// Widget d'exemple montrant l'utilisation complète du système de localisation
/// avec les vraies données d'exercices depuis Supabase
class LocalizedExerciseList extends StatefulWidget {
  final String? muscleGroup;
  
  const LocalizedExerciseList({
    super.key,
    this.muscleGroup,
  });

  @override
  State<LocalizedExerciseList> createState() => _LocalizedExerciseListState();
}

class _LocalizedExerciseListState extends State<LocalizedExerciseList> {
  List<Map<String, dynamic>> exercises = [];
  List<Map<String, dynamic>> cardioActivities = [];
  bool isLoading = true;
  String selectedTab = 'exercises'; // 'exercises' ou 'cardio'

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Écouter les changements de langue pour recharger les données
    LocalizationService.instance.addListener(_onLanguageChanged);
  }

  @override
  void dispose() {
    LocalizationService.instance.removeListener(_onLanguageChanged);
    super.dispose();
  }

  void _onLanguageChanged() {
    // Recharger les données quand la langue change
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    
    try {
      final results = await Future.wait([
        LocalizedExerciseService.getExercises(
          muscleGroup: widget.muscleGroup,
          limit: 20,
        ),
        LocalizedExerciseService.getCardioActivities(),
      ]);
      
      setState(() {
        exercises = results[0];
        cardioActivities = results[1];
        isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocalizationService>(
      builder: (context, locService, child) {
        return Column(
          children: [
            // Header avec indicateur de langue et tabs
            _buildHeader(locService),
            
            // Contenu principal
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : selectedTab == 'exercises'
                      ? _buildExercisesList(locService)
                      : _buildCardioList(locService),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader(LocalizationService locService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Indicateur de langue et titre
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: locService.isFrench ? Colors.blue.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  locService.isFrench ? '🇫🇷 Français' : '🇺🇸 English',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: locService.isFrench ? Colors.blue.shade700 : Colors.green.shade700,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                'workout'.tr(locService.currentLanguageCode),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              const Spacer(),
              // Bouton pour changer de langue (test)
              GestureDetector(
                onTap: () {
                  final newLang = locService.isFrench ? 'en' : 'fr';
                  locService.setLanguage(newLang);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Icon(
                    LucideIcons.languages,
                    size: 16,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Tabs
          Row(
            children: [
              Expanded(
                child: _buildTabButton(
                  'exercises',
                  'Exercices', // Sera traduit dynamiquement
                  LucideIcons.dumbbell,
                  locService,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildTabButton(
                  'cardio',
                  'Cardio',
                  LucideIcons.heart,
                  locService,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String tabId, String label, IconData icon, LocalizationService locService) {
    final isSelected = selectedTab == tabId;
    return GestureDetector(
      onTap: () => setState(() => selectedTab = tabId),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0B132B) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF0B132B) : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExercisesList(LocalizationService locService) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.dumbbell,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'no_data'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise, locService);
      },
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, LocalizationService locService) {
    final suffix = locService.getColumnSuffix();
    final name = exercise['name$suffix'] ?? 'Nom non disponible';
    final instructions = exercise['instructions$suffix'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF0B132B).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.dumbbell,
            size: 20,
            color: Color(0xFF0B132B),
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (exercise['muscle_group'] != null) ...[
              Text(
                exercise['muscle_group'],
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
            if (instructions.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                instructions.length > 100 
                    ? '${instructions.substring(0, 100)}...'
                    : instructions,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              children: [
                if (exercise['difficulty_level'] != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(exercise['difficulty_level']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exercise['difficulty_level'],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: _getDifficultyColor(exercise['difficulty_level']),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                if (exercise['equipment'] != null && exercise['equipment'].isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      exercise['equipment'],
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () => _showExerciseDetails(exercise, locService),
      ),
    );
  }

  Widget _buildCardioList(LocalizationService locService) {
    if (cardioActivities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.heart,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'no_data'.tr(locService.currentLanguageCode),
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: cardioActivities.length,
      itemBuilder: (context, index) {
        final activity = cardioActivities[index];
        return _buildCardioCard(activity, locService);
      },
    );
  }

  Widget _buildCardioCard(Map<String, dynamic> activity, LocalizationService locService) {
    final suffix = locService.getColumnSuffix();
    final name = activity['name$suffix'] ?? 'Nom non disponible';
    final description = activity['description$suffix'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            LucideIcons.heart,
            size: 20,
            color: Colors.red,
          ),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        subtitle: description.isNotEmpty
            ? Text(
                description.length > 80 
                    ? '${description.substring(0, 80)}...'
                    : description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                ),
              )
            : null,
        trailing: Icon(
          LucideIcons.chevronRight,
          size: 16,
          color: Colors.grey.shade400,
        ),
        onTap: () => _showCardioDetails(activity, locService),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showExerciseDetails(Map<String, dynamic> exercise, LocalizationService locService) {
    final suffix = locService.getColumnSuffix();
    final name = exercise['name$suffix'] ?? 'Nom non disponible';
    final instructions = exercise['instructions$suffix'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (exercise['muscle_group'] != null) ...[
                Text('Groupe musculaire: ${exercise['muscle_group']}'),
                const SizedBox(height: 8),
              ],
              if (exercise['equipment'] != null && exercise['equipment'].isNotEmpty) ...[
                Text('Équipement: ${exercise['equipment']}'),
                const SizedBox(height: 8),
              ],
              if (exercise['difficulty_level'] != null) ...[
                Text('Difficulté: ${exercise['difficulty_level']}'),
                const SizedBox(height: 8),
              ],
              if (instructions.isNotEmpty) ...[
                const Text(
                  'Instructions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(instructions),
                const SizedBox(height: 8),
              ],
              Text(
                'Langue actuelle: ${locService.isFrench ? "Français" : "English"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr(locService.currentLanguageCode)),
          ),
        ],
      ),
    );
  }

  void _showCardioDetails(Map<String, dynamic> activity, LocalizationService locService) {
    final suffix = locService.getColumnSuffix();
    final name = activity['name$suffix'] ?? 'Nom non disponible';
    final description = activity['description$suffix'] ?? '';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty) ...[
              Text(description),
              const SizedBox(height: 8),
            ],
            Text(
              'Clé d\'activité: ${activity['activity_key'] ?? 'N/A'}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Langue actuelle: ${locService.isFrench ? "Français" : "English"}',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr(locService.currentLanguageCode)),
          ),
        ],
      ),
    );
  }
}