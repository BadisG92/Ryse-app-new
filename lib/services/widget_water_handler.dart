import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'water_service.dart';

/// Service pour gérer les actions d'eau déclenchées depuis le widget iOS (App Intents)
/// Vérifie périodiquement si des actions d'eau en attente doivent être traitées
class WidgetWaterHandler {
  static const MethodChannel _channel = MethodChannel('com.ryze.widget/data');
  static Timer? _checkTimer;

  /// Démarrer la vérification périodique des actions d'eau en attente
  static void startChecking() {
    if (!Platform.isIOS) return;

    // Vérifier immédiatement au démarrage
    _checkPendingWaterActions();

    // Vérifier plus fréquemment pour réduire la latence (toutes les 500ms)
    _checkTimer?.cancel();
    _checkTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkPendingWaterActions();
    });
  }

  /// Arrêter la vérification
  static void stopChecking() {
    _checkTimer?.cancel();
    _checkTimer = null;
  }

  /// Vérifier et traiter les actions d'eau en attente
  static Future<void> _checkPendingWaterActions() async {
    try {
      if (!Platform.isIOS) return;

      // Vérifier si une action d'eau est en attente (bool dans UserDefaults)
      final pendingAdd = await _channel.invokeMethod<bool>('getBool', {
        'key': 'widget_pending_water_add',
      });

      if (pendingAdd == null || pendingAdd == false) {
        return; // Pas d'action en attente
      }

      // Récupérer la quantité (sauvegardée comme Int dans iOS)
      final amount = await _channel.invokeMethod<int>('getInt', {
        'key': 'widget_pending_water_amount',
      });

      // Récupérer le timestamp (sauvegardé comme Double dans iOS)
      final timestamp = await _channel.invokeMethod<double>('getDouble', {
        'key': 'widget_pending_water_timestamp',
      });

      if (amount == null) {
        if (kDebugMode) {
          debugPrint('⚠️ widget_pending_water_add est true mais widget_pending_water_amount est null');
        }
        return;
      }
      if (amount <= 0) {
        if (kDebugMode) {
          debugPrint('⚠️ Quantité d\'eau invalide: $amount');
        }
        // Nettoyer les clés invalides
        await _clearPendingWaterAction();
        return;
      }

      // Vérifier que l'action n'est pas trop ancienne (max 1 heure)
      if (timestamp != null) {
        final actionDate = DateTime.fromMillisecondsSinceEpoch((timestamp * 1000).toInt());
        final now = DateTime.now();
        if (now.difference(actionDate).inHours > 1) {
          if (kDebugMode) {
            debugPrint('⚠️ Action d\'eau trop ancienne, ignorée');
          }
          await _clearPendingWaterAction();
          return;
        }
      }

      // IMPORTANT: Nettoyer les clés IMMÉDIATEMENT pour éviter les doublons
      // On fait ça AVANT d'ajouter l'eau pour empêcher le traitement multiple
      await _clearPendingWaterAction();

      if (kDebugMode) {
        debugPrint('💧 Traitement de l\'action d\'eau depuis le widget: ${amount}ml');
      }

      // Ajouter l'eau via WaterService
      final success = await WaterService.addWaterEntry(
        amount: amount,
        sourceType: _getSourceTypeFromAmount(amount),
      );

      if (success) {
        if (kDebugMode) {
          debugPrint('✅ Eau ajoutée avec succès depuis le widget: ${amount}ml');
        }
      } else {
        if (kDebugMode) {
          debugPrint('❌ Échec de l\'ajout d\'eau depuis le widget');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Erreur lors de la vérification des actions d\'eau: $e');
      }
    }
  }

  /// Nettoyer les clés d'action en attente
  static Future<void> _clearPendingWaterAction() async {
    try {
      await _channel.invokeMethod('remove', {'key': 'widget_pending_water_add'});
      await _channel.invokeMethod('remove', {'key': 'widget_pending_water_amount'});
      await _channel.invokeMethod('remove', {'key': 'widget_pending_water_timestamp'});
    } catch (e) {
      if (kDebugMode) {
        debugPrint('⚠️ Erreur lors du nettoyage des clés: $e');
      }
    }
  }

  /// Déterminer le type de source selon la quantité
  static String _getSourceTypeFromAmount(int milliliters) {
    switch (milliliters) {
      case 250:
        return 'glass';
      case 500:
        return 'bottle';
      case 750:
        return 'sports_bottle';
      case 200:
        return 'cup';
      case 1000:
        return 'bottle';
      default:
        return 'manual';
    }
  }
}
