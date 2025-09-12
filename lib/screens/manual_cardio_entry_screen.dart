import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../models/cardio_session_models.dart';
import '../components/ui/numeric_text_field.dart';
import '../services/cardio_service.dart';
import '../services/translations.dart';
import '../services/localization_service.dart';

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
    final locService = LocalizationService.instance;
    final hours = int.tryParse(_durationHoursController.text) ?? 0;
    final minutes = int.tryParse(_durationMinutesController.text) ?? 0;
    final distance = double.tryParse(_distanceController.text) ?? 0.0;
    final steps = int.tryParse(_stepsController.text) ?? 0;

    if (minutes == 0 && hours == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_duration_required'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (distance <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('error_distance_required'.tr(locService.currentLanguageCode)),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Pour la marche, vérifier aussi les pas
    if (widget.activityType == 'walking' && steps <= 0) {
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
    );

    // Afficher le résumé
    _showEntrySummary(entry);
  }

  void _showEntrySummary(ManualCardioEntry entry) {
    final locService = LocalizationService.instance;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(LucideIcons.check, color: Color(0xFF10B981)),
            const SizedBox(width: 8),
            Text('manual_session_saved'.tr(locService.currentLanguageCode)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${'manual_activity_label'.tr(locService.currentLanguageCode)}: ${entry.activityTitle}'),
            Text('${'manual_format_label'.tr(locService.currentLanguageCode)}: ${entry.formatTitle}'),
            Text('${'manual_duration_label'.tr(locService.currentLanguageCode)}: ${_formatDuration(entry.duration)}'),
            Text('${'manual_distance_label'.tr(locService.currentLanguageCode)}: ${entry.distance.toStringAsFixed(2)} km'),
            if (widget.activityType == 'walking') ...[
              Text('${'manual_steps_label_result'.tr(locService.currentLanguageCode)}: ${entry.steps}'),
              if (entry.duration.inMinutes > 0)
                Text('${'manual_steps_per_minute'.tr(locService.currentLanguageCode)}: ${(entry.steps / entry.duration.inMinutes).toStringAsFixed(0)}'),
            ] else
              Text('${'manual_avg_speed'.tr(locService.currentLanguageCode)}: ${entry.calculateAverageSpeed().toStringAsFixed(1)} km/h'),
            Text('${'manual_estimated_calories'.tr(locService.currentLanguageCode)}: ${entry.calculateCalories()} kcal'),
            if (entry.notes != null) Text('${'manual_notes_label'.tr(locService.currentLanguageCode)}: ${entry.notes}'),
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
            child: Text('manual_finish'.tr(locService.currentLanguageCode), style: const TextStyle(color: Colors.white)),
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
      
      final locService = LocalizationService.instance;
      await CardioService.saveCompletedCardioSession(
        sessionData: sessionData,
        intensity: 'manual_intensity_moderate'.tr(locService.currentLanguageCode), // Valeur par défaut
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
                  label: 'manual_distance_km'.tr(locService.currentLanguageCode),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  suffix: 'km',
                ),
              ),

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
