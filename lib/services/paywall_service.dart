import 'package:flutter/material.dart';
import '../models/subscription_models.dart';
import '../screens/paywall_screen.dart';
import 'subscription_service.dart';

/// Contextes de paywall (pour analytics et personnalisation)
enum PaywallContext {
  aiScanLimit,          // Limite de scans IA atteinte
  historyLimit,         // Limite d'historique atteinte
  workoutGenerator,     // Générateur de workouts
  nutritionAnalysis,    // Bilan nutritionnel
  trialEnded,          // Fin du trial
  recipeLimit,         // Limite recettes
  exportData,          // Export de données
  advancedCharts,      // Graphiques avancés
  offlineMode,         // Mode offline
  genericUpgrade,      // Upgrade générique
}

/// Service pour gérer l'affichage des paywalls
class PaywallService {
  static final PaywallService _instance = PaywallService._internal();
  factory PaywallService() => _instance;
  PaywallService._internal();

  static PaywallService get instance => _instance;

  final _subscriptionService = SubscriptionService.instance;

  /// Afficher un paywall modal
  Future<bool> showPaywall({
    required BuildContext context,
    required PaywallContext paywallContext,
    String? customTitle,
    String? customMessage,
  }) async {
    // Si déjà Premium, ne pas afficher le paywall
    if (_subscriptionService.isPremium) {
      return true;
    }

    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (context) => PaywallScreen(
        context: paywallContext,
        customTitle: customTitle,
        customMessage: customMessage,
      ),
    );

    return result ?? false;
  }

  /// Vérifier si l'utilisateur peut accéder à une feature
  /// Affiche un paywall si nécessaire
  Future<bool> canAccessFeature({
    required BuildContext context,
    required String featureName,
    required PaywallContext paywallContext,
  }) async {
    if (_subscriptionService.canAccessFeature(featureName)) {
      return true;
    }

    // Afficher le paywall
    return await showPaywall(
      context: context,
      paywallContext: paywallContext,
    );
  }

  /// Vérifier limite quotidienne et afficher paywall si dépassée
  Future<bool> checkDailyLimit({
    required BuildContext context,
    required String featureName,
    required int limit,
    required PaywallContext paywallContext,
  }) async {
    if (await _subscriptionService.canUseDailyLimitedFeature(featureName, limit)) {
      // Incrémenter le compteur
      await _subscriptionService.incrementDailyUsage(featureName);
      return true;
    }

    // Limite atteinte, afficher paywall
    return await showPaywall(
      context: context,
      paywallContext: paywallContext,
    );
  }

  /// Obtenir le message personnalisé selon le contexte
  static Map<String, String> getPaywallContent(
    PaywallContext context,
    String languageCode,
  ) {
    final isFrench = languageCode == 'fr';

    switch (context) {
      case PaywallContext.aiScanLimit:
        return {
          'title': isFrench ? '🔥 Limite atteinte' : '🔥 Limit reached',
          'message': isFrench
              ? 'Tu as utilisé tes 3 scans gratuits aujourd\'hui!\n\nTu es motivé, c\'est génial! 🎯\n\nLes utilisateurs Premium scannent en moyenne 8 repas/jour.'
              : 'You\'ve used your 3 free scans today!\n\nYou\'re motivated, that\'s great! 🎯\n\nPremium users scan an average of 8 meals/day.',
        };

      case PaywallContext.workoutGenerator:
        return {
          'title': isFrench
              ? '🤖 Générateur IA - Premium'
              : '🤖 AI Generator - Premium',
          'message': isFrench
              ? 'Le générateur de séances IA est réservé aux membres Premium.\n\nIl analyse ton historique pour créer des workouts personnalisés avec les bons poids.'
              : 'The AI workout generator is reserved for Premium members.\n\nIt analyzes your history to create personalized workouts with the right weights.',
        };

      case PaywallContext.nutritionAnalysis:
        return {
          'title': isFrench ? '📊 Bilan IA - Premium' : '📊 AI Analysis - Premium',
          'message': isFrench
              ? 'Les bilans nutritionnels quotidiens sont réservés aux membres Premium.\n\nCoach Ryze analyse ta journée et te donne des conseils personnalisés.'
              : 'Daily nutrition reports are reserved for Premium members.\n\nCoach Ryze analyzes your day and gives you personalized advice.',
        };

      case PaywallContext.historyLimit:
        return {
          'title': isFrench
              ? '⚠️ Historique limité'
              : '⚠️ Limited history',
          'message': isFrench
              ? 'Version gratuite: 3 jours d\'historique\n\nPasse Premium pour garder TOUTES tes données à vie et suivre ta progression sur le long terme.'
              : 'Free version: 3 days of history\n\nUpgrade to Premium to keep ALL your data forever and track your long-term progress.',
        };

      case PaywallContext.trialEnded:
        return {
          'title': isFrench ? '🎉 Tu as adoré ton essai Premium!' : '🎉 You loved your Premium trial!',
          'message': isFrench
              ? 'Ton essai gratuit de 7 jours est terminé.\n\nContinue à profiter de toutes les fonctionnalités Premium pour seulement 9,99€/mois.'
              : 'Your 7-day free trial has ended.\n\nContinue enjoying all Premium features for only €9.99/month.',
        };

      case PaywallContext.recipeLimit:
        return {
          'title': isFrench
              ? '🍳 Limite recettes'
              : '🍳 Recipe limit',
          'message': isFrench
              ? 'Version gratuite: 3 recettes maximum\n\nPasse Premium pour créer et sauvegarder autant de recettes que tu veux.'
              : 'Free version: 3 recipes maximum\n\nUpgrade to Premium to create and save unlimited recipes.',
        };

      case PaywallContext.exportData:
        return {
          'title': isFrench ? '📄 Export - Premium' : '📄 Export - Premium',
          'message': isFrench
              ? 'L\'export de données est réservé aux membres Premium.\n\nTélécharge tes données en PDF ou Excel.'
              : 'Data export is reserved for Premium members.\n\nDownload your data in PDF or Excel format.',
        };

      case PaywallContext.advancedCharts:
        return {
          'title': isFrench
              ? '📈 Graphiques - Premium'
              : '📈 Charts - Premium',
          'message': isFrench
              ? 'Les graphiques avancés sont réservés aux membres Premium.\n\nVisualise ta progression sur le long terme avec des graphiques détaillés.'
              : 'Advanced charts are reserved for Premium members.\n\nVisualize your long-term progress with detailed charts.',
        };

      case PaywallContext.offlineMode:
        return {
          'title': isFrench
              ? '✈️ Mode offline - Premium'
              : '✈️ Offline mode - Premium',
          'message': isFrench
              ? 'Le mode offline complet est réservé aux membres Premium.\n\nContinue à tracker même sans connexion internet.'
              : 'Full offline mode is reserved for Premium members.\n\nKeep tracking even without internet connection.',
        };

      case PaywallContext.genericUpgrade:
      default:
        return {
          'title': isFrench
              ? '💎 Passe Premium'
              : '💎 Upgrade to Premium',
          'message': isFrench
              ? 'Débloque toutes les fonctionnalités Premium et atteins tes objectifs plus rapidement.'
              : 'Unlock all Premium features and reach your goals faster.',
        };
    }
  }
}
