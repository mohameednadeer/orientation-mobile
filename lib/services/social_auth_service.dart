import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class SocialAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _isGoogleSignInInitialized = false;

  Future<void> _initGoogleSignIn() async {
    if (_isGoogleSignInInitialized) return;
    await _googleSignIn.initialize(
      serverClientId: '745396676629-2nkvgpsu6df4pp4b9tldnkq9r9sh0hec.apps.googleusercontent.com',
      clientId: Platform.isIOS ? '745396676629-5ltfp049tk8sp6nbbt1vfd0u4r12ala8.apps.googleusercontent.com' : null,
    );
    _isGoogleSignInInitialized = true;
  }

  /// Returns Google ID Token if successful, null if canceled
  Future<String?> signInWithGoogle() async {
    try {
      await _initGoogleSignIn();
      final GoogleSignInAccount? account = await _googleSignIn.authenticate();
      if (account == null) {
        return null; // User canceled
      }
      final GoogleSignInAuthentication auth = account.authentication;
      return auth.idToken; 
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel')) {
        return null; // User canceled, return null gracefully
      }
      throw Exception('Google sign-in failed: $e');
    }
  }

  /// Returns Facebook Access Token if successful, null if canceled
  Future<String?> signInWithFacebook() async {
    try {
      // Temporarily disabled. Fails gracefully to allow Google testing.
      throw Exception('Facebook login is currently disabled.');
      /*
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        return result.accessToken?.token;
      } else if (result.status == LoginStatus.cancelled) {
        return null;
      } else {
        throw Exception(result.message ?? 'Facebook sign-in failed');
      }
      */
    } catch (e) {
      throw Exception('Facebook sign-in failed: $e');
    }
  }

  /// Optional: Sign out from both
  Future<void> signOut() async {
    try {
      await _initGoogleSignIn();
      await _googleSignIn.signOut();
      await FacebookAuth.instance.logOut();
    } catch (e) {
      print('Social SignOut Error: $e');
    }
  }
}
