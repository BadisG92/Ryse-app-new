/// Écran de paramètres des notifications
library;

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../models/notification_models.dart';
import '../services/notification_service.dart';
import '../services/localization_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  late NotificationPreferences _prefs;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _loading = true);
    _prefs = _notificationService.getPreferences();
    setState(() => _loading = false);
  }

  Future<void> _savePreferences() async {
    await _notificationService.savePreferences(_prefs);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isGerman
              ? 'Einstellungen gespeichert ✓'
              : _isFrench
                  ? 'Paramètres enregistrés ✓'
                  : 'Settings saved ✓'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  bool get _isFrench => LocalizationService.instance.currentLanguageCode == 'fr';
  bool get _isGerman => LocalizationService.instance.currentLanguageCode == 'de';

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isGerman ? 'Benachrichtigungen' : _isFrench ? 'Notifications' : 'Notifications'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0E21),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isGerman ? 'Benachrichtigungen' : _isFrench ? 'Notifications' : 'Notifications',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Master toggle
            _buildMasterToggle(),
            const SizedBox(height: 24),

            // Quiet hours
            _buildQuietHours(),
            const SizedBox(height: 24),

            // Categories
            _buildCategorySection(
              title: _isGerman ? 'Mahlzeit-Erinnerungen' : _isFrench ? 'Rappels de repas' : 'Meal reminders',
              icon: LucideIcons.utensils,
              enabled: _prefs.mealRemindersEnabled,
              onToggle: (value) {
                setState(() => _prefs = _prefs.copyWith(mealRemindersEnabled: value));
                _savePreferences();
              },
              children: _prefs.mealRemindersEnabled
                  ? [
                      _buildTimePicker(
                        label: _isGerman ? 'Frühstück' : _isFrench ? 'Petit-déjeuner' : 'Breakfast',
                        hour: _prefs.breakfastTime,
                        onChanged: (value) {
                          setState(() => _prefs = _prefs.copyWith(breakfastTime: value));
                          _savePreferences();
                        },
                      ),
                      _buildTimePicker(
                        label: _isGerman ? 'Mittagessen' : _isFrench ? 'Déjeuner' : 'Lunch',
                        hour: _prefs.lunchTime,
                        onChanged: (value) {
                          setState(() => _prefs = _prefs.copyWith(lunchTime: value));
                          _savePreferences();
                        },
                      ),
                      _buildTimePicker(
                        label: _isGerman ? 'Abendessen' : _isFrench ? 'Dîner' : 'Dinner',
                        hour: _prefs.dinnerTime,
                        onChanged: (value) {
                          setState(() => _prefs = _prefs.copyWith(dinnerTime: value));
                          _savePreferences();
                        },
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 16),

            _buildCategorySection(
              title: _isGerman ? 'Flüssigkeitszufuhr' : _isFrench ? 'Hydratation' : 'Hydration',
              icon: LucideIcons.droplet,
              enabled: _prefs.waterRemindersEnabled,
              onToggle: (value) {
                setState(() => _prefs = _prefs.copyWith(waterRemindersEnabled: value));
                _savePreferences();
              },
              children: _prefs.waterRemindersEnabled
                  ? [
                      _buildFrequencyPicker(
                        label: _isGerman ? 'Häufigkeit pro Tag' : _isFrench ? 'Fréquence par jour' : 'Frequency per day',
                        value: _prefs.waterReminderFrequency,
                        onChanged: (value) {
                          setState(() => _prefs = _prefs.copyWith(waterReminderFrequency: value));
                          _savePreferences();
                        },
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 16),

            _buildCategorySection(
              title: _isGerman ? 'Serienfortschritt-Schutz' : _isFrench ? 'Protection de série' : 'Streak protection',
              icon: LucideIcons.flame,
              enabled: _prefs.streakProtectionEnabled,
              onToggle: (value) {
                setState(() => _prefs = _prefs.copyWith(streakProtectionEnabled: value));
                _savePreferences();
              },
              subtitle: _isGerman
                  ? 'Erinnert dich, eine Aktivität zu loggen, wenn du eine aktive Serie hast'
                  : _isFrench
                      ? 'Te rappelle de log une activité si tu as une série active'
                      : 'Reminds you to log an activity if you have an active streak',
            ),
            const SizedBox(height: 16),

            _buildCategorySection(
              title: _isGerman ? 'Tägliche Zusammenfassung' : _isFrench ? 'Résumé quotidien' : 'Daily summary',
              icon: LucideIcons.target,
              enabled: _prefs.dailyGoalsSummaryEnabled,
              onToggle: (value) {
                setState(() => _prefs = _prefs.copyWith(dailyGoalsSummaryEnabled: value));
                _savePreferences();
              },
              subtitle: _isGerman
                  ? 'Zusammenfassung deiner Ziele jeden Abend'
                  : _isFrench
                      ? 'Résumé de tes objectifs chaque soir'
                      : 'Summary of your goals each evening',
            ),
            const SizedBox(height: 16),

            _buildCategorySection(
              title: _isGerman ? 'Training' : _isFrench ? 'Entraînement' : 'Workout',
              icon: LucideIcons.dumbbell,
              enabled: _prefs.workoutRemindersEnabled,
              onToggle: (value) {
                setState(() => _prefs = _prefs.copyWith(workoutRemindersEnabled: value));
                _savePreferences();
              },
              children: _prefs.workoutRemindersEnabled
                  ? [
                      _buildTimePicker(
                        label: _isGerman ? 'Bevorzugte Zeit' : _isFrench ? 'Heure préférée' : 'Preferred time',
                        hour: _prefs.workoutReminderTime,
                        onChanged: (value) {
                          setState(() => _prefs = _prefs.copyWith(workoutReminderTime: value));
                          _savePreferences();
                        },
                      ),
                    ]
                  : null,
            ),
            const SizedBox(height: 16),

            _buildCategorySection(
              title: _isGerman ? 'Wöchentliche Zusammenfassung' : _isFrench ? 'Résumé hebdomadaire' : 'Weekly recap',
              icon: LucideIcons.calendar,
              enabled: _prefs.weeklyRecapEnabled,
              onToggle: (value) {
                setState(() => _prefs = _prefs.copyWith(weeklyRecapEnabled: value));
                _savePreferences();
              },
              subtitle: _isGerman
                  ? 'Jeden Sonntag um 18 Uhr'
                  : _isFrench
                      ? 'Chaque dimanche à 18h'
                      : 'Every Sunday at 6 PM',
            ),
            const SizedBox(height: 16),

            _buildCategorySection(
              title: _isGerman ? 'Meilensteine & Erfolge' : _isFrench ? 'Jalons & célébrations' : 'Milestones & celebrations',
              icon: LucideIcons.trophy,
              enabled: _prefs.milestonesEnabled,
              onToggle: (value) {
                setState(() => _prefs = _prefs.copyWith(milestonesEnabled: value));
                _savePreferences();
              },
              subtitle: _isGerman
                  ? 'Feiere deine Erfolge (Serien, perfekte Ziele)'
                  : _isFrench
                      ? 'Célèbre tes succès (séries, objectifs parfaits)'
                      : 'Celebrate your achievements (streaks, perfect goals)',
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildMasterToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _prefs.notificationsEnabled
                  ? const Color(0xFF6C63FF).withOpacity(0.2)
                  : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              LucideIcons.bell,
              color: _prefs.notificationsEnabled ? const Color(0xFF6C63FF) : Colors.grey,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isGerman ? 'Alle Benachrichtigungen' : _isFrench ? 'Toutes les notifications' : 'All notifications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isGerman
                      ? 'Alle Benachrichtigungen aktivieren oder deaktivieren'
                      : _isFrench
                          ? 'Active ou désactive toutes les notifications'
                          : 'Enable or disable all notifications',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _prefs.notificationsEnabled,
            onChanged: (value) {
              setState(() => _prefs = _prefs.copyWith(notificationsEnabled: value));
              _savePreferences();
            },
            activeColor: const Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  Widget _buildQuietHours() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.moonStar, color: Color(0xFF6C63FF), size: 20),
              const SizedBox(width: 12),
              Text(
                _isGerman ? 'Ruhezeiten' : _isFrench ? 'Heures silencieuses' : 'Quiet hours',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildTimeRangePicker(
                  label: _isGerman ? 'Beginn' : _isFrench ? 'Début' : 'Start',
                  hour: _prefs.quietHoursStart,
                  onChanged: (value) {
                    setState(() => _prefs = _prefs.copyWith(quietHoursStart: value));
                    _savePreferences();
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildTimeRangePicker(
                  label: _isGerman ? 'Ende' : _isFrench ? 'Fin' : 'End',
                  hour: _prefs.quietHoursEnd,
                  onChanged: (value) {
                    setState(() => _prefs = _prefs.copyWith(quietHoursEnd: value));
                    _savePreferences();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySection({
    required String title,
    required IconData icon,
    required bool enabled,
    required Function(bool) onToggle,
    String? subtitle,
    List<Widget>? children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1D1F33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6C63FF), size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: onToggle,
                  activeColor: const Color(0xFF6C63FF),
                ),
              ],
            ),
          ),
          if (children != null && enabled) ...[
            const Divider(color: Color(0xFF2A2D4A), height: 1),
            ...children,
          ],
        ],
      ),
    );
  }

  Widget _buildTimePicker({
    required String label,
    required int hour,
    required Function(int) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => _showTimePickerDialog(hour, onChanged),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2D4A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${hour.toString().padLeft(2, '0')}:00',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRangePicker({
    required String label,
    required int hour,
    required Function(int) onChanged,
  }) {
    return GestureDetector(
      onTap: () => _showTimePickerDialog(hour, onChanged),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2D4A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFrequencyPicker({
    required String label,
    required int value,
    required Function(int) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ),
          Row(
            children: [
              for (int i = 1; i <= 4; i++)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: GestureDetector(
                    onTap: () => onChanged(i),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: value == i
                            ? const Color(0xFF6C63FF)
                            : const Color(0xFF2A2D4A),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          '$i',
                          style: TextStyle(
                            color: value == i ? Colors.white : Colors.grey[400],
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showTimePickerDialog(int currentHour, Function(int) onChanged) async {
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: currentHour, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF6C63FF),
              surface: Color(0xFF1D1F33),
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      onChanged(time.hour);
    }
  }
}
