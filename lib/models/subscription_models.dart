import 'package:flutter/foundation.dart';

/// Énumération des tiers d'abonnement
enum SubscriptionTier {
  free,
  premium,
}

/// Énumération des périodes d'abonnement
enum SubscriptionPeriod {
  weekly,
  monthly,
  annual,
  lifetime,
}

/// Modèle d'abonnement utilisateur
class UserSubscription {
  final SubscriptionTier tier;
  final SubscriptionPeriod? period; // null si free
  final DateTime? startDate;
  final DateTime? expiryDate; // null si lifetime
  final bool isTestMode; // Mode TEST pour bypass paiement
  final bool isTrial; // En période d'essai
  final DateTime? trialEndDate;

  UserSubscription({
    required this.tier,
    this.period,
    this.startDate,
    this.expiryDate,
    this.isTestMode = false,
    this.isTrial = false,
    this.trialEndDate,
  });

  /// Vérifie si l'utilisateur est Premium (actif)
  bool get isPremium {
    if (tier == SubscriptionTier.free) return false;

    // Mode TEST: toujours premium
    if (isTestMode) return true;

    // Lifetime: toujours premium
    if (period == SubscriptionPeriod.lifetime) return true;

    // Vérifier expiration
    if (expiryDate != null && DateTime.now().isAfter(expiryDate!)) {
      return false;
    }

    return true;
  }

  /// Vérifie si l'utilisateur est en trial
  bool get isInTrial {
    if (!isTrial) return false;
    if (trialEndDate == null) return false;
    return DateTime.now().isBefore(trialEndDate!);
  }

  /// Jours restants du trial
  int get trialDaysRemaining {
    if (!isInTrial || trialEndDate == null) return 0;
    return trialEndDate!.difference(DateTime.now()).inDays;
  }

  /// Factory: Utilisateur Free
  factory UserSubscription.free() {
    return UserSubscription(
      tier: SubscriptionTier.free,
      period: null,
      startDate: null,
      expiryDate: null,
    );
  }

  /// Factory: Trial Premium (3 jours)
  factory UserSubscription.trial({bool isTestMode = false}) {
    final now = DateTime.now();
    return UserSubscription(
      tier: SubscriptionTier.premium,
      period: null,
      startDate: now,
      expiryDate: now.add(const Duration(days: 3)),
      isTestMode: isTestMode,
      isTrial: true,
      trialEndDate: now.add(const Duration(days: 3)),
    );
  }

  /// Factory: Premium payant
  factory UserSubscription.premium({
    required SubscriptionPeriod period,
    bool isTestMode = false,
  }) {
    final now = DateTime.now();
    DateTime? expiry;

    switch (period) {
      case SubscriptionPeriod.weekly:
        expiry = now.add(const Duration(days: 7));
        break;
      case SubscriptionPeriod.monthly:
        expiry = DateTime(now.year, now.month + 1, now.day);
        break;
      case SubscriptionPeriod.annual:
        expiry = DateTime(now.year + 1, now.month, now.day);
        break;
      case SubscriptionPeriod.lifetime:
        expiry = null; // Jamais d'expiration
        break;
    }

    return UserSubscription(
      tier: SubscriptionTier.premium,
      period: period,
      startDate: now,
      expiryDate: expiry,
      isTestMode: isTestMode,
      isTrial: false,
      trialEndDate: null,
    );
  }

  /// Conversion vers JSON
  Map<String, dynamic> toJson() {
    return {
      'tier': tier.name,
      'period': period?.name,
      'start_date': startDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'is_test_mode': isTestMode,
      'is_trial': isTrial,
      'trial_end_date': trialEndDate?.toIso8601String(),
    };
  }

  /// Création depuis JSON
  factory UserSubscription.fromJson(Map<String, dynamic> json) {
    return UserSubscription(
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == json['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      period: json['period'] != null
          ? SubscriptionPeriod.values.firstWhere(
              (e) => e.name == json['period'],
              orElse: () => SubscriptionPeriod.monthly,
            )
          : null,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'])
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'])
          : null,
      isTestMode: json['is_test_mode'] ?? false,
      isTrial: json['is_trial'] ?? false,
      trialEndDate: json['trial_end_date'] != null
          ? DateTime.parse(json['trial_end_date'])
          : null,
    );
  }

  /// Copie avec modifications
  UserSubscription copyWith({
    SubscriptionTier? tier,
    SubscriptionPeriod? period,
    DateTime? startDate,
    DateTime? expiryDate,
    bool? isTestMode,
    bool? isTrial,
    DateTime? trialEndDate,
  }) {
    return UserSubscription(
      tier: tier ?? this.tier,
      period: period ?? this.period,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      isTestMode: isTestMode ?? this.isTestMode,
      isTrial: isTrial ?? this.isTrial,
      trialEndDate: trialEndDate ?? this.trialEndDate,
    );
  }
}

/// Pricing d'un plan d'abonnement
class SubscriptionPlan {
  final SubscriptionPeriod period;
  final double priceEur;
  final String displayName;
  final String description;
  final int? discountPercent; // null si pas de discount

  SubscriptionPlan({
    required this.period,
    required this.priceEur,
    required this.displayName,
    required this.description,
    this.discountPercent,
  });

  /// Prix par mois équivalent
  double get pricePerMonth {
    switch (period) {
      case SubscriptionPeriod.weekly:
        return priceEur * 4.33; // Moyenne semaines/mois
      case SubscriptionPeriod.monthly:
        return priceEur;
      case SubscriptionPeriod.annual:
        return priceEur / 12;
      case SubscriptionPeriod.lifetime:
        return 0; // N/A
    }
  }

  /// Plans disponibles
  static List<SubscriptionPlan> get availablePlans => [
    SubscriptionPlan(
      period: SubscriptionPeriod.weekly,
      priceEur: 2.99,
      displayName: 'Hebdomadaire',
      description: 'Parfait pour tester',
      discountPercent: null,
    ),
    SubscriptionPlan(
      period: SubscriptionPeriod.monthly,
      priceEur: 9.99,
      displayName: 'Mensuel',
      description: 'Le plus populaire',
      discountPercent: null,
    ),
    SubscriptionPlan(
      period: SubscriptionPeriod.annual,
      priceEur: 69.99,
      displayName: 'Annuel',
      description: 'Meilleure valeur',
      discountPercent: 42, // (9.99*12 - 69.99) / (9.99*12) * 100
    ),
    SubscriptionPlan(
      period: SubscriptionPeriod.lifetime,
      priceEur: 299.0,
      displayName: 'À vie',
      description: 'Accès permanent',
      discountPercent: null,
    ),
  ];

  /// Plan recommandé par défaut
  static SubscriptionPlan get recommended => availablePlans[1]; // Monthly
}

/// Features Premium (pour affichage)
class PremiumFeature {
  final String title;
  final String description;
  final String icon; // Emoji ou icon name
  final bool isFreeFeature;

  PremiumFeature({
    required this.title,
    required this.description,
    required this.icon,
    this.isFreeFeature = false,
  });

  /// Liste des features Premium
  static List<PremiumFeature> get premiumFeatures => [
    PremiumFeature(
      title: 'Scans IA illimités',
      description: 'Scanne autant de repas que tu veux avec Gemini 2.0',
      icon: '📸',
    ),
    PremiumFeature(
      title: 'Bilan nutritionnel quotidien',
      description: 'Analyse IA personnalisée de ta journée avec Coach Ryze',
      icon: '🎯',
    ),
    PremiumFeature(
      title: 'Générateur de séances IA',
      description: 'Workouts personnalisés basés sur ton historique',
      icon: '🤖',
    ),
    PremiumFeature(
      title: 'Chat nutrition IA',
      description: 'Ajoute des aliments par texte ou voix',
      icon: '💬',
    ),
    PremiumFeature(
      title: 'Historique illimité',
      description: 'Garde toutes tes données à vie',
      icon: '📊',
    ),
    PremiumFeature(
      title: 'Tous les workouts',
      description: 'HIIT, Cardio, Musculation, programmes complets',
      icon: '🏋️',
    ),
    PremiumFeature(
      title: 'Recettes illimitées',
      description: 'Crée et sauvegarde autant de recettes que tu veux',
      icon: '🍳',
    ),
    PremiumFeature(
      title: 'Export de données',
      description: 'PDF, Excel de ton historique nutrition/sport',
      icon: '📄',
    ),
    PremiumFeature(
      title: 'Graphiques avancés',
      description: 'Visualise ta progression sur le long terme',
      icon: '📈',
    ),
    PremiumFeature(
      title: 'Mode offline complet',
      description: 'Continue à tracker même sans connexion',
      icon: '✈️',
    ),
    PremiumFeature(
      title: 'Pas de publicité',
      description: 'Expérience 100% sans distractions',
      icon: '🚫',
    ),
  ];

  /// Features gratuites (pour comparaison)
  static List<PremiumFeature> get freeFeatures => [
    PremiumFeature(
      title: '3 scans IA/jour',
      description: 'Scanner alimentaire avec Gemini 2.0',
      icon: '📸',
      isFreeFeature: true,
    ),
    PremiumFeature(
      title: 'Tracking manuel illimité',
      description: 'Ajoute autant d\'aliments que tu veux manuellement',
      icon: '✍️',
      isFreeFeature: true,
    ),
    PremiumFeature(
      title: '3 jours d\'historique',
      description: 'Consulte tes 3 derniers jours',
      icon: '📅',
      isFreeFeature: true,
    ),
    PremiumFeature(
      title: '3 workouts pré-définis',
      description: 'Accès à des séances basiques',
      icon: '💪',
      isFreeFeature: true,
    ),
  ];
}
