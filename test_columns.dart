import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Initialiser Supabase
  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',
    anonKey: 'YOUR_ANON_KEY',
  );

  final client = Supabase.instance.client;

  // Faire une requête pour voir les colonnes disponibles
  try {
    final result = await client
        .from('workout_session_summaries')
        .select()
        .limit(1);

    if (result.isNotEmpty) {
      print('✅ Colonnes disponibles dans workout_session_summaries:');
      print(result.first.keys.toList());
    } else {
      print('⚠️ Table vide');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
