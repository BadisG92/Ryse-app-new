import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'ui/custom_card.dart';

class SportMusculation extends StatefulWidget {
  const SportMusculation({super.key});

  @override
  State<SportMusculation> createState() => _SportMusculationState();
}

class _SportMusculationState extends State<SportMusculation> {
  bool _isSessionActive = false;
  bool _isSessionCompleted = false;
  String _sessionName = '';
  String _sessionType = 'Full body';
  DateTime? _sessionStartTime;
  List<Map<String, dynamic>> _currentExercises = [];
  List<Map<String, dynamic>> _weekHistory = [];
  Map<int, bool> _exerciseExpansionState = {}; // Track expansion state for each exercise

  final List<String> _sessionTypes = ['Haut du corps', 'Bas du corps', 'Full body'];

  final List<Map<String, dynamic>> programs = [
    {
      'id': 1,
      'name': 'Push/Pull/Legs',
      'duration': '60-75 min',
      'frequency': '6 jours/semaine',
      'progress': '+12%',
      'exercises': [
        {'name': 'Développé couché', 'sets': 4, 'reps': '8-10', 'muscleGroup': 'Pectoraux'},
        {'name': 'Développé incliné', 'sets': 3, 'reps': '10-12', 'muscleGroup': 'Pectoraux'},
        {'name': 'Écarté poulie', 'sets': 3, 'reps': '12-15', 'muscleGroup': 'Pectoraux'},
        {'name': 'Développé militaire', 'sets': 4, 'reps': '8-10', 'muscleGroup': 'Épaules'},
      ],
      'lastUsed': 'Il y a 2 jours',
    },
    {
      'id': 2,
      'name': 'Upper/Lower',
      'duration': '45-60 min',
      'frequency': '4 jours/semaine',
      'progress': '+8%',
      'exercises': [
        {'name': 'Squat', 'sets': 4, 'reps': '6-8', 'muscleGroup': 'Jambes'},
        {'name': 'Soulevé de terre', 'sets': 4, 'reps': '6-8', 'muscleGroup': 'Dos'},
        {'name': 'Presse à cuisses', 'sets': 3, 'reps': '12-15', 'muscleGroup': 'Jambes'},
        {'name': 'Leg curl', 'sets': 3, 'reps': '12-15', 'muscleGroup': 'Jambes'},
      ],
      'lastUsed': 'Il y a 4 jours',
    },
  ];

  final List<Map<String, dynamic>> exerciseProgress = [
    {'name': 'Développé couché', 'current': '85kg', 'progress': '+12%', 'sessions': 24},
    {'name': 'Squat', 'current': '120kg', 'progress': '+18%', 'sessions': 18},
    {'name': 'Soulevé de terre', 'current': '140kg', 'progress': '+15%', 'sessions': 20},
    {'name': 'Tractions', 'current': '+15kg', 'progress': '+25%', 'sessions': 22},
  ];

  Color _getLevelColor(String level) {
    switch (level) {
      case 'Débutant':
        return const Color(0xFFDCFCE7); // green-100
      case 'Intermédiaire':
        return const Color(0xFF0B132B).withOpacity(0.1);
      case 'Avancé':
        return const Color(0xFFFECDCA); // red-100
      default:
        return const Color(0xFFF1F5F9); // gray-100
    }
  }

  Color _getLevelTextColor(String level) {
    switch (level) {
      case 'Débutant':
        return const Color(0xFF166534); // green-800
      case 'Intermédiaire':
        return const Color(0xFF0B132B);
      case 'Avancé':
        return const Color(0xFFDC2626); // red-800
      default:
        return const Color(0xFF64748B); // gray-600
    }
  }

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
            // 1. Bloc "Cette semaine"
            _buildWeeklyStats(),
            
            const SizedBox(height: 16),
            
            // 2. Bloc principal "Commencer une séance"
            if (!_isSessionActive && !_isSessionCompleted) ...[
              _buildStartSessionBlock(),
              const SizedBox(height: 16),
            ],
            
            // 3. Bloc "Suivi de séance en cours" (si séance active)
            if (_isSessionActive) ...[
              _buildSessionTracking(),
              const SizedBox(height: 16),
              _buildSessionExercises(),
              const SizedBox(height: 16),
            ],
            
            // 4. Bloc "Récapitulatif post-séance" (si séance terminée)
            if (_isSessionCompleted) ...[
              _buildSessionSummary(),
              const SizedBox(height: 16),
            ],
            
            // 5. Bloc "Historique de la semaine"
            _buildWeekHistory(),
            
            const SizedBox(height: 16),
            
            // 6. Bloc "Progression par exercice"
            _buildExerciseProgress(),
            
            // Padding bottom
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyStats() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette semaine',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildWeeklyCard(
                    title: '3',
                    subtitle: 'Séances réalisées',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeeklyCard(
                    title: '22 500 kg',
                    subtitle: 'Soulevés',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildWeeklyCard(
                    title: '1 240',
                    subtitle: 'Kcal brûlées',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyCard({
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0B132B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartSessionBlock() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Commencer une séance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showSessionChoiceModal,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.play, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Commencer une séance',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                  'Nom de la séance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Nom de la séance',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0B132B)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sessionName = nameController.text;
                      _showSessionTypeModal();
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
                      'Continuer',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  void _showSessionTypeModal() {
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
                'Type de séance',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Segmented Control
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: _sessionTypes.map((type) {
                    final isSelected = _sessionType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _sessionType = type;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? const Color(0xFF0B132B) : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            type,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: isSelected ? Colors.white : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startManualSession();
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
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  void _startManualSession() {
    setState(() {
      _isSessionActive = true;
      _isSessionCompleted = false;
      _sessionStartTime = DateTime.now();
      _currentExercises = [];
    });
  }

  void _showProgramsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
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
                'Choisir un programme',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              
              const SizedBox(height: 24),
              
              Expanded(
                child: ListView.builder(
                  itemCount: programs.length,
                  itemBuilder: (context, index) {
                    final program = programs[index];
                    return _buildProgramCard(program);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(Map<String, dynamic> program) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    program['name'],
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startProgramSession(program);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0B132B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: const Text('Commencer'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Aperçu des exercices (4 premiers)
            Text(
              'Aperçu des exercices:',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...(program['exercises'] as List).take(4).map((exercise) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0))
                    ),
                    child: Text(
                      '${exercise['name']} ${exercise['sets']}×${exercise['reps']}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _startProgramSession(Map<String, dynamic> program) {
    setState(() {
      _isSessionActive = true;
      _isSessionCompleted = false;
      _sessionName = program['name'];
      _sessionStartTime = DateTime.now();
      
      // Pré-remplir avec les exercices du programme
      _currentExercises = (program['exercises'] as List).map((exercise) {
        final sets = <Map<String, dynamic>>[];
        for (int i = 0; i < exercise['sets']; i++) {
          sets.add({
            'weight': '',
            'reps': exercise['reps'],
            'completed': false,
            'failed': false,
          });
        }
        
        return {
          'name': exercise['name'],
          'muscleGroup': exercise['muscleGroup'],
          'sets': sets,
        };
      }).toList();
    });
  }

  Widget _buildSessionTracking() {
    if (!_isSessionActive || _sessionStartTime == null) return const SizedBox();
    
    final duration = DateTime.now().difference(_sessionStartTime!);
    final totalSets = _currentExercises.fold<int>(
      0, 
      (sum, exercise) => sum + (exercise['sets'] as List).length,
    );
    final completedSets = _currentExercises.fold<int>(
      0,
      (sum, exercise) => sum + (exercise['sets'] as List).where((set) => set['completed'] == true).length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B132B), Color(0xFF1C2951)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B132B).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _sessionName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _buildSessionStat(
                      icon: LucideIcons.clock,
                      value: '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}',
                    ),
                    const SizedBox(width: 16),
                    _buildSessionStat(
                      icon: LucideIcons.dumbbell,
                      value: '${_currentExercises.length} exercices',
                    ),
                    const SizedBox(width: 16),
                    _buildSessionStat(
                      icon: LucideIcons.checkCircle,
                      value: '$completedSets/$totalSets séries',
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _completeSession,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B132B),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text(
              'Terminer',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionStat({
    required IconData icon,
    required String value,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

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
            
            ..._currentExercises.asMap().entries.map((entry) {
              final index = entry.key;
              final exercise = entry.value;
              return _buildExerciseCard(exercise, index);
            }).toList(),
            
            // Bouton ajouter exercice déplacé en bas
            const SizedBox(height: 8),
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
    final hasMultipleSeries = (exercise['sets'] as List).length > 1;
    final isExpanded = _exerciseExpansionState[exerciseIndex] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE2E8F0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          leading: Icon(
            isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
            size: 16,
            color: const Color(0xFF64748B),
          ),
          title: GestureDetector(
            onTap: () => _editExerciseName(exerciseIndex),
            child: Text(
              exercise['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          trailing: (hasMultipleSeries || (exercise['sets'] as List).isNotEmpty)
              ? Container(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: () => _removeExercise(exerciseIndex),
                    icon: const Icon(Icons.close, size: 18),
                    color: const Color(0xFF64748B),
                    padding: EdgeInsets.zero,
                  ),
                )
              : null,
          onExpansionChanged: (expanded) {
            setState(() {
              _exerciseExpansionState[exerciseIndex] = expanded;
            });
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: EdgeInsets.zero,
          children: [
            // Séparateur visuel
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: const Color(0xFFE2E8F0),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // En-têtes
                  const Row(
                    children: [
                      Expanded(child: Text('Poids (kg)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
                      Expanded(child: Text('Reps', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)))),
                      SizedBox(width: 40), // Checkbox complété
                      SizedBox(width: 40), // X supprimer série
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Séries
                  ...(exercise['sets'] as List).asMap().entries.map((setEntry) {
                    final setIndex = setEntry.key;
                    final set = setEntry.value;
                    return _buildSetRow(exerciseIndex, setIndex, set);
                  }).toList(),
                  
                  const SizedBox(height: 16),
                  
                  // Bouton ajouter série
                  TextButton.icon(
                    onPressed: () => _addSet(exerciseIndex),
                    icon: const Icon(LucideIcons.plus, size: 16),
                    label: const Text('Ajouter une série'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF0B132B),
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

  Widget _buildSetRow(int exerciseIndex, int setIndex, Map<String, dynamic> set) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          // Poids
          Expanded(
            child: TextField(
              controller: TextEditingController(text: set['weight']),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (value) => set['weight'] = value,
              decoration: InputDecoration(
                hintText: 'Poids',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Répétitions
          Expanded(
            child: TextField(
              controller: TextEditingController(text: set['reps']),
              keyboardType: TextInputType.number,
              onChanged: (value) => set['reps'] = value,
              decoration: InputDecoration(
                hintText: 'Reps',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: Color(0xFF0B132B), width: 2),
                ),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Checkbox série complétée
          GestureDetector(
            onTap: () {
              setState(() {
                set['completed'] = !set['completed'];
                if (set['completed']) set['failed'] = false;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: set['completed'] ? const Color(0xFF0B132B) : Colors.transparent,
                border: Border.all(
                  color: set['completed'] ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: set['completed']
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
          
          const SizedBox(width: 8),
          
          // X pour supprimer la série - aligné dans la colonne de droite
          Container(
            width: 32,
            height: 32,
            child: IconButton(
              onPressed: () => _removeSet(exerciseIndex, setIndex),
              icon: const Icon(Icons.close, size: 18),
              color: const Color(0xFF64748B),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  void _addExercise() {
    _showExerciseSelectionModal();
  }

  void _showExerciseSelectionModal() {
    final TextEditingController searchController = TextEditingController();
    final ValueNotifier<int> selectedSets = ValueNotifier<int>(3);
    
    // Liste d'exercices prédéfinis
    final allExercises = [
      {'name': 'Développé couché', 'muscleGroup': 'Pectoraux'},
      {'name': 'Développé incliné', 'muscleGroup': 'Pectoraux'},
      {'name': 'Écarté couché', 'muscleGroup': 'Pectoraux'},
      {'name': 'Squat', 'muscleGroup': 'Jambes'},
      {'name': 'Presse à cuisses', 'muscleGroup': 'Jambes'},
      {'name': 'Leg curl', 'muscleGroup': 'Jambes'},
      {'name': 'Soulevé de terre', 'muscleGroup': 'Dos'},
      {'name': 'Tractions', 'muscleGroup': 'Dos'},
      {'name': 'Rowing', 'muscleGroup': 'Dos'},
      {'name': 'Développé militaire', 'muscleGroup': 'Épaules'},
      {'name': 'Élévations latérales', 'muscleGroup': 'Épaules'},
      {'name': 'Curl biceps', 'muscleGroup': 'Bras'},
      {'name': 'Extensions triceps', 'muscleGroup': 'Bras'},
    ];
    
    final ValueNotifier<List<Map<String, dynamic>>> filteredExercises = 
        ValueNotifier<List<Map<String, dynamic>>>(allExercises);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
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
                  'Ajouter un exercice',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Champ de recherche
                TextField(
                  controller: searchController,
                  onChanged: (value) {
                    filteredExercises.value = allExercises
                        .where((exercise) =>
                            exercise['name']!.toLowerCase().contains(value.toLowerCase()) ||
                            exercise['muscleGroup']!.toLowerCase().contains(value.toLowerCase()))
                        .toList();
                  },
                  decoration: InputDecoration(
                    hintText: 'Rechercher ou créer un exercice...',
                    prefixIcon: const Icon(LucideIcons.search, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF0B132B)),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Sélecteur nombre de séries
                Row(
                  children: [
                    const Text(
                      'Nombre de séries:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ValueListenableBuilder<int>(
                      valueListenable: selectedSets,
                      builder: (context, sets, _) {
                        return Row(
                          children: [1, 2, 3, 4, 5].map((number) {
                            final isSelected = sets == number;
                            return GestureDetector(
                              onTap: () => selectedSets.value = number,
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected ? const Color(0xFF0B132B) : Colors.transparent,
                                  border: Border.all(
                                    color: isSelected ? const Color(0xFF0B132B) : const Color(0xFFE2E8F0),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    number.toString(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: isSelected ? Colors.white : const Color(0xFF64748B),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Liste des exercices filtrés
                Expanded(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: filteredExercises,
                    builder: (context, exercises, _) {
                      return ListView(
                        children: [
                          // Option pour créer un nouvel exercice
                          if (searchController.text.isNotEmpty &&
                              !exercises.any((ex) => ex['name']!.toLowerCase() == searchController.text.toLowerCase()))
                            _buildExerciseOption(
                              name: searchController.text,
                              muscleGroup: 'Personnalisé',
                              isCustom: true,
                              onTap: () {
                                Navigator.pop(context);
                                _createExercise(
                                  searchController.text,
                                  'Personnalisé',
                                  selectedSets.value,
                                );
                              },
                            ),
                          
                          // Exercices existants
                          ...exercises.map((exercise) =>
                              _buildExerciseOption(
                                name: exercise['name']!,
                                muscleGroup: exercise['muscleGroup']!,
                                onTap: () {
                                  Navigator.pop(context);
                                  _createExercise(
                                    exercise['name']!,
                                    exercise['muscleGroup']!,
                                    selectedSets.value,
                                  );
                                },
                              )).toList(),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseOption({
    required String name,
    required String muscleGroup,
    required VoidCallback onTap,
    bool isCustom = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCustom ? const Color(0xFFF0F9FF) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
          border: isCustom ? Border.all(color: const Color(0xFF0B132B), width: 1) : null,
        ),
        child: Row(
          children: [
            if (isCustom)
              const Icon(LucideIcons.plus, size: 16, color: Color(0xFF0B132B)),
            if (isCustom) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCustom ? 'Créer "$name"' : name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isCustom ? const Color(0xFF0B132B) : const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    muscleGroup,
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
      ),
    );
  }

  void _createExercise(String name, String muscleGroup, int setsCount) {
    final sets = <Map<String, dynamic>>[];
    for (int i = 0; i < setsCount; i++) {
      sets.add({
        'weight': '',
        'reps': '',
        'completed': false,
        'failed': false,
      });
    }
    
    setState(() {
      _currentExercises.add({
        'name': name,
        'muscleGroup': muscleGroup,
        'sets': sets,
      });
    });
  }

  void _editExerciseName(int exerciseIndex) {
    // TODO: Implémenter l'édition inline du nom d'exercice
    // Pour l'instant, on peut juste afficher un message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Fonctionnalité d\'édition à venir'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _removeExercise(int index) {
    setState(() {
      _currentExercises.removeAt(index);
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      (_currentExercises[exerciseIndex]['sets'] as List).add({
        'weight': '',
        'reps': '',
        'completed': false,
        'failed': false,
      });
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    setState(() {
      (_currentExercises[exerciseIndex]['sets'] as List).removeAt(setIndex);
    });
  }

  void _completeSession() {
    setState(() {
      _isSessionActive = false;
      _isSessionCompleted = true;
    });
  }

  Widget _buildSessionSummary() {
    final sessionDuration = _sessionStartTime != null 
        ? DateTime.now().difference(_sessionStartTime!)
        : const Duration();
    
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
              'Bilan de la séance',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Statistiques
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildSummaryItem('Durée', '${sessionDuration.inMinutes} min'),
                      _buildSummaryItem('Exercices', '${_currentExercises.length}'),
                      _buildSummaryItem('Séries', '$completedSets/$totalSets'),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Liste des exercices
            ...(_currentExercises.isEmpty 
                ? [const Text('Aucun exercice complété')] 
                : _currentExercises.map((exercise) => _buildSummaryExercise(exercise)).toList()
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'action
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
                      // TODO: Enregistrer et partager
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
    return Expanded(
      child: Column(
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
      ),
    );
  }

  Widget _buildSummaryExercise(Map<String, dynamic> exercise) {
    final completedSets = (exercise['sets'] as List).where((set) => set['completed'] == true).length;
    final totalSets = (exercise['sets'] as List).length;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              exercise['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          Text(
            '$completedSets/$totalSets séries',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeekHistory() {
    // Données de démonstration
    final weekSessions = [
      {
        'name': 'Push/Pull/Legs',
        'day': 'Lundi',
        'calories': 340,
        'exercises': [
          'Développé couché 4×8-10',
          'Développé incliné 3×10-12',
          'Écarté poulie 3×12-15',
          'Développé militaire 4×8-10',
        ],
        'lastUsed': 'Il y a 2 jours',
      },
      {
        'name': 'Séance Jambes',
        'day': 'Mercredi',
        'calories': 420,
        'exercises': [
          'Squat 4×6-8',
          'Presse à cuisses 3×12-15',
          'Leg curl 3×12-15',
          'Mollets 4×15-20',
        ],
        'lastUsed': 'Il y a 4 jours',
      },
      {
        'name': 'Upper Body',
        'day': 'Vendredi',
        'calories': 380,
        'exercises': [
          'Tractions 4×6-8',
          'Rowing 4×8-10',
          'Curl biceps 3×12-15',
          'Extensions triceps 3×12-15',
        ],
        'lastUsed': 'Il y a 6 jours',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 0),
          child: Text(
            'Historique de la semaine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...weekSessions.map((session) => _buildHistoryCard(session)).toList(),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> session) {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session['name'],
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      session['day'],
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              // Bulle calories brûlées
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
                    const Icon(
                      LucideIcons.flame,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${session['calories']} kcal',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Aperçu des exercices
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: (session['exercises'] as List).map((exercise) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  exercise,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Dernière utilisation: ${session['lastUsed']}',
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseProgress() {
    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progression par exercice',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    // TODO: Voir tout
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B132B),
                  ),
                  child: const Text(
                    'Voir tout',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ...exerciseProgress.map((exercise) => _buildProgressCard(exercise)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(Map<String, dynamic> exercise) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                  exercise['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  '${exercise['sessions']} séances',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                exercise['current'],
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B132B),
                ),
              ),
              Text(
                exercise['progress'],
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
    );
  }
} 