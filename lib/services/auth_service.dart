import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';
import 'global_state_manager.dart';
import 'localization_service.dart';
import 'fast_cache_service.dart';
import 'analytics_service.dart';
import 'offline_workout_service.dart';
import 'meal_widget_data_provider.dart';

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _supabase => SupabaseConfig.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  bool _googleSignInInitialized = false;

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;
  bool _disposed = false;
  bool _isNotifying = false;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _supabase != null;
  
  /// Safe wrapper pour les opérations Supabase
  T? _safeSupabaseCall<T>(T Function(SupabaseClient) operation) {
    try {
      if (_supabase != null) {
        return operation(_supabase!);
      }
      if (kDebugMode) debugPrint('⚠️ Supabase not available (offline mode)');
      return null;
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Supabase operation failed: $e');
      return null;
    }
  }
  bool get isAuthenticated => _currentUser != null;

  /// Initialize the authentication service
  Future<void> initialize() async {
    _setLoading(true);
    try {
      if (kDebugMode) debugPrint('🚀 Initializing AuthService...');

      // CRITICAL: Vérifier si Supabase est disponible avant d'accéder au client
      if (!SupabaseConfig.isAvailable) {
        if (kDebugMode) debugPrint('⚠️ Supabase not available - working in offline mode');
        _setLoading(false);
        return;
      }

      // Check if user is already logged in
      // CRITICAL: Timeout ultra-court pour éviter blocage en mode avion
      final session = await Future.microtask(() => _supabase.auth.currentSession)
          .timeout(const Duration(milliseconds: 500), onTimeout: () => null);

      if (session != null) {
        if (kDebugMode) debugPrint('🔍 Found existing session, loading profile...');
        // Timeout court pour le chargement du profil
        await _loadUserProfile(session.user.id)
            .timeout(const Duration(seconds: 3), onTimeout: () {
          if (kDebugMode) debugPrint('⚠️ Profile loading timeout - continuing with cached data');
        });

        // NOUVEAU: Réinitialiser GlobalStateManager si session existante
        if (kDebugMode) debugPrint('🔄 Réinitialisation GlobalStateManager (session existante)...');
        await GlobalStateManager.instance.initialize()
            .timeout(const Duration(seconds: 2), onTimeout: () {
          if (kDebugMode) debugPrint('⚠️ GlobalStateManager timeout - using defaults');
        });
        // Forcer la mise à jour du widget avec les vraies données utilisateur
        await MealWidgetDataProvider.forceWidgetUpdate();
      } else {
        if (kDebugMode) debugPrint('📱 No existing session found');
      }
      if (kDebugMode) debugPrint('✅ AuthService initialized successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ AuthService initialization failed: $e');
      _setError('Failed to initialize auth service: $e');
      // Ne pas bloquer l'app même si l'auth échoue
    } finally {
      _setLoading(false);
    }
  }

  /// Sign up with email and password
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.user != null) {
        // 📊 Analytics: Sign up success
        await AnalyticsService.logSignUp(method: 'email');
        await AnalyticsService.setUserId(response.user!.id);

        // 🌍 Mettre à jour la langue de l'utilisateur immédiatement après signup
        final userLanguage = LocalizationService.instance.currentLanguageCode;
        if (kDebugMode) debugPrint('🌍 Setting user language after signup: $userLanguage');
        try {
          await _supabase
              .from('users')
              .update({'language': userLanguage})
              .eq('id', response.user!.id);
          if (kDebugMode) debugPrint('✅ Language set to $userLanguage');
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Failed to set language: $e');
        }

        // OFFLINE: Télécharger le cache des exercices pour utilisation offline
        if (kDebugMode) debugPrint('💾 Téléchargement du cache des exercices après inscription...');
        unawaited(OfflineWorkoutService().refreshCache().catchError((e) {
          if (kDebugMode) debugPrint('⚠️ Erreur téléchargement cache exercices: $e');
        }));

        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Sign up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        await _storeTokenSecurely(response.session?.accessToken);

        // 📊 Analytics: Login success
        await AnalyticsService.logLogin(method: 'email');
        await AnalyticsService.setUserId(response.user!.id);

        // NOUVEAU: Réinitialiser GlobalStateManager après connexion réussie
        if (kDebugMode) debugPrint('🔄 Réinitialisation GlobalStateManager après connexion...');
        await GlobalStateManager.instance.initialize();
        // Forcer la mise à jour du widget avec les vraies données utilisateur après connexion
        await MealWidgetDataProvider.forceWidgetUpdate();

        // OFFLINE: Télécharger le cache des exercices pour utilisation offline
        if (kDebugMode) debugPrint('💾 Téléchargement du cache des exercices pour mode offline...');
        unawaited(OfflineWorkoutService().refreshCache().catchError((e) {
          if (kDebugMode) debugPrint('⚠️ Erreur téléchargement cache exercices: $e');
        }));

        return true;
      }
      return false;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Initialize Google Sign-In (V7 API)
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;

    try {
      await GoogleSignIn.instance.initialize(
        // serverClientId is needed to get server auth code for Supabase
        // This should be your web client ID from Google Cloud Console
        // Platform-specific configs are handled in platform files
      );
      _googleSignInInitialized = true;
      if (kDebugMode) debugPrint('✅ GoogleSignIn initialized');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ GoogleSignIn init failed: $e');
      rethrow;
    }
  }

  /// Sign in with Google (V7 API)
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      // Skip Google Sign-In on web if not properly configured
      if (kIsWeb) {
        _setError('Google Sign-In not configured for web');
        return false;
      }

      // Ensure GoogleSignIn is initialized
      await _ensureGoogleSignInInitialized();

      // Check if platform supports authenticate()
      if (!GoogleSignIn.instance.supportsAuthenticate()) {
        _setError('Google Sign-In not supported on this platform');
        return false;
      }

      // V7 API: Use authenticate() to get user account
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: ['email', 'profile'],
      );

      // Get ID token for authentication
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // Verify we have an ID token (required for Supabase)
      if (googleAuth.idToken == null) {
        _setError('Failed to get Google ID token');
        return false;
      }

      // Sign in to Supabase with the ID token only
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
      );

      if (response.user != null) {
        // Extraire le nom depuis Google (si disponible)
        String? firstName;
        String? lastName;

        if (googleUser.displayName != null && googleUser.displayName!.isNotEmpty) {
          final nameParts = googleUser.displayName!.split(' ');
          firstName = nameParts.first;
          if (nameParts.length > 1) {
            lastName = nameParts.sublist(1).join(' ');
          }
          if (kDebugMode) debugPrint('📝 Google name extracted: $firstName $lastName');
        }

        await _loadUserProfile(response.user!.id);

        // 🌍 S'assurer que la langue est définie (pour nouveaux users Google)
        final userLanguage = LocalizationService.instance.currentLanguageCode;
        if (kDebugMode) debugPrint('🌍 Ensuring language is set after Google login: $userLanguage');
        try {
          await _supabase
              .from('users')
              .update({'language': userLanguage})
              .eq('id', response.user!.id);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Failed to update language: $e');
        }

        // Mettre à jour le profil avec le nom si disponible et si pas déjà renseigné
        if (firstName != null && _currentUser != null) {
          final needsUpdate = _currentUser!.firstName.isEmpty ||
                             _currentUser!.firstName == 'User' ||
                             _currentUser!.lastName.isEmpty;

          if (needsUpdate) {
            if (kDebugMode) debugPrint('📝 Updating user profile with Google name...');
            await _updateUserNameFromSocial(
              response.user!.id,
              firstName,
              lastName ?? '',
            );
          }
        }

        await _storeTokenSecurely(response.session?.accessToken);

        // NOUVEAU: Réinitialiser GlobalStateManager après connexion Google
        if (kDebugMode) debugPrint('🔄 Réinitialisation GlobalStateManager après connexion Google...');
        await GlobalStateManager.instance.initialize();
        await MealWidgetDataProvider.updateWidgetData();

        // OFFLINE: Télécharger le cache des exercices pour utilisation offline
        if (kDebugMode) debugPrint('💾 Téléchargement du cache des exercices...');
        unawaited(OfflineWorkoutService().refreshCache().catchError((e) {
          if (kDebugMode) debugPrint('⚠️ Erreur téléchargement cache exercices: $e');
        }));

        return true;
      }
      return false;
    } catch (e) {
      _setError('Google sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _clearError();

    try {
      if (kDebugMode) debugPrint('🍎 Starting Apple Sign In...');

      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();
      if (kDebugMode) debugPrint('🔐 Generated nonce for Apple Sign In');

      if (kDebugMode) debugPrint('🔑 Requesting Apple credentials...');
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      if (kDebugMode) {
        debugPrint('✅ Apple credentials received:');
        debugPrint('   - User ID: ${credential.userIdentifier}');
        debugPrint('   - Email: ${credential.email ?? "not provided"}');
        debugPrint('   - Given Name: ${credential.givenName ?? "not provided"}');
        debugPrint('   - Family Name: ${credential.familyName ?? "not provided"}');
        debugPrint('   - Identity Token: ${credential.identityToken != null ? "✅ present" : "❌ missing"}');
      }

      if (credential.identityToken == null) {
        throw Exception('Apple Sign In failed: No identity token received');
      }

      if (kDebugMode) debugPrint('🔄 Authenticating with Supabase...');
      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );

      if (kDebugMode) {
        debugPrint('📊 Supabase response:');
        debugPrint('   - User ID: ${response.user?.id ?? "null"}');
        debugPrint('   - Session: ${response.session != null ? "✅ created" : "❌ missing"}');
      }

      if (response.user != null) {
        // Extraire le nom depuis Apple (si disponible)
        // IMPORTANT: Apple ne donne le nom QU'À LA PREMIÈRE connexion !
        String? firstName;
        String? lastName;

        if (credential.givenName != null && credential.givenName!.isNotEmpty) {
          firstName = credential.givenName;
          if (kDebugMode) debugPrint('📝 Apple firstName extracted: $firstName');
        }
        if (credential.familyName != null && credential.familyName!.isNotEmpty) {
          lastName = credential.familyName;
          if (kDebugMode) debugPrint('📝 Apple lastName extracted: $lastName');
        }

        if (kDebugMode) debugPrint('👤 Loading user profile...');
        await _loadUserProfileWithSocialData(
          response.user!.id,
          firstName: firstName,
          lastName: lastName,
        );

        // 🌍 S'assurer que la langue est définie (pour nouveaux users Apple)
        final userLanguage = LocalizationService.instance.currentLanguageCode;
        if (kDebugMode) debugPrint('🌍 Ensuring language is set after Apple login: $userLanguage');
        try {
          await _supabase
              .from('users')
              .update({'language': userLanguage})
              .eq('id', response.user!.id);
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Failed to update language: $e');
        }

        if (kDebugMode) debugPrint('🔐 Storing access token securely...');
        await _storeTokenSecurely(response.session?.accessToken);

        // NOUVEAU: Réinitialiser GlobalStateManager après connexion Apple
        if (kDebugMode) debugPrint('🔄 Réinitialisation GlobalStateManager après connexion Apple...');
        await GlobalStateManager.instance.initialize();
        await MealWidgetDataProvider.updateWidgetData();

        // OFFLINE: Télécharger le cache des exercices pour utilisation offline
        if (kDebugMode) debugPrint('💾 Téléchargement du cache des exercices...');
        unawaited(OfflineWorkoutService().refreshCache().catchError((e) {
          if (kDebugMode) debugPrint('⚠️ Erreur téléchargement cache exercices: $e');
        }));

        if (kDebugMode) debugPrint('✅ Apple Sign In completed successfully');
        return true;
      }

      if (kDebugMode) debugPrint('❌ Apple Sign In failed: No user returned from Supabase');
      return false;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('❌ Apple Sign In error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
      _setError('Apple sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _supabase.auth.signOut();
      // V7 API: Sign out from Google if initialized
      if (_googleSignInInitialized) {
        await GoogleSignIn.instance.signOut();
      }
      await _clearAllLocalData();
      _currentUser = null;
      _safeNotifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Clear all local data (cache, tokens, preferences)
  /// Private method used during sign out
  Future<void> _clearAllLocalData() async {
    try {
      if (kDebugMode) debugPrint('🧹 Clearing all local data...');

      // 1. Clear secure storage (tokens)
      await _secureStorage.deleteAll();

      // 2. Clear SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      // 3. Clear fast cache
      FastCacheService.invalidateDashboard();

      // 4. Clear global state manager
      GlobalStateManager.instance.reset();
      await MealWidgetDataProvider.clearWidgetData();

      if (kDebugMode) debugPrint('✅ All local data cleared');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Error clearing local data: $e');
    }
  }

  /// Force clear all local data and sign out
  /// Useful when user deleted their account from database directly
  /// or when app is in inconsistent state
  Future<void> forceResetApp() async {
    _setLoading(true);
    try {
      if (kDebugMode) debugPrint('🚨 Force reset app...');

      // Sign out from Supabase if possible
      try {
        await _supabase.auth.signOut();
      } catch (e) {
        if (kDebugMode) debugPrint('⚠️ Could not sign out from Supabase: $e');
      }

      // Sign out from Google if initialized
      if (_googleSignInInitialized) {
        try {
          await GoogleSignIn.instance.signOut();
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Could not sign out from Google: $e');
        }
      }

      // Clear all local data
      await _clearAllLocalData();

      // Reset current user
      _currentUser = null;
      _safeNotifyListeners();

      if (kDebugMode) debugPrint('✅ App reset complete - please restart');
    } catch (e) {
      _setError('Force reset failed: $e');
      if (kDebugMode) debugPrint('❌ Force reset error: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return true;
    } on AuthException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('Password reset failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? phoneNumber,
    DateTime? dateOfBirth,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    String? fitnessGoal,
    int? dailyCalories,
  }) async {
    if (_currentUser == null) return false;

    _setLoading(true);
    _clearError();

    try {
      final updates = <String, dynamic>{};
      if (firstName != null) updates['first_name'] = firstName;
      if (lastName != null) updates['last_name'] = lastName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (dateOfBirth != null) updates['date_of_birth'] = dateOfBirth.toIso8601String();
      if (gender != null) updates['gender'] = gender;
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (activityLevel != null) updates['activity_level'] = activityLevel;
      if (fitnessGoal != null) updates['fitness_goal'] = fitnessGoal;
      if (dailyCalories != null) updates['daily_calories'] = dailyCalories;

      await _supabase
          .from('users')
          .update(updates)
          .eq('id', _currentUser!.id);

      // Update local user model
      _currentUser = _currentUser!.copyWith(
        firstName: firstName ?? _currentUser!.firstName,
        lastName: lastName ?? _currentUser!.lastName,
        phoneNumber: phoneNumber ?? _currentUser!.phoneNumber,
        dateOfBirth: dateOfBirth ?? _currentUser!.dateOfBirth,
        gender: gender ?? _currentUser!.gender,
        height: height ?? _currentUser!.height,
        weight: weight ?? _currentUser!.weight,
        activityLevel: activityLevel ?? _currentUser!.activityLevel,
        fitnessGoal: fitnessGoal ?? _currentUser!.fitnessGoal,
        dailyCalories: dailyCalories ?? _currentUser!.dailyCalories,
      );

      _safeNotifyListeners();
      return true;
    } catch (e) {
      _setError('Profile update failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update daily calories goal
  Future<bool> updateDailyCalories(int calories) async {
    return await updateProfile(dailyCalories: calories);
  }

  /// Get stored access token
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: 'access_token');
  }

  /// Private methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    _safeNotifyListeners();
  }

  void _setError(String error) {
    _errorMessage = _getFriendlyErrorMessage(error);
    _safeNotifyListeners();
  }

  /// Convertit les erreurs techniques en messages conviviaux et ludiques
  String _getFriendlyErrorMessage(String technicalError) {
    final errorLower = technicalError.toLowerCase();

    // Erreurs d'identifiants invalides
    if (errorLower.contains('invalid login') ||
        errorLower.contains('invalid credentials') ||
        errorLower.contains('email not confirmed') ||
        errorLower.contains('invalid grant')) {
      return 'auth_error_invalid_credentials';
    }

    // Utilisateur non trouvé
    if (errorLower.contains('user not found') ||
        errorLower.contains('no user found')) {
      return 'auth_error_user_not_found';
    }

    // Email invalide
    if (errorLower.contains('invalid email') ||
        errorLower.contains('malformed email')) {
      return 'auth_error_invalid_email';
    }

    // Mot de passe trop faible
    if (errorLower.contains('password') &&
        (errorLower.contains('weak') ||
         errorLower.contains('short') ||
         errorLower.contains('must be at least'))) {
      return 'auth_error_weak_password';
    }

    // Email déjà utilisé
    if (errorLower.contains('already registered') ||
        errorLower.contains('already exists') ||
        errorLower.contains('email already in use') ||
        errorLower.contains('user already registered')) {
      return 'auth_error_email_already_exists';
    }

    // Trop de tentatives
    if (errorLower.contains('too many requests') ||
        errorLower.contains('rate limit') ||
        errorLower.contains('too many attempts')) {
      return 'auth_error_too_many_requests';
    }

    // Problèmes réseau
    if (errorLower.contains('network') ||
        errorLower.contains('connection') ||
        errorLower.contains('timeout') ||
        errorLower.contains('failed host lookup')) {
      return 'auth_error_network';
    }

    // Google Sign-In annulé
    if (errorLower.contains('sign_in_canceled') ||
        errorLower.contains('sign_in_cancelled') ||
        (errorLower.contains('google') && errorLower.contains('cancel'))) {
      return 'auth_error_google_cancelled';
    }

    // Apple Sign-In annulé
    if (errorLower.contains('authorization_error_canceled') ||
        errorLower.contains('the operation couldn\'t be completed') ||
        (errorLower.contains('apple') && errorLower.contains('cancel'))) {
      return 'auth_error_apple_cancelled';
    }

    // Session expirée
    if (errorLower.contains('session expired') ||
        errorLower.contains('token expired') ||
        errorLower.contains('jwt expired')) {
      return 'auth_error_session_expired';
    }

    // Inscription désactivée
    if (errorLower.contains('signup') && errorLower.contains('disabled')) {
      return 'auth_error_signup_disabled';
    }

    // Compte désactivé
    if (errorLower.contains('account') && errorLower.contains('disabled')) {
      return 'auth_error_account_disabled';
    }

    // Google Sign-In échoué
    if (errorLower.contains('google sign in failed') ||
        errorLower.contains('google authentication failed')) {
      return 'auth_error_google_failed';
    }

    // Apple Sign-In échoué
    if (errorLower.contains('apple sign in failed') ||
        errorLower.contains('apple authentication failed')) {
      return 'auth_error_apple_failed';
    }

    // Réinitialisation mot de passe échouée
    if (errorLower.contains('password reset failed')) {
      return 'auth_error_password_reset_failed';
    }

    // Erreur inconnue
    return 'auth_error_unknown';
  }

  void _clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void _safeNotifyListeners() {
    // Prevent recursive notifications and build-time notifications
    if (_disposed || _isNotifying) return;
    
    _isNotifying = true;
    
    // Always schedule for later to avoid "setState during build" errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) {
        try {
          notifyListeners();
        } catch (e) {
          if (kDebugMode) debugPrint('⚠️ Failed to notify listeners: $e');
        }
        _isNotifying = false;
      }
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<void> _loadUserProfile(String userId) async {
    try {
      if (kDebugMode) debugPrint('🔄 Loading user profile for: $userId');

      // Essayer de charger le profil existant
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response != null) {
        // L'utilisateur existe déjà dans la table
        _currentUser = UserModel.fromJson(response);
        _safeNotifyListeners();
        if (kDebugMode) debugPrint('✅ User profile loaded successfully');

        // Si la langue n'est pas définie, la mettre à jour avec la langue système
        final existingLanguage = response['language'] as String?;
        if (existingLanguage == null || existingLanguage.isEmpty) {
          final userLanguage = LocalizationService.instance.currentLanguageCode;
          if (kDebugMode) debugPrint('🌍 User has no language set, updating to: $userLanguage');
          await _supabase
              .from('users')
              .update({'language': userLanguage})
              .eq('id', userId);
        }
      } else {
        // L'utilisateur n'existe pas encore → le créer
        if (kDebugMode) debugPrint('👤 User not found in database, creating...');
        await _createUserProfile(userId);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to load user profile: $e');
      // En cas d'erreur, essayer de créer l'utilisateur
      try {
        await _createUserProfile(userId);
      } catch (createError) {
        if (kDebugMode) debugPrint('❌ Failed to create user profile: $createError');
        // Fallback: profil minimal en mémoire seulement
        _currentUser = UserModel(
          id: userId,
          email: _supabase.auth.currentUser?.email ?? 'unknown',
          firstName: 'User',
          lastName: '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _safeNotifyListeners();
      }
    }
  }

  /// Load user profile with social login data (Apple, Google)
  /// If user doesn't exist, create with provided names
  Future<void> _loadUserProfileWithSocialData(
    String userId, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      if (kDebugMode) debugPrint('🔄 Loading user profile for: $userId');

      // Essayer de charger le profil existant
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle()
          .timeout(const Duration(seconds: 5));

      if (response != null) {
        // L'utilisateur existe déjà dans la table
        _currentUser = UserModel.fromJson(response);
        _safeNotifyListeners();
        if (kDebugMode) debugPrint('✅ User profile loaded successfully');

        // Si la langue n'est pas définie, la mettre à jour avec la langue système
        final existingLanguage = response['language'] as String?;
        if (existingLanguage == null || existingLanguage.isEmpty) {
          final userLanguage = LocalizationService.instance.currentLanguageCode;
          if (kDebugMode) debugPrint('🌍 User has no language set, updating to: $userLanguage');
          await _supabase
              .from('users')
              .update({'language': userLanguage})
              .eq('id', userId);
        }

        // Mettre à jour le nom si fourni et si le profil a 'User' comme nom
        if (firstName != null && _currentUser != null) {
          final needsUpdate = _currentUser!.firstName == 'User' ||
                             _currentUser!.firstName.isEmpty;

          if (needsUpdate) {
            if (kDebugMode) debugPrint('📝 Updating user profile with social name...');
            await _updateUserNameFromSocial(userId, firstName, lastName ?? '');
          }
        }
      } else {
        // L'utilisateur n'existe pas encore → le créer avec le nom fourni
        if (kDebugMode) debugPrint('👤 User not found in database, creating with social data...');
        await _createUserProfile(userId, firstName: firstName, lastName: lastName);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Failed to load user profile: $e');
      // En cas d'erreur, essayer de créer l'utilisateur
      try {
        await _createUserProfile(userId, firstName: firstName, lastName: lastName);
      } catch (createError) {
        if (kDebugMode) debugPrint('❌ Failed to create user profile: $createError');
        // Fallback: profil minimal en mémoire seulement
        _currentUser = UserModel(
          id: userId,
          email: _supabase.auth.currentUser?.email ?? 'unknown',
          firstName: firstName ?? 'User',
          lastName: lastName ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        _safeNotifyListeners();
      }
    }
  }

  /// Crée un nouveau profil utilisateur dans la table users
  Future<void> _createUserProfile(
    String userId, {
    String? firstName,
    String? lastName,
  }) async {
    try {
      final authUser = _supabase.auth.currentUser;
      if (authUser == null) {
        throw Exception('No authenticated user found');
      }

      if (kDebugMode) debugPrint('📝 Creating user profile in database...');

      // Créer l'utilisateur avec les données minimales
      // Inclure la langue détectée par LocalizationService (basée sur la langue système)
      final userLanguage = LocalizationService.instance.currentLanguageCode;
      if (kDebugMode) debugPrint('🌍 Creating user with language: $userLanguage');

      final newUser = {
        'id': userId,
        'email': authUser.email ?? 'unknown',
        'first_name': firstName ?? 'User',
        'last_name': lastName ?? '',
        'language': userLanguage,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_onboarded': false,
      };

      await _supabase.from('users').insert(newUser);

      // Charger le profil créé
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      _currentUser = UserModel.fromJson(response);
      _safeNotifyListeners();

      if (kDebugMode) debugPrint('✅ User profile created successfully');
    } catch (e) {
      if (kDebugMode) debugPrint('❌ Error creating user profile: $e');
      rethrow;
    }
  }

  Future<void> _storeTokenSecurely(String? token) async {
    if (token != null) {
      await _secureStorage.write(key: 'access_token', value: token);
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = List.generate(length, (_) => charset[(DateTime.now().millisecondsSinceEpoch * 1000) % charset.length]);
    return random.join();
  }

  /// Met à jour le nom de l'utilisateur depuis les données du social login
  Future<void> _updateUserNameFromSocial(
    String userId,
    String firstName,
    String lastName,
  ) async {
    try {
      await _supabase.from('users').update({
        'first_name': firstName,
        'last_name': lastName,
      }).eq('id', userId);

      // Mettre à jour le modèle local
      if (_currentUser != null) {
        _currentUser = _currentUser!.copyWith(
          firstName: firstName,
          lastName: lastName,
        );
        _safeNotifyListeners();
      }

      if (kDebugMode) debugPrint('✅ User name updated from social login: $firstName $lastName');
    } catch (e) {
      if (kDebugMode) debugPrint('⚠️ Failed to update user name from social login: $e');
      // Ne pas bloquer le flow si ça échoue
    }
  }

  /// Vérifie si l'utilisateur a un nom complet
  bool get hasCompleteName {
    if (_currentUser == null) return false;
    return _currentUser!.firstName.isNotEmpty &&
           _currentUser!.firstName != 'User' &&
           _currentUser!.lastName.isNotEmpty;
  }
} 
