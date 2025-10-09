import 'package:flutter/foundation.dart';
import '../components/ui/dashboard_models.dart';
import '../services/dashboard_service.dart';

/// Notifier pour gérer le profil utilisateur de façon centralisée
/// Évite le rechargement du streak à chaque changement de page
class UserProfileNotifier extends ChangeNotifier {
  UserProfile? _userProfile;
  bool _isLoading = false;
  bool _hasBeenInitialized = false;
  DateTime? _lastRefresh;

  // Cache de 5 minutes pour éviter les rechargements excessifs
  static const Duration _cacheExpiration = Duration(minutes: 5);

  // Getters publics
  UserProfile? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get hasBeenInitialized => _hasBeenInitialized;

  // Vérifier si le cache est encore valide
  bool get _isCacheValid => _lastRefresh != null &&
      DateTime.now().difference(_lastRefresh!) < _cacheExpiration;

  /// Initialisation du profil (appelée une seule fois au démarrage de l'app)
  Future<void> initializeProfile() async {
    if (_hasBeenInitialized || _isLoading) {
      // Déjà initialisé ou en cours d'initialisation
      return;
    }

    // Si le cache est valide, pas besoin de recharger
    if (_isCacheValid && _userProfile != null) {
      debugPrint('⚡ UserProfile: cache valide, pas de rechargement');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await DashboardService.getUserProfile();
      _hasBeenInitialized = true;
      _lastRefresh = DateTime.now();
      debugPrint('✅ UserProfile initialisé: streak=${_userProfile?.streak}, name=${_userProfile?.name}');
    } catch (e) {
      debugPrint('❌ Erreur initialisation UserProfile: $e');
      _userProfile = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour le score du jour (pour animations)
  void updateTodayScore(int score) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(todayScore: score);
      notifyListeners();
    }
  }

  /// Mettre à jour le statut premium
  void updatePremiumStatus(bool isPremium) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(isPremium: isPremium);
      notifyListeners();
    }
  }

  /// Mettre à jour les calories actuelles
  void updateCurrentCalories(int currentCalories) {
    if (_userProfile != null) {
      _userProfile = _userProfile!.copyWith(currentCalories: currentCalories);
      notifyListeners();
    }
  }

  /// Recharger le profil (pour pull-to-refresh par exemple)
  Future<void> refreshProfile() async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await DashboardService.getUserProfile();
      _lastRefresh = DateTime.now();
      debugPrint('🔄 UserProfile rechargé: streak=${_userProfile?.streak}');
    } catch (e) {
      debugPrint('❌ Erreur rechargement UserProfile: $e');
      // Garder l'ancien profil en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset complet (pour déconnexion par exemple)
  void reset() {
    _userProfile = null;
    _isLoading = false;
    _hasBeenInitialized = false;
    _lastRefresh = null;
    notifyListeners();
    debugPrint('🔄 UserProfile reset');
  }
}