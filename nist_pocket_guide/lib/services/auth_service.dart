import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _isGuestKey = 'is_guest';

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  // Current user state
  User? get currentUser => Supabase.instance.client.auth.currentUser;
  bool get isAuthenticated => currentUser != null;

  // Check if user is in guest mode
  Future<bool> isGuestMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isGuestKey) ?? true; // Default to guest mode
  }

  // Set guest mode
  Future<void> setGuestMode(bool isGuest) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isGuestKey, isGuest);
  }

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: 'https://your-project.supabase.co', // Replace with your Supabase URL
      anonKey: 'your-anon-key', // Replace with your Supabase anon key
    );
  }

  // Sign up with email and password
  Future<AuthResult> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: fullName != null ? {'full_name': fullName} : null,
      );

      if (response.user != null) {
        await setGuestMode(false);
        await _saveUserId(response.user!.id);
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.error('Failed to create account');
      }
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Sign in with email and password
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        await setGuestMode(false);
        await _saveUserId(response.user!.id);
        return AuthResult.success(response.user!);
      } else {
        return AuthResult.error('Failed to sign in');
      }
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('An unexpected error occurred');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      await setGuestMode(true);
      await _clearUserId();
    } catch (e) {
      // Silent fail for sign out
    }
  }

  // Reset password
  Future<AuthResult> resetPassword(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      return AuthResult.success(null, 'Password reset email sent');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Failed to send reset email');
    }
  }

  // Sign in with Google
  Future<AuthResult> signInWithGoogle() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );

      if (response) {
        await setGuestMode(false);
        final user = currentUser;
        if (user != null) {
          await _saveUserId(user.id);
          return AuthResult.success(user);
        }
      }
      return AuthResult.error('Google sign-in was cancelled');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Google sign-in failed: $e');
    }
  }

  // Sign in with Apple
  Future<AuthResult> signInWithApple() async {
    try {
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.flutter://reset-callback/',
      );

      if (response) {
        await setGuestMode(false);
        final user = currentUser;
        if (user != null) {
          await _saveUserId(user.id);
          return AuthResult.success(user);
        }
      }
      return AuthResult.error('Apple sign-in was cancelled');
    } on AuthException catch (e) {
      return AuthResult.error(e.message);
    } catch (e) {
      return AuthResult.error('Apple sign-in failed: $e');
    }
  }

  // Continue as guest
  Future<void> continueAsGuest() async {
    await setGuestMode(true);
  }

  // Convert guest to account
  Future<AuthResult> convertGuestToAccount({
    required String email,
    required String password,
    String? fullName,
  }) async {
    // First create the account
    final result = await signUp(
      email: email,
      password: password,
      fullName: fullName,
    );

    if (result.isSuccess) {
      // Here you would typically migrate guest data to the new account
      // This will be handled by the sync service
      await setGuestMode(false);
    }

    return result;
  }

  // Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) return false;

      // Check if token is expired
      final now = DateTime.now().millisecondsSinceEpoch / 1000;
      return session.expiresAt! > now;
    } catch (e) {
      return false;
    }
  }

  // Refresh session if needed
  Future<void> refreshSessionIfNeeded() async {
    try {
      if (!await isSessionValid()) {
        await Supabase.instance.client.auth.refreshSession();
      }
    } catch (e) {
      // If refresh fails, sign out
      await signOut();
    }
  }

  // Save user ID to local storage
  Future<void> _saveUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
  }

  // Clear user ID from local storage
  Future<void> _clearUserId() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
  }

  // Get saved user ID
  Future<String?> getSavedUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  // Listen to auth state changes
  void listenToAuthChanges(Function(AuthState) callback) {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      callback(data);
    });
  }
}

// Result class for authentication operations
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? error;
  final String? message;

  AuthResult.success(this.user, [this.message])
    : isSuccess = true,
      error = null;

  AuthResult.error(this.error) : isSuccess = false, user = null, message = null;
}
