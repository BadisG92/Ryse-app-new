import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/subscription_models.dart';
import '../config/env_config.dart';

/// Service de gestion des abonnements
class SubscriptionService extends ChangeNotifier {
  static final SubscriptionService _instance = SubscriptionService._internal();
  factory SubscriptionService() => _instance;
  SubscriptionService._internal();

  static SubscriptionService get instance => _instance;

  final _supabase = Supabase.instance.client;
  UserSubscription? _currentSubscription;
  bool _isLoading = false;

  /// ✅ MODE TEST CONTRÔLÉ PAR VARIABLE D'ENVIRONNEMENT
  /// En développement: TEST_MODE=true (.env.local)
  /// En production: TEST_MODE=false (.env.production)
  static bool get TEST_MODE => EnvConfig.testMode;

  UserSubscription? get currentSubscription => _currentSubscription;
  bool get isLoading => _isLoading;

  /// Vérifie si l'utilisateur est Premium
  /// Renvoie true si l'utilisateur a un abonnement actif ou est en période d'essai
  /// En screenshotMode, renvoie toujours true
  bool get isPremium => EnvConfig.screenshotMode || (_currentSubscription?.isPremium ?? false);

  /// Vérifie si l'utilisateur est en trial
  bool get isInTrial => _currentSubscription?.isInTrial ?? false;

  /// Jours restants du trial
  int get trialDaysRemaining => _currentSubscription?.trialDaysRemaining ?? 0;

  /// Tier actuel
  SubscriptionTier get currentTier =>
      _currentSubscription?.tier ?? SubscriptionTier.free;

  /// Initialiser le service (charger l'abonnement)
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        _currentSubscription = UserSubscription.free();
        return;
      }

      // Charger depuis la base de données
      await _loadSubscriptionFromDatabase(userId);

      // Si pas d'abonnement en DB et TEST_MODE, donner trial gratuit
      if (_currentSubscription == null && TEST_MODE) {
        debugPrint('🧪 TEST MODE: Démarrage trial gratuit');
        await startTrial();
      }
    } catch (e) {
      debugPrint('❌ Error initializing subscription: $e');
      _currentSubscription = UserSubscription.free();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger l'abonnement depuis la base de données
  Future<void> _loadSubscriptionFromDatabase(String userId) async {
    try {
      final response = await _supabase
          .from('user_subscriptions')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        _currentSubscription = UserSubscription.fromJson(response);
        debugPrint('✅ Subscription loaded: ${_currentSubscription?.tier.name}');
      } else {
        _currentSubscription = UserSubscription.free();
        debugPrint('ℹ️ No subscription found, defaulting to FREE');
      }
    } catch (e) {
      debugPrint('❌ Error loading subscription: $e');
      _currentSubscription = UserSubscription.free();
    }
  }

  /// Sauvegarder l'abonnement en base de données
  Future<void> _saveSubscriptionToDatabase() async {
    if (_currentSubscription == null) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = {
        'user_id': userId,
        ..._currentSubscription!.toJson(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('user_subscriptions').upsert(data);
      debugPrint('✅ Subscription saved to database');
    } catch (e) {
      debugPrint('❌ Error saving subscription: $e');
    }
  }

  /// Démarrer un trial gratuit (7 jours)
  Future<bool> startTrial() async {
    try {
      // Vérifier si l'utilisateur a déjà eu un trial
      if (await _hasHadTrial()) {
        debugPrint('⚠️ User already had a trial');
        return false;
      }

      _currentSubscription = UserSubscription.trial(isTestMode: TEST_MODE);
      await _saveSubscriptionToDatabase();
      await _markTrialUsed();

      debugPrint('✅ Trial started (7 days)');
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('❌ Error starting trial: $e');
      return false;
    }
  }

  /// Vérifier si l'utilisateur a déjà eu un trial
  Future<bool> _hasHadTrial() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return false;

    return prefs.getBool('trial_used_$userId') ?? false;
  }

  /// Marquer le trial comme utilisé
  Future<void> _markTrialUsed() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    await prefs.setBool('trial_used_$userId', true);
  }

  /// Upgrade vers Premium (MODE TEST ou vrai paiement)
  Future<bool> upgradeToPremium({
    required SubscriptionPeriod period,
    bool testBypass = false, // Bypass pour tester
  }) async {
    try {
      if (TEST_MODE || testBypass) {
        // MODE TEST: Bypass le paiement
        debugPrint('🧪 TEST MODE: Upgrade to Premium (${period.name})');
        _currentSubscription = UserSubscription.premium(
          period: period,
          isTestMode: true,
        );
        await _saveSubscriptionToDatabase();
        notifyListeners();
        return true;
      } else {
        // MODE PRODUCTION: Intégrer RevenueCat ici
        debugPrint('💳 PRODUCTION MODE: Launch payment flow for ${period.name}');
        // TODO: Intégrer RevenueCat/Stripe
        // final purchaseResult = await RevenueCat.purchasePlan(period);
        // if (purchaseResult.success) {
        //   _currentSubscription = UserSubscription.premium(period: period);
        //   await _saveSubscriptionToDatabase();
        //   notifyListeners();
        //   return true;
        // }
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error upgrading to Premium: $e');
      return false;
    }
  }

  /// Downgrade vers Free
  Future<bool> downgradeToFree() async {
    try {
      _currentSubscription = UserSubscription.free();
      await _saveSubscriptionToDatabase();
      notifyListeners();
      debugPrint('✅ Downgraded to FREE');
      return true;
    } catch (e) {
      debugPrint('❌ Error downgrading: $e');
      return false;
    }
  }

  /// Vérifier si une feature est accessible
  bool canAccessFeature(String featureName) {
    // Features toujours accessibles en Free
    const freeFeatures = [
      'manual_food_entry',
      'basic_tracking',
      'basic_workouts',
    ];

    if (freeFeatures.contains(featureName)) return true;

    // Features Premium
    const premiumFeatures = [
      'unlimited_ai_scans',
      'daily_nutrition_analysis',
      'ai_workout_generator',
      'ai_chat_nutrition',
      'unlimited_history',
      'all_workouts',
      'unlimited_recipes',
      'data_export',
      'advanced_charts',
      'offline_mode',
      'no_ads',
    ];

    if (premiumFeatures.contains(featureName)) {
      return isPremium;
    }

    return false;
  }

  /// Vérifier les limites quotidiennes (ex: scans IA)
  Future<bool> canUseDailyLimitedFeature(String featureName, int limit) async {
    if (isPremium) return true; // Premium = illimité

    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'daily_limit_${featureName}_${userId}_$today';

    final currentCount = prefs.getInt(key) ?? 0;

    if (currentCount >= limit) {
      debugPrint('⚠️ Daily limit reached for $featureName ($currentCount/$limit)');
      return false;
    }

    return true;
  }

  /// Incrémenter le compteur d'utilisation quotidien
  Future<void> incrementDailyUsage(String featureName) async {
    if (isPremium) return; // Premium = pas de comptage

    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'daily_limit_${featureName}_${userId}_$today';

    final currentCount = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, currentCount + 1);

    debugPrint('📊 Daily usage for $featureName: ${currentCount + 1}');
  }

  /// Obtenir le compteur d'utilisation quotidien
  Future<int> getDailyUsage(String featureName) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = _supabase.auth.currentUser?.id ?? 'anonymous';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'daily_limit_${featureName}_${userId}_$today';

    return prefs.getInt(key) ?? 0;
  }

  /// Reset manuel (pour testing)
  Future<void> resetSubscription() async {
    _currentSubscription = UserSubscription.free();
    await _saveSubscriptionToDatabase();
    notifyListeners();
    debugPrint('🔄 Subscription reset to FREE');
  }

  /// Afficher les infos de debug
  void debugPrintSubscriptionInfo() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📱 SUBSCRIPTION INFO');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Tier: ${currentTier.name}');
    debugPrint('Is Premium: $isPremium');
    debugPrint('Is Trial: $isInTrial');
    debugPrint('Trial Days Remaining: $trialDaysRemaining');
    debugPrint('Period: ${_currentSubscription?.period?.name ?? 'N/A'}');
    debugPrint('Test Mode: ${_currentSubscription?.isTestMode ?? false}');
    debugPrint('Start Date: ${_currentSubscription?.startDate}');
    debugPrint('Expiry Date: ${_currentSubscription?.expiryDate}');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }
}
