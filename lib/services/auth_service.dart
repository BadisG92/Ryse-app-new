import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import '../models/user_model.dart';
import '../config/supabase_config.dart';
import 'global_state_manager.dart'; // NOUVEAU: Pour réinitialiser après connexion

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  SupabaseClient get _supabase => SupabaseConfig.client;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  GoogleSignIn? _googleSignIn;

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
      debugPrint('⚠️ Supabase not available (offline mode)');
      return null;
    } catch (e) {
      debugPrint('⚠️ Supabase operation failed: $e');
      return null;
    }
  }
  bool get isAuthenticated => _currentUser != null;

  /// Initialize the authentication service
  Future<void> initialize() async {
    _setLoading(true);
    try {
      debugPrint('🚀 Initializing AuthService...');

      // Check if user is already logged in
      final session = _supabase.auth.currentSession;
      if (session != null) {
        debugPrint('🔍 Found existing session, loading profile...');
        // CORRECTION: Timeout global pour toute l'initialisation
        await _loadUserProfile(session.user.id).timeout(const Duration(seconds: 10));

        // NOUVEAU: Réinitialiser GlobalStateManager si session existante
        debugPrint('🔄 Réinitialisation GlobalStateManager (session existante)...');
        await GlobalStateManager.instance.initialize();
      } else {
        debugPrint('📱 No existing session found');
      }
      debugPrint('✅ AuthService initialized successfully');
    } catch (e) {
      debugPrint('❌ AuthService initialization failed: $e');
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

        // NOUVEAU: Réinitialiser GlobalStateManager après connexion réussie
        debugPrint('🔄 Réinitialisation GlobalStateManager après connexion...');
        await GlobalStateManager.instance.initialize();

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

  /// Initialize Google Sign-In safely (lazy loading)
  GoogleSignIn _getGoogleSignIn() {
    if (_googleSignIn == null) {
      try {
        // Only initialize if not on web or if properly configured
        if (kIsWeb) {
          // Check if Google Client ID is configured for web
          _googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
            // Web will use meta tag configuration
          );
        } else {
          _googleSignIn = GoogleSignIn(
            scopes: ['email', 'profile'],
          );
        }
      } catch (e) {
        debugPrint('⚠️ GoogleSignIn init failed: $e');
        rethrow;
      }
    }
    return _googleSignIn!;
  }

  /// Sign in with Google (with web protection)
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      // Skip Google Sign-In on web if not properly configured
      if (kIsWeb) {
        _setError('Google Sign-In not configured for web');
        return false;
      }

      final GoogleSignInAccount? googleUser = await _getGoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: googleAuth.idToken!,
        accessToken: googleAuth.accessToken,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        await _storeTokenSecurely(response.session?.accessToken);

        // NOUVEAU: Réinitialiser GlobalStateManager après connexion Google
        debugPrint('🔄 Réinitialisation GlobalStateManager après connexion Google...');
        await GlobalStateManager.instance.initialize();

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
      final rawNonce = _generateNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final response = await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: credential.identityToken!,
        nonce: rawNonce,
      );

      if (response.user != null) {
        await _loadUserProfile(response.user!.id);
        await _storeTokenSecurely(response.session?.accessToken);

        // NOUVEAU: Réinitialiser GlobalStateManager après connexion Apple
        debugPrint('🔄 Réinitialisation GlobalStateManager après connexion Apple...');
        await GlobalStateManager.instance.initialize();

        return true;
      }
      return false;
    } catch (e) {
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
      // Only sign out from Google if initialized
      if (_googleSignIn != null) {
        await _googleSignIn!.signOut();
      }
      await _secureStorage.delete(key: 'access_token');
      _currentUser = null;
      _safeNotifyListeners();
    } catch (e) {
      _setError('Sign out failed: $e');
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
    _errorMessage = error;
    _safeNotifyListeners();
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
          debugPrint('⚠️ Failed to notify listeners: $e');
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
      debugPrint('🔄 Loading user profile for: $userId');
      
      // CORRECTION: Ajouter timeout de 5 secondes
      final response = await _supabase
          .from('users')
          .select()
          .eq('id', userId)
          .single()
          .timeout(const Duration(seconds: 5));

      _currentUser = UserModel.fromJson(response);
      _safeNotifyListeners();
      debugPrint('✅ User profile loaded successfully');
    } catch (e) {
      debugPrint('❌ Failed to load user profile: $e');
      // Ne pas bloquer l'app, continuer avec un profil minimal
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
} 