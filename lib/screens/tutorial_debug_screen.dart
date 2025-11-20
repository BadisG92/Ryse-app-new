import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/tutorial_service.dart';

/// Écran de débogage pour tester et réinitialiser les tutoriels
/// Utile pour identifier pourquoi les tutoriels réapparaissent
class TutorialDebugScreen extends StatefulWidget {
  const TutorialDebugScreen({super.key});

  @override
  State<TutorialDebugScreen> createState() => _TutorialDebugScreenState();
}

class _TutorialDebugScreenState extends State<TutorialDebugScreen> {
  Map<String, dynamic> _supabaseData = {};
  Map<String, dynamic> _localData = {};
  bool _isLoading = false;
  String _logs = '';

  final List<String> _tutorialKeys = [
    'tutorial_dashboard_completed',
    'tutorial_nutrition_completed',
    'tutorial_sport_completed',
    'tutorial_cardio_completed',
    'tutorial_musculation_completed',
    'tutorial_progression_completed',
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _logs = '';
    });

    try {
      await _loadSupabaseData();
      await _loadLocalData();
    } catch (e) {
      _addLog('❌ Erreur: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _addLog(String message) {
    setState(() {
      _logs += '$message\n';
    });
    debugPrint(message);
  }

  Future<void> _loadSupabaseData() async {
    _addLog('📡 Chargement des données Supabase...');
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) {
      _addLog('⚠️ Aucun utilisateur connecté');
      return;
    }

    _addLog('✅ Utilisateur: ${user.id}');
    _addLog('📧 Email: ${user.email}');

    try {
      final response = await supabase
          .from('users')
          .select(_tutorialKeys.join(','))
          .eq('id', user.id)
          .single();

      _addLog('📦 Réponse Supabase: $response');

      setState(() {
        _supabaseData = Map<String, dynamic>.from(response);
      });

      for (final key in _tutorialKeys) {
        final value = response[key] as bool? ?? false;
        _addLog('  ├─ $key: $value');
      }
    } catch (e) {
      _addLog('❌ Erreur Supabase: $e');
    }
  }

  Future<void> _loadLocalData() async {
    _addLog('\n💾 Chargement des données locales (SharedPreferences)...');
    final prefs = await SharedPreferences.getInstance();

    final localData = <String, dynamic>{};
    for (final key in _tutorialKeys) {
      final value = prefs.getBool(key) ?? false;
      localData[key] = value;
      _addLog('  ├─ $key: $value');
    }

    setState(() {
      _localData = localData;
    });
  }

  Future<void> _resetAllTutorials() async {
    _addLog('\n🔄 Réinitialisation de tous les tutoriels...');
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Réinitialiser dans SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      for (final key in _tutorialKeys) {
        await prefs.remove(key);
      }
      _addLog('✅ SharedPreferences réinitialisé');

      // 2. Réinitialiser dans Supabase
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user != null) {
        final updates = <String, bool>{};
        for (final key in _tutorialKeys) {
          updates[key] = false;
        }

        await supabase.from('users').update(updates).eq('id', user.id);
        _addLog('✅ Supabase réinitialisé');
      }

      // 3. Recharger les données
      await _loadAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Tous les tutoriels ont été réinitialisés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur lors de la réinitialisation: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _syncSupabaseToLocal() async {
    _addLog('\n🔄 Synchronisation Supabase → Local...');
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      for (final key in _tutorialKeys) {
        final supabaseValue = _supabaseData[key] as bool? ?? false;
        await prefs.setBool(key, supabaseValue);
        _addLog('  ├─ $key: $supabaseValue');
      }

      _addLog('✅ Synchronisation terminée');
      await _loadAllData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Synchronisation terminée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _addLog('❌ Erreur: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Débogage Tutoriels'),
        backgroundColor: const Color(0xFF0B132B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _loadAllData,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Recharger les données'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _resetAllTutorials,
                            icon: const Icon(Icons.restore),
                            label: const Text('Réinitialiser tous les tutoriels'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: _syncSupabaseToLocal,
                            icon: const Icon(Icons.sync),
                            label: const Text('Synchroniser Supabase → Local'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Données Supabase
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📡 Données Supabase (Source de vérité)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildDataRows(_supabaseData),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Données locales
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '💾 Données Locales (SharedPreferences)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._buildDataRows(_localData),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Logs
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '📋 Logs de débogage',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[900],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: SelectableText(
                              _logs.isEmpty ? 'Aucun log pour le moment' : _logs,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12,
                                color: Colors.white,
                              ),
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

  List<Widget> _buildDataRows(Map<String, dynamic> data) {
    if (data.isEmpty) {
      return [
        const Text(
          'Aucune donnée',
          style: TextStyle(color: Colors.grey),
        ),
      ];
    }

    return _tutorialKeys.map((key) {
      final value = data[key] as bool? ?? false;
      final displayName = key.replaceAll('tutorial_', '').replaceAll('_completed', '');

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(displayName),
            ),
            Icon(
              value ? Icons.check_circle : Icons.cancel,
              color: value ? Colors.green : Colors.red,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              value ? 'Complété' : 'Non complété',
              style: TextStyle(
                color: value ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
