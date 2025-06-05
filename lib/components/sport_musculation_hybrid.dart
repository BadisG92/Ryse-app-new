import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';
import 'ui/workout_widgets.dart';

class SportMusculationHybrid extends StatefulWidget {
  const SportMusculationHybrid({super.key});

  @override
  State<SportMusculationHybrid> createState() => _SportMusculationHybridState();
}

class _SportMusculationHybridState extends State<SportMusculationHybrid> {
  bool _isSessionActive = false;
  bool _isSessionCompleted = false;
  String _sessionName = '';
  String _sessionType = 'Full body';
  DateTime? _sessionStartTime;
  List<Map<String, dynamic>> _currentExercises = [];
  Map<int, bool> _exerciseExpansionState = {};

  final List<String> _sessionTypes = ['Haut du corps', 'Bas du corps', 'Full body'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Bloc "Cette semaine" (FACTORISÉ)
            const WeeklyStatsSection(),
            
            const SizedBox(height: 16),
            
            // 2. Bloc principal "Commencer une séance" (FACTORISÉ)
            if (!_isSessionActive && !_isSessionCompleted) ...[
              StartSessionButton(onPressed: _showSessionChoiceModal),
              const SizedBox(height: 16),
            ],
            
            // 3. Bloc "Suivi de séance en cours" (HYBRIDE - Card factorisée, logique intégrée)
            if (_isSessionActive) ...[
              SessionTrackingCard(
                sessionName: _sessionName,
                sessionStartTime: _sessionStartTime!,
                currentExercises: _currentExercises,
                onComplete: _completeSession,
              ),
              const SizedBox(height: 16),
              _buildSessionExercises(),
              const SizedBox(height: 16),
            ],
            
            // 4. Bloc "Récapitulatif post-séance" (INTÉGRÉ - logique spécifique)
            if (_isSessionCompleted) ...[
              _buildSessionSummary(),
              const SizedBox(height: 16),
            ],
            
            // 5. Bloc "Historique de la semaine" (FACTORISÉ)
            const WeekHistorySection(),
            
            const SizedBox(height: 16),
            
            // 6. Bloc "Progression par exercice" (FACTORISÉ)
            const ExerciseProgressSection(),
            
            // Padding bottom
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // SECTION INTÉGRÉE : Bottom sheets et logique de session (complexité élevée, spécifique)
  void _showSessionChoiceModal() {
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
              
              const Text(
                'Nouvelle séance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Options
              _buildSessionChoiceButton(
                icon: LucideIcons.edit3,
                title: 'Créer une séance manuellement',
                subtitle: 'Construire sa séance étape par étape',
                onTap: () {
                  Navigator.pop(context);
                  _showManualSessionFlow();
                },
              ),
              
              const SizedBox(height: 12),
              
              _buildSessionChoiceButton(
                icon: LucideIcons.bookOpen,
                title: 'Choisir un programme enregistré',
                subtitle: 'Utiliser un programme existant',
                onTap: () {
                  Navigator.pop(context);
                  _showProgramsModal();
                },
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSessionChoiceButton({
    required IconData icon,
    required String title,
    required String subtitle,
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
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: Color(0xFF64748B),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualSessionFlow() {
    _showSessionNameModal();
  }

  void _showSessionNameModal() {
    final TextEditingController nameController = TextEditingController();
    nameController.text = 'Séance du ${DateTime.now().day}/${DateTime.now().month}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
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
                
                const Text(
                  'Nom de la séance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    hintText: 'Nom de la séance',
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _startSession(nameController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Commencer la séance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProgramsModal() {
    // TODO: Implémenter modal des programmes
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Programmes à venir')),
    );
  }

  void _startSession(String name) {
    setState(() {
      _isSessionActive = true;
      _sessionName = name;
      _sessionStartTime = DateTime.now();
      _currentExercises = [];
    });
  }

  void _completeSession() {
    setState(() {
      _isSessionActive = false;
      _isSessionCompleted = true;
    });
  }

  // SECTION INTÉGRÉE : Exercices de session (logique complexe, état partagé)
  Widget _buildSessionExercises() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Exercices de la séance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (_currentExercises.isEmpty)
              const Center(
                child: Text(
                  'Aucun exercice ajouté',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF64748B),
                  ),
                ),
              )
            else
              ..._currentExercises.asMap().entries.map((entry) {
                final index = entry.key;
                final exercise = entry.value;
                return _buildExerciseCard(exercise, index);
              }).toList(),
            
            const SizedBox(height: 16),
            Center(
              child: TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Ajouter un exercice'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0B132B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(Map<String, dynamic> exercise, int exerciseIndex) {
    final isExpanded = _exerciseExpansionState[exerciseIndex] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        leading: Icon(
          isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
          size: 16,
          color: const Color(0xFF64748B),
        ),
        title: Text(
          exercise['name'] ?? 'Exercice',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A),
          ),
        ),
        trailing: IconButton(
          onPressed: () => _removeExercise(exerciseIndex),
          icon: const Icon(Icons.close, size: 18),
          color: const Color(0xFF64748B),
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _exerciseExpansionState[exerciseIndex] = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text('Détails de l\'exercice'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _addSet(exerciseIndex),
                  child: const Text('Ajouter une série'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addExercise() {
    setState(() {
      _currentExercises.add({
        'name': 'Nouvel exercice',
        'sets': [],
      });
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _currentExercises.removeAt(index);
      _exerciseExpansionState.remove(index);
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      (_currentExercises[exerciseIndex]['sets'] as List).add({
        'reps': 0,
        'weight': 0,
        'completed': false,
      });
    });
  }

  // SECTION INTÉGRÉE : Récapitulatif de session (logique spécifique)
  Widget _buildSessionSummary() {
    final duration = DateTime.now().difference(_sessionStartTime!);
    final totalSets = _currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise['sets'] as List).length,
    );
    final completedSets = _currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise['sets'] as List).where((set) => set['completed'] == true).length,
    );

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Séance terminée !',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    'Durée',
                    '${duration.inMinutes} min',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Exercices',
                    '${_currentExercises.length}',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    'Séries',
                    '$completedSets/$totalSets',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _isSessionCompleted = false;
                        _currentExercises.clear();
                        _sessionName = '';
                        _sessionStartTime = null;
                      });
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0B132B),
                      side: const BorderSide(color: Color(0xFF0B132B)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Nouvelle séance'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Séance enregistrée !')),
                      );
                      setState(() {
                        _isSessionCompleted = false;
                        _currentExercises.clear();
                        _sessionName = '';
                        _sessionStartTime = null;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0B132B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Enregistrer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF0B132B),
          ),
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