import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/cardio_session_models.dart';
import '../services/cardio_service.dart';

class ManualCardioEntryScreen extends StatefulWidget {
  final String activityType;
  final String activityTitle;
  final String formatTitle;

  const ManualCardioEntryScreen({
    super.key,
    required this.activityType,
    required this.activityTitle,
    required this.formatTitle,
  });

  @override
  State<ManualCardioEntryScreen> createState() => _ManualCardioEntryScreenState();
}

class _ManualCardioEntryScreenState extends State<ManualCardioEntryScreen> {
  final TextEditingController _durationHoursController = TextEditingController(text: '0');
  final TextEditingController _durationMinutesController = TextEditingController(text: '30');
  final TextEditingController _distanceController = TextEditingController(text: '5.0');
  final TextEditingController _stepsController = TextEditingController(text: '3000');
  final TextEditingController _notesController = TextEditingController();
  
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
    final hours = int.tryParse(_durationHoursController.text) ?? 0;
    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
    final distance = double.tryParse(_distanceController.text) ?? 0.0;
    final steps = int.tryParse(_stepsController.text) ?? 0;

    if (minutes == 0 && hours == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une durée valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une distance valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pour la marche, vérifier aussi les pas
    if (widget.activityType == 'walking' && steps <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer un nombre de pas valide'),
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
    );

    // Afficher le résumé
    _showEntrySummary(entry);
  }

  void _showEntrySummary(ManualCardioEntry entry) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.check, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Séance enregistrée'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Activité: ${entry.activityTitle}'),
            Text('Format: ${entry.formatTitle}'),
            Text('Durée: ${_formatDuration(entry.duration)}'),
            Text('Distance: ${entry.distance.toStringAsFixed(2)} km'),
            if (widget.activityType == 'walking') ...[
              Text('Pas: ${entry.steps}'),
              if (entry.duration.inMinutes > 0)
                Text('Pas par minute: ${(entry.steps / entry.duration.inMinutes).toStringAsFixed(0)}'),
            ] else
              Text('Vitesse moyenne: ${entry.calculateAverageSpeed().toStringAsFixed(1)} km/h'),
            Text('Calories estimées: ${entry.calculateCalories()} kcal'),
            if (entry.notes != null) Text('Notes: ${entry.notes}'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              // Historiser la session dans Supabase
              try {
                await _saveManualSessionToSupabase(entry);
                debugPrint('✅ Session manuelle cardio sauvegardée');
              } catch (e) {
                debugPrint('❌ Erreur sauvegarde session manuelle: $e');
                // Continuer même en cas d'erreur pour ne pas bloquer l'utilisateur
              }
              
              Navigator.pop(context); // Fermer dialog
              Navigator.pop(context); // Retourner au cardio
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0B132B),
            ),
            child: const Text('Terminer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
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
  Future<void> _saveManualSessionToSupabase(ManualCardioEntry entry) async {
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
      
      await CardioService.saveCompletedCardioSession(
        sessionData: sessionData,
        intensity: 'Modéré', // Valeur par défaut
        notes: entry.notes,
      );
      
      // Invalider le cache pour rafraîchir les données
      CardioService.invalidateCache();
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
        title: Text(
          'Saisir ${widget.activityTitle.toLowerCase()}',
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
                title: 'Date de la séance',
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
                title: 'Durée de la séance',
                child: Row(
                  children: [
                    Expanded(
                      child: _buildTimeField(
                        controller: _durationHoursController,
                        label: 'Heures',
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeField(
                        controller: _durationMinutesController,
                        label: 'Minutes',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Distance
              _buildSection(
                title: 'Distance parcourue',
                child: _buildTextField(
                  controller: _distanceController,
                  label: 'Distance (km)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'km',
                ),
              ),

              const SizedBox(height: 24),

              // Nombre de pas (pour la marche uniquement)
              if (widget.activityType == 'walking') ...[
                _buildSection(
                  title: 'Nombre de pas',
                  child: _buildTextField(
                    controller: _stepsController,
                    label: 'Nombre de pas',
                    keyboardType: TextInputType.number,
                    suffix: 'pas',
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Notes (optionnel)
              _buildSection(
                title: 'Notes (optionnel)',
                child: _buildTextField(
                  controller: _notesController,
                  label: 'Commentaires sur la séance...',
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.save, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Enregistrer la séance',
                        style: TextStyle(
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
