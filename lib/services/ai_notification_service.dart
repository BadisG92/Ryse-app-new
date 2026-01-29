/// Service pour les notifications personnalisées générées par IA
/// 30% des notifications utilisent des messages IA pré-générés
library;

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'localization_service.dart';

/// Types de notifications supportés par l'IA
enum AiNotificationType {
  meal,
  water,
  streak,
  workout,
  progress,
}

/// Service singleton pour les notifications IA
class AiNotificationService {
  AiNotificationService._();
  static final AiNotificationService instance = AiNotificationService._();

  final _random = Random();

  /// Probabilité d'utiliser un message IA (30%)
  static const double aiMessageProbability = 0.30;

  /// Vérifie si on doit utiliser un message IA (30% de chance)
  bool shouldUseAiMessage() {
    return _random.nextDouble() < aiMessageProbability;
  }

  /// Récupère un message IA non utilisé pour ce type de notification
  /// Retourne null si aucun message disponible
  /// IMPORTANT: Filtre par langue pour éviter les messages dans la mauvaise langue
  Future<({String title, String body})?> getAiMessage(AiNotificationType type) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      // Récupérer la langue actuelle de l'utilisateur
      final currentLanguage = LocalizationService.instance.currentLanguageCode;

      // Récupérer un message non utilisé, non expiré ET dans la bonne langue
      final response = await Supabase.instance.client
          .from('ai_notifications_pool')
          .select('id, title, body')
          .eq('user_id', user.id)
          .eq('notification_type', type.name)
          .eq('locale', currentLanguage) // IMPORTANT: Filtre par langue (colonne = locale)
          .eq('used', false)
          .gt('expires_at', DateTime.now().toIso8601String())
          .limit(1)
          .maybeSingle();

      if (response == null) {
        if (kDebugMode) debugPrint('ℹ️ No AI message available for ${type.name}');
        return null;
      }

      // Marquer le message comme utilisé
      await Supabase.instance.client
          .from('ai_notifications_pool')
          .update({
            'used': true,
            'used_at': DateTime.now().toIso8601String(),
          })
          .eq('id', response['id']);

      if (kDebugMode) {
        debugPrint('✨ Using AI notification: ${response['title']}');
      }

      return (
        title: response['title'] as String,
        body: response['body'] as String,
      );
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error getting AI message: $e');
      return null;
    }
  }

  /// Récupère le contenu de notification (IA ou classique)
  /// Avec 30% de chance d'utiliser un message IA si disponible
  Future<({String title, String body})> getNotificationContent({
    required AiNotificationType type,
    required String defaultTitle,
    required String defaultBody,
  }) async {
    // 30% de chance d'essayer un message IA
    if (shouldUseAiMessage()) {
      final aiMessage = await getAiMessage(type);
      if (aiMessage != null) {
        return aiMessage;
      }
    }

    // Fallback sur message classique
    return (title: defaultTitle, body: defaultBody);
  }

  /// Compte le nombre de messages IA disponibles pour l'utilisateur
  Future<int> getAvailableAiMessagesCount() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return 0;

      final response = await Supabase.instance.client
          .from('ai_notifications_pool')
          .select('id')
          .eq('user_id', user.id)
          .eq('used', false)
          .gt('expires_at', DateTime.now().toIso8601String());

      return (response as List).length;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error counting AI messages: $e');
      return 0;
    }
  }

  /// Compte les messages disponibles par type
  Future<Map<AiNotificationType, int>> getAvailableAiMessagesByType() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return {};

      final response = await Supabase.instance.client
          .from('ai_notifications_pool')
          .select('notification_type')
          .eq('user_id', user.id)
          .eq('used', false)
          .gt('expires_at', DateTime.now().toIso8601String());

      final counts = <AiNotificationType, int>{};
      for (final row in response as List) {
        final typeName = row['notification_type'] as String;
        final type = AiNotificationType.values.firstWhere(
          (t) => t.name == typeName,
          orElse: () => AiNotificationType.meal,
        );
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error counting AI messages by type: $e');
      return {};
    }
  }

  /// Supprime tous les messages IA non utilisés (utile si l'utilisateur change de langue/personnalité)
  Future<void> clearUnusedMessages() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      await Supabase.instance.client
          .from('ai_notifications_pool')
          .delete()
          .eq('user_id', user.id)
          .eq('used', false);

      if (kDebugMode) debugPrint('🗑️ Cleared unused AI notification messages');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error clearing AI messages: $e');
    }
  }

  /// Demande la génération de nouveaux messages (appelle l'Edge Function)
  /// Normalement fait automatiquement par CRON, mais peut être appelé manuellement
  Future<bool> requestNewMessages() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'generate-ai-notifications',
        body: {
          'userId': Supabase.instance.client.auth.currentUser?.id,
        },
      );

      if (response.status == 200) {
        if (kDebugMode) debugPrint('✅ AI notifications generation requested');
        return true;
      } else {
        if (kDebugMode) {
          debugPrint('❌ Failed to request AI notifications: ${response.status}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error requesting AI notifications: $e');
      return false;
    }
  }
}
