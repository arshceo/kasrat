import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth service — handles Google Sign-In via Supabase.
class AuthService {
  static final _supabase = Supabase.instance.client;

  /// Sign in with Google using Supabase native Google auth.
  static Future<AuthResponse> signInWithGoogle() async {
    // 🚨 STOP! EXTREMELY IMPORTANT:
    // This MUST be the "Web application" Client ID from Google Cloud Console.
    // Do NOT put the "Android" Client ID here.
    // Both the Web Client and Android Client must exist in the EXACT SAME Google Cloud Project.
    const String webClientId = '378148668409-38lfvcjb4b350lm01c4p2v9s5acfqsvp.apps.googleusercontent.com';

    /// For Android: Uses native Google Sign-In
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
    );

    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google Sign-In was cancelled');
    }

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('No ID Token found');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    return response;
  }

  /// Sign out
  static Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabase.auth.signOut();
  }

  /// Get current user
  static User? getCurrentUser() {
    return _supabase.auth.currentUser;
  }

  /// Get current session
  static Session? getCurrentSession() {
    return _supabase.auth.currentSession;
  }

  /// Check if logged in
  static bool get isLoggedIn => _supabase.auth.currentUser != null;

  /// Listen to auth state changes
  static Stream<AuthState> get onAuthStateChange =>
      _supabase.auth.onAuthStateChange;

  /// Update user profile in Supabase
  static Future<void> updateProfile({
    String? language,
    String? commanderPersona,
    String? tier,
    int? collateralAmount,
  }) async {
    final user = getCurrentUser();
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (language != null) updates['language'] = language;
    if (commanderPersona != null) updates['commander_persona'] = commanderPersona;
    if (tier != null) updates['tier'] = tier;
    if (collateralAmount != null) updates['collateral_amount'] = collateralAmount;

    if (updates.isNotEmpty) {
      await _supabase
          .from('profiles')
          .update(updates)
          .eq('id', user.id);
    }
  }

  /// Get user profile
  static Future<Map<String, dynamic>?> getProfile() async {
    final user = getCurrentUser();
    if (user == null) return null;

    final response = await _supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return response;
  }
}
