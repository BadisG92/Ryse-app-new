import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_models.dart';
import '../config/env_config.dart';
import '../config/subscription_config.dart';
import 'revenuecat_service.dart';
import 'subscription_service.dart';

/// Service unifié de gestion des abonnements
///
/// Ce service fait le pont entre:
/// - RevenueCat (achats in-app réels)
/// - SubscriptionService (logique métier et base de données)
///
/// En mode TEST: Utilise le système de test actuel
/// En mode PRODUCTION: Utilise RevenueCat pour les vrais achats
class UnifiedSubscriptionService extends ChangeNotifier {
  static final UnifiedSubscriptionService _instance = UnifiedSubscriptionService._internal();
  factory UnifiedSubscriptionService() => _instance;
  UnifiedSubscriptionService._internal();

  final _revenueCat = RevenueCatService();
  final _subscription = SubscriptionService();
  final _supabase = Supabase.instance.client;

  bool _isInitialized = false;
  bool _isLoading = false;

  /// Mode de test (défini par variable d'environnement)
  bool get testMode => EnvConfig.testMode;

  /// État de chargement
  bool get isLoading => _isLoading;

  /// Service d'abonnement (pour compatibilité avec le code existant)
  SubscriptionService get subscriptionService => _subscription;

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALISATION
  // ═══════════════════════════════════════════════════════════════════════════

  /// Initialise les services d'abonnement
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('UnifiedSubscriptionService déjà initialisé');

      // 🔧 FIX: Vérifier si RevenueCat doit être initialisé maintenant qu'un user est connecté
      final userId = _supabase.auth.currentUser?.id;
      if (!testMode && userId != null && !_revenueCat.isInitialized) {
        debugPrint('🔄 RevenueCat pas encore initialisé mais user connecté, initialisation...');
        try {
          await _revenueCat.initialize(userId: userId);
          debugPrint('✅ RevenueCat initialisé en mode PRODUCTION (delayed)');
          await _syncRevenueCatStatus();
        } catch (e) {
          debugPrint('⚠️ Erreur RevenueCat delayed init: $e');
        }
      }

      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;

      // Initialiser le service de base
      await _subscription.initialize();

      // En production, initialiser RevenueCat
      if (!testMode && userId != null) {
        try {
          await _revenueCat.initialize(userId: userId);
          debugPrint('✅ RevenueCat initialisé en mode PRODUCTION');

          // Synchroniser l'état RevenueCat avec notre DB
          await _syncRevenueCatStatus();
        } catch (e) {
          debugPrint('⚠️ Erreur RevenueCat, fallback sur mode test: $e');
        }
      } else {
        debugPrint('🧪 Mode TEST activé - Pas d\'initialisation RevenueCat');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Erreur initialisation UnifiedSubscriptionService: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchronise le statut RevenueCat avec notre base de données
  Future<void> _syncRevenueCatStatus() async {
    if (testMode || !_revenueCat.isInitialized) return;

    try {
      final isPremium = _revenueCat.isPremium();
      final subscriptionInfo = _revenueCat.getSubscriptionInfo();

      // Si RevenueCat dit premium mais notre DB dit gratuit, mettre à jour
      if (isPremium && !_subscription.isPremium) {
        debugPrint('🔄 Synchronisation: RevenueCat Premium → DB');

        // Déterminer la période depuis le productId
        SubscriptionPeriod period = SubscriptionPeriod.monthly;
        final productId = subscriptionInfo['productId'] as String?;

        if (productId != null) {
          if (productId.contains('weekly')) {
            period = SubscriptionPeriod.weekly;
          } else if (productId.contains('yearly')) {
            period = SubscriptionPeriod.annual;
          }
        }

        // Mettre à jour notre DB
        await _subscription.upgradeToPremium(period: period, testBypass: true);
      }
      // Si RevenueCat dit gratuit mais notre DB dit premium, mettre à jour
      else if (!isPremium && _subscription.isPremium) {
        debugPrint('🔄 Synchronisation: RevenueCat Free → DB');
        await _subscription.downgradeToFree();
      }
    } catch (e) {
      debugPrint('❌ Erreur synchronisation RevenueCat: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // LOGIN / LOGOUT
  // ═══════════════════════════════════════════════════════════════════════════

  /// Se connecter (appelé lors de l'authentification)
  Future<void> login(String userId) async {
    try {
      // Initialiser le service d'abonnement
      await _subscription.initialize();

      // En production, se connecter à RevenueCat
      if (!testMode) {
        await _revenueCat.login(userId);
        await _syncRevenueCatStatus();
      }
    } catch (e) {
      debugPrint('❌ Erreur login UnifiedSubscriptionService: $e');
    }
  }

  /// Se déconnecter (appelé lors de la déconnexion)
  Future<void> logout() async {
    try {
      if (!testMode && _revenueCat.isInitialized) {
        await _revenueCat.logout();
      }
    } catch (e) {
      debugPrint('❌ Erreur logout UnifiedSubscriptionService: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATUT ABONNEMENT (délégué au service approprié)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie si l'utilisateur est Premium
  bool get isPremium {
    // 📸 MODE SCREENSHOT - Bypass pour les screenshots App Store
    if (EnvConfig.screenshotMode) {
      return true;
    }

    if (testMode) {
      return _subscription.isPremium;
    }

    // En production, vérifier RevenueCat en priorité
    if (_revenueCat.isInitialized) {
      return _revenueCat.isPremium();
    }

    // Fallback sur notre DB
    return _subscription.isPremium;
  }

  /// Vérifie si l'utilisateur est en trial
  bool get isInTrial => _subscription.isInTrial;

  /// Jours restants du trial
  int get trialDaysRemaining => _subscription.trialDaysRemaining;

  /// Tier actuel
  SubscriptionTier get currentTier => _subscription.currentTier;

  /// Abonnement actuel
  UserSubscription? get currentSubscription => _subscription.currentSubscription;

  // ═══════════════════════════════════════════════════════════════════════════
  // TRIAL
  // ═══════════════════════════════════════════════════════════════════════════

  /// Démarrer un trial gratuit (3 jours)
  Future<bool> startTrial() async {
    return await _subscription.startTrial();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // UPGRADE / PURCHASE
  // ═══════════════════════════════════════════════════════════════════════════

  /// Upgrade vers Premium
  /// En test: Bypass le paiement
  /// En production: Lance le flux RevenueCat
  Future<bool> upgradeToPremium({
    required SubscriptionPeriod period,
    bool testBypass = false,
  }) async {
    // Mode test ou bypass
    if (testMode || testBypass) {
      return await _subscription.upgradeToPremium(
        period: period,
        testBypass: true,
      );
    }

    // Mode production: Utiliser RevenueCat
    if (!_revenueCat.isInitialized) {
      debugPrint('❌ RevenueCat non initialisé');
      return false;
    }

    try {
      final packages = await _revenueCat.getAvailablePackages();
      if (packages.isEmpty) {
        debugPrint('❌ Aucun package disponible');
        return false;
      }

      // Trouver le bon package selon la période
      String targetIdentifier;
      switch (period) {
        case SubscriptionPeriod.weekly:
          targetIdentifier = SubscriptionConfig.weeklyProductId;
          break;
        case SubscriptionPeriod.monthly:
          targetIdentifier = SubscriptionConfig.monthlyProductId;
          break;
        case SubscriptionPeriod.annual:
          targetIdentifier = SubscriptionConfig.yearlyProductId;
          break;
        case SubscriptionPeriod.lifetime:
          // Pas de lifetime pour Ryse, fallback sur mensuel
          targetIdentifier = SubscriptionConfig.monthlyProductId;
          break;
      }

      // Trouver le package correspondant
      final package = packages.firstWhere(
        (p) => p.storeProduct.identifier == targetIdentifier,
        orElse: () => packages.first,
      );

      // Lancer l'achat
      debugPrint('🛒 Achat RevenueCat: ${package.identifier}');
      final result = await _revenueCat.purchasePackage(package);

      if (result != null && _revenueCat.isPremium()) {
        // Mettre à jour notre DB
        await _subscription.upgradeToPremium(period: period, testBypass: true);
        notifyListeners();
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('❌ Erreur upgrade Premium: $e');
      return false;
    }
  }

  /// Restaurer les achats (iOS uniquement en général)
  Future<bool> restorePurchases() async {
    if (testMode || !_revenueCat.isInitialized) {
      debugPrint('⚠️ Restore non disponible en mode test');
      return false;
    }

    try {
      final customerInfo = await _revenueCat.restorePurchases();
      if (customerInfo != null) {
        await _syncRevenueCatStatus();
        notifyListeners();
        return _revenueCat.isPremium();
      }
      return false;
    } catch (e) {
      debugPrint('❌ Erreur restore: $e');
      return false;
    }
  }

  /// Obtenir les packages disponibles (pour afficher le paywall)
  Future<List<Map<String, dynamic>>> getAvailablePackages() async {
    if (testMode || !_revenueCat.isInitialized) {
      // Retourner les packages fictifs en mode test
      return [
        {
          'identifier': 'weekly',
          'period': SubscriptionPeriod.weekly,
          'price': SubscriptionConfig.weeklyPriceDisplay,
          'description': SubscriptionConfig.getOfferDescription('weekly'),
        },
        {
          'identifier': 'monthly',
          'period': SubscriptionPeriod.monthly,
          'price': SubscriptionConfig.monthlyPriceDisplay,
          'description': SubscriptionConfig.getOfferDescription('monthly'),
        },
        {
          'identifier': 'yearly',
          'period': SubscriptionPeriod.annual,
          'price': SubscriptionConfig.yearlyPriceDisplay,
          'description': SubscriptionConfig.getOfferDescription('yearly'),
        },
      ];
    }

    // En production, récupérer les vrais packages de RevenueCat
    try {
      final packages = await _revenueCat.getAvailablePackages();
      return packages.map((package) {
        SubscriptionPeriod period = SubscriptionPeriod.monthly;
        if (package.storeProduct.identifier.contains('weekly')) {
          period = SubscriptionPeriod.weekly;
        } else if (package.storeProduct.identifier.contains('yearly')) {
          period = SubscriptionPeriod.annual;
        }

        return {
          'identifier': package.identifier,
          'period': period,
          'price': package.storeProduct.priceString,
          'description': package.storeProduct.description,
          'package': package, // Package RevenueCat pour l'achat
        };
      }).toList();
    } catch (e) {
      debugPrint('❌ Erreur récupération packages: $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FEATURES ACCESS (délégué à SubscriptionService)
  // ═══════════════════════════════════════════════════════════════════════════

  /// Vérifie si une feature est accessible
  bool canAccessFeature(String featureName) {
    // 📸 MODE SCREENSHOT - Toutes les features accessibles
    if (EnvConfig.screenshotMode) {
      return true;
    }
    return _subscription.canAccessFeature(featureName);
  }

  /// Vérifie si une feature avec limite quotidienne est accessible
  Future<bool> canUseDailyLimitedFeature(String featureName, int limit) async {
    // 📸 MODE SCREENSHOT - Pas de limite
    if (EnvConfig.screenshotMode) {
      return true;
    }
    return await _subscription.canUseDailyLimitedFeature(featureName, limit);
  }

  /// Incrémente le compteur d'utilisation quotidien
  Future<void> incrementDailyUsage(String featureName) async {
    return await _subscription.incrementDailyUsage(featureName);
  }

  /// Obtient le compteur d'utilisation quotidien
  Future<int> getDailyUsage(String featureName) async {
    return await _subscription.getDailyUsage(featureName);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DOWNGRADE & RESET
  // ═══════════════════════════════════════════════════════════════════════════

  /// Downgrade vers Free
  Future<bool> downgradeToFree() async {
    return await _subscription.downgradeToFree();
  }

  /// Reset (pour testing)
  Future<void> resetSubscription() async {
    await _subscription.resetSubscription();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DEBUG
  // ═══════════════════════════════════════════════════════════════════════════

  /// Afficher les infos de debug
  void debugPrintInfo() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📱 UNIFIED SUBSCRIPTION INFO');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Test Mode: $testMode');
    debugPrint('Is Premium: $isPremium');
    debugPrint('Is Trial: $isInTrial');
    debugPrint('Trial Days: $trialDaysRemaining');
    debugPrint('Tier: ${currentTier.name}');
    debugPrint('RevenueCat Initialized: ${_revenueCat.isInitialized}');

    if (_revenueCat.isInitialized) {
      debugPrint('RevenueCat Premium: ${_revenueCat.isPremium()}');
    }

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
