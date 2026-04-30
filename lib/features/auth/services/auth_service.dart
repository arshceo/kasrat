import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Auth service — handles Google Sign-In via Supabase.
class AuthService {
  static final _supabase = Supabase.instance.client;

  static const String _webClientId =
      '378148668409-38lfvcjb4b350lm01c4p2v9s5acfqsvp.apps.googleusercontent.com';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile', 'openid'],
    serverClientId: _webClientId,
  );

  /// Sign in with Google using Supabase native Google auth.
  static Future<AuthResponse> signInWithGoogle() async {
    try {
      // Clear any existing Google sign-in local state to force selection
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }

      final googleUser = await _googleSignIn.signIn();
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
    } on PlatformException catch (error) {
      if (error.code == 'sign_in_failed' &&
          error.message?.contains('ApiException: 10') == true) {
        throw Exception(
          'Google Sign-In is not configured for this Android build. Register package com.ustadai.kasrat_ai with SHA-1 F8:08:A2:7A:96:81:16:38:3E:20:7E:49:98:53:00:77:A0:6C:03:0D in Google Cloud OAuth and Supabase, then rebuild the app.',
        );
      }

      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    try {
      // Disconnect clears the current account selection entirely
      await _googleSignIn.signOut();
      await _googleSignIn.disconnect();
    } catch (e) {
      // Ignore if already disconnected
    }
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
    if (commanderPersona != null) {
      updates['commander_persona'] = commanderPersona;
    }
    if (tier != null) updates['tier'] = tier;
    if (collateralAmount != null) {
      updates['collateral_amount'] = collateralAmount;
    }

    if (updates.isNotEmpty) {
      await _supabase.from('profiles').update(updates).eq('id', user.id);
    }
  }

  /// Check if the user has completed onboarding
  static Future<bool> isOnboardingComplete() async {
    final user = getCurrentUser();
    if (user == null) return false;

    try {
      final res = await _supabase
          .from('profiles')
          .select('onboarding_complete')
          .eq('id', user.id)
          .maybeSingle();

      return res != null && res['onboarding_complete'] == true;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
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
