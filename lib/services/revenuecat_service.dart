import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../config/subscription_config.dart';

/// Service RevenueCat pour la gestion des achats in-app réels
///
/// Ce service gère:
/// - L'initialisation de RevenueCat
/// - La récupération des offres d'abonnement
/// - L'achat et la restauration des abonnements
/// - La vérification du statut d'abonnement
/// - La synchronisation avec l'authentification
///
/// Modèle d'abonnement Ryse:
/// - Weekly: 2,99€/semaine
/// - Monthly: 9,99€/mois
/// - Yearly: 69,99€/an (économie 42%)
/// - Trial: 7 jours gratuits avec toutes les features IA
class RevenueCatService {
  static final RevenueCatService _instance = RevenueCatService._internal();
  factory RevenueCatService() => _instance;
  RevenueCatService._internal();

  // Clés API RevenueCat (à configurer dans vos variables d'environnement)
  static const String _appleApiKey = String.fromEnvironment(
    'REVENUECAT_APPLE_API_KEY',
    defaultValue: '',
  );

  static const String _googleApiKey = String.fromEnvironment(
    'REVENUECAT_GOOGLE_API_KEY',
    defaultValue: '',
  );

  // Identifiants des entitlements et produits (depuis SubscriptionConfig)
  static String get premiumEntitlementId => SubscriptionConfig.premiumEntitlementId;
  static String get weeklyProductId => SubscriptionConfig.weeklyProductId;
  static String get monthlyProductId => SubscriptionConfig.monthlyProductId;
  static String get yearlyProductId => SubscriptionConfig.yearlyProductId;

  bool _isInitialized = false;
  CustomerInfo? _currentCustomerInfo;

  // StreamController pour notifier les changements d'abonnement
  final _subscriptionStatusController = StreamController<bool>.broadcast();
  Stream<bool> get subscriptionStatusStream => _subscriptionStatusController.stream;

  /// Initialise RevenueCat avec la clé API appropriée
  Future<void> initialize({String? userId}) async {
    if (_isInitialized) {
      debugPrint('RevenueCat déjà initialisé');
      return;
    }

    // Vérifier si les clés API sont configurées
    final apiKey = Platform.isIOS ? _appleApiKey : _googleApiKey;
    if (apiKey.isEmpty) {
      debugPrint('⚠️ RevenueCat API key non configurée. Utilisation du mode test.');
      return;
    }

    try {
      // Configuration de RevenueCat
      final configuration = PurchasesConfiguration(apiKey);

      if (userId != null) {
        configuration.appUserID = userId;
      }

      // Configuration sans observerMode (supprimé dans RevenueCat 8.x)
      await Purchases.configure(configuration);

      // Active les logs en développement
      if (kDebugMode) {
        await Purchases.setLogLevel(LogLevel.debug);
      } else {
        await Purchases.setLogLevel(LogLevel.info);
      }

      // Écoute les changements de CustomerInfo
      Purchases.addCustomerInfoUpdateListener(_onCustomerInfoUpdate);

      _isInitialized = true;
      debugPrint('✅ RevenueCat initialisé avec succès');

      // Récupère les infos client initiales
      await refreshCustomerInfo();
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de RevenueCat: $e');
      rethrow;
    }
  }

  /// Callback appelé quand les infos client changent
  void _onCustomerInfoUpdate(CustomerInfo customerInfo) {
    _currentCustomerInfo = customerInfo;
    final isPremium = _isPremiumActive(customerInfo);
    _subscriptionStatusController.add(isPremium);
    debugPrint('📱 Statut abonnement mis à jour: ${isPremium ? "Premium" : "Gratuit"}');
  }

  /// Identifie l'utilisateur dans RevenueCat
  Future<void> login(String userId) async {
    if (!_isInitialized) {
      debugPrint('⚠️ RevenueCat non initialisé, impossible de se connecter');
      return;
    }

    try {
      final logInResult = await Purchases.logIn(userId);
      _currentCustomerInfo = logInResult.customerInfo;
      debugPrint('✅ Utilisateur connecté à RevenueCat: $userId');

      // Notifier du statut
      _subscriptionStatusController.add(_isPremiumActive(logInResult.customerInfo));
    } catch (e) {
      debugPrint('❌ Erreur lors de la connexion RevenueCat: $e');
      rethrow;
    }
  }

  /// Déconnecte l'utilisateur de RevenueCat
  Future<void> logout() async {
    if (!_isInitialized) return;

    try {
      await Purchases.logOut();
      _currentCustomerInfo = null;
      _subscriptionStatusController.add(false);
      debugPrint('✅ Utilisateur déconnecté de RevenueCat');
    } catch (e) {
      debugPrint('❌ Erreur lors de la déconnexion RevenueCat: $e');
      rethrow;
    }
  }

  /// Récupère les informations client actuelles
  Future<CustomerInfo> refreshCustomerInfo() async {
    if (!_isInitialized) {
      throw Exception('RevenueCat non initialisé');
    }

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _currentCustomerInfo = customerInfo;
      return customerInfo;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des infos client: $e');
      rethrow;
    }
  }

  /// Récupère les offres d'abonnement disponibles
  Future<Offerings?> getOfferings() async {
    if (!_isInitialized) {
      debugPrint('⚠️ RevenueCat non initialisé');
      return null;
    }

    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        debugPrint('⚠️ Aucune offre disponible');
        return null;
      }

      debugPrint('📦 Offres disponibles: ${offerings.current!.identifier}');
      return offerings;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des offres: $e');
      rethrow;
    }
  }

  /// Récupère les packages d'abonnement
  Future<List<Package>> getAvailablePackages() async {
    if (!_isInitialized) {
      debugPrint('⚠️ RevenueCat non initialisé');
      return [];
    }

    try {
      final offerings = await Purchases.getOfferings();

      if (offerings.current == null) {
        debugPrint('⚠️ Aucune offre disponible');
        return [];
      }

      final packages = offerings.current!.availablePackages;
      debugPrint('📦 ${packages.length} packages disponibles');

      for (final package in packages) {
        debugPrint('  - ${package.identifier}: ${package.storeProduct.priceString}');
      }

      return packages;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des packages: $e');
      rethrow;
    }
  }

  /// Achète un package d'abonnement
  /// Retourne CustomerInfo directement (RevenueCat 8.x)
  Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_isInitialized) {
      debugPrint('⚠️ RevenueCat non initialisé');
      return null;
    }

    try {
      debugPrint('🛒 Achat de l\'abonnement: ${package.identifier}');
      final customerInfo = await Purchases.purchasePackage(package);
      _currentCustomerInfo = customerInfo;

      if (_isPremiumActive(customerInfo)) {
        debugPrint('✅ Abonnement activé avec succès!');
        _subscriptionStatusController.add(true);
      }

      return customerInfo;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);

      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('ℹ️ Achat annulé par l\'utilisateur');
      } else if (errorCode == PurchasesErrorCode.productAlreadyPurchasedError) {
        debugPrint('ℹ️ Produit déjà acheté');
      } else if (errorCode == PurchasesErrorCode.paymentPendingError) {
        debugPrint('ℹ️ Paiement en attente');
      } else {
        debugPrint('❌ Erreur lors de l\'achat: ${e.message}');
      }
      rethrow;
    }
  }

  /// Restaure les achats précédents
  Future<CustomerInfo?> restorePurchases() async {
    if (!_isInitialized) {
      debugPrint('⚠️ RevenueCat non initialisé');
      return null;
    }

    try {
      debugPrint('🔄 Restauration des achats...');
      final customerInfo = await Purchases.restorePurchases();
      _currentCustomerInfo = customerInfo;

      if (_isPremiumActive(customerInfo)) {
        debugPrint('✅ Abonnements restaurés avec succès!');
        _subscriptionStatusController.add(true);
      } else {
        debugPrint('ℹ️ Aucun abonnement actif trouvé');
        _subscriptionStatusController.add(false);
      }

      return customerInfo;
    } catch (e) {
      debugPrint('❌ Erreur lors de la restauration: $e');
      rethrow;
    }
  }

  /// Vérifie si l'utilisateur a un abonnement premium actif
  bool isPremium() {
    if (!_isInitialized || _currentCustomerInfo == null) {
      return false;
    }
    return _isPremiumActive(_currentCustomerInfo!);
  }

  /// Vérifie si le CustomerInfo contient un entitlement premium actif
  bool _isPremiumActive(CustomerInfo customerInfo) {
    final entitlement = customerInfo.entitlements.all[premiumEntitlementId];
    final isActive = entitlement?.isActive ?? false;

    if (isActive) {
      debugPrint('✅ Entitlement premium actif: ${entitlement?.identifier}');
    }

    return isActive;
  }

  /// Obtient la date d'expiration de l'abonnement
  DateTime? getExpirationDate() {
    if (_currentCustomerInfo == null) return null;

    final entitlement = _currentCustomerInfo!.entitlements.all[premiumEntitlementId];
    if (entitlement == null || !entitlement.isActive) return null;

    return entitlement.expirationDate != null
        ? DateTime.parse(entitlement.expirationDate!)
        : null;
  }

  /// Obtient le type d'abonnement (monthly, yearly, etc.)
  String? getSubscriptionType() {
    if (_currentCustomerInfo == null) return null;

    final entitlement = _currentCustomerInfo!.entitlements.all[premiumEntitlementId];
    if (entitlement == null || !entitlement.isActive) return null;

    return entitlement.productIdentifier;
  }

  /// Vérifie si l'abonnement va se renouveler automatiquement
  bool willRenew() {
    if (_currentCustomerInfo == null) return false;

    final entitlement = _currentCustomerInfo!.entitlements.all[premiumEntitlementId];
    return entitlement?.willRenew ?? false;
  }

  /// Obtient l'URL pour gérer l'abonnement
  Future<String?> getManagementURL() async {
    if (!_isInitialized) return null;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      return customerInfo.managementURL;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de l\'URL de gestion: $e');
      return null;
    }
  }

  /// Obtient les informations détaillées sur l'abonnement
  Map<String, dynamic> getSubscriptionInfo() {
    if (_currentCustomerInfo == null) {
      return {
        'isPremium': false,
        'tier': 'free',
        'expirationDate': null,
        'willRenew': false,
        'productId': null,
      };
    }

    final entitlement = _currentCustomerInfo!.entitlements.all[premiumEntitlementId];
    final isPremium = entitlement?.isActive ?? false;

    return {
      'isPremium': isPremium,
      'tier': isPremium ? 'premium' : 'free',
      'expirationDate': entitlement?.expirationDate,
      'willRenew': entitlement?.willRenew ?? false,
      'productId': entitlement?.productIdentifier,
      'isTrialPeriod': entitlement?.periodType == PeriodType.trial,
      'isIntroductoryPeriod': entitlement?.periodType == PeriodType.intro,
    };
  }

  /// Nettoie les ressources
  void dispose() {
    _subscriptionStatusController.close();
  }

  /// Obtient les informations client actuelles (peut être null)
  CustomerInfo? get currentCustomerInfo => _currentCustomerInfo;

  /// Vérifie si RevenueCat est initialisé
  bool get isInitialized => _isInitialized;

  /// Affiche les informations de debug
  void debugPrintInfo() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📱 REVENUECAT INFO');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Initialized: $_isInitialized');
    debugPrint('Is Premium: ${isPremium()}');
    debugPrint('Will Renew: ${willRenew()}');
    debugPrint('Expiration: ${getExpirationDate()}');
    debugPrint('Product ID: ${getSubscriptionType()}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
