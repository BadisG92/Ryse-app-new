import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/hiit_models.dart';
import 'hiit_session_screen.dart';

class HiitConfigScreen extends StatefulWidget {
  const HiitConfigScreen({super.key});

  @override
  State<HiitConfigScreen> createState() => _HiitConfigScreenState();
}

class _HiitConfigScreenState extends State<HiitConfigScreen> {
  final TextEditingController _workController = TextEditingController(text: '30');
  final TextEditingController _restController = TextEditingController(text: '30');
  final TextEditingController _durationController = TextEditingController(text: '15');

  @override
  void dispose() {
    _workController.dispose();
    _restController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  void _startCustomHiit() {
    final workDuration = int.tryParse(_workController.text) ?? 30;
    final restDuration = int.tryParse(_restController.text) ?? 30;
    final totalDuration = int.tryParse(_durationController.text) ?? 15;
    
    // Calculer le nombre de rounds
    final cycleTime = workDuration + restDuration;
    final totalRounds = (totalDuration * 60 / cycleTime).floor();

    final customWorkout = HiitWorkout(
      id: 'custom',
      title: 'HIIT personnalisé',
      description: '$totalDuration min - ${workDuration}s effort / ${restDuration}s repos',
      workDuration: workDuration,
      restDuration: restDuration,
      totalDuration: totalDuration,
      totalRounds: totalRounds,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HiitSessionScreen(
          workout: customWorkout,
          isFromCustomConfig: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: const Text(
          'HIIT personnalisé',
          style: TextStyle(
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
            const Text(
              'Configure ton entraînement',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            
            const SizedBox(height: 8),
            
            const Text(
              'Définis les paramètres de ton HIIT personnalisé',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
              ),
            ),
            
            const SizedBox(height: 32),

            // Durée totale
            _buildConfigSection(
              icon: LucideIcons.clock,
              title: 'Durée totale',
              subtitle: 'Combien de temps veux-tu t\'entraîner ?',
              controller: _durationController,
              unit: 'min',
            ),

            const SizedBox(height: 24),

            // Temps d'effort
            _buildConfigSection(
              icon: LucideIcons.flame,
              title: 'Temps d\'effort',
              subtitle: 'Durée de la phase d\'effort',
              controller: _workController,
              unit: 'sec',
            ),

            const SizedBox(height: 24),

            // Temps de repos
            _buildConfigSection(
              icon: LucideIcons.coffee,
              title: 'Temps de repos',
              subtitle: 'Durée de la phase de récupération',
              controller: _restController,
              unit: 'sec',
            ),

            const SizedBox(height: 32),

            // Aperçu
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B132B).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF0B132B).withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Aperçu de ta séance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreviewItem(
                    'Durée totale',
                    '${_durationController.text} minutes',
                  ),
                  _buildPreviewItem(
                    'Cycles',
                    _getEstimatedCycles(),
                  ),
                  _buildPreviewItem(
                    'Format',
                    '${_workController.text}s effort / ${_restController.text}s repos',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Bouton de démarrage
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _startCustomHiit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0B132B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.play, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Commencer l\'entraînement',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Espace en bas pour éviter l'overflow
            const SizedBox(height: 24),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildConfigSection({
    required IconData icon,
    required String title,
    required String subtitle,
    required TextEditingController controller,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0B132B),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
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
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    Text(
                      subtitle,
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
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF64748B),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  String _getEstimatedCycles() {
    final workDuration = int.tryParse(_workController.text) ?? 30;
    final restDuration = int.tryParse(_restController.text) ?? 30;
    final totalDuration = int.tryParse(_durationController.text) ?? 15;
    
    final cycleTime = workDuration + restDuration;
    final cycles = (totalDuration * 60 / cycleTime).floor();
    
    return '$cycles cycles';
  }
} 
