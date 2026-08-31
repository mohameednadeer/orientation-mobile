import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../core/api_client.dart';

class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _isGoogleSignInInitialized = false;

  static Future<void> _initGoogleSignIn() async {
    if (_isGoogleSignInInitialized) return;
    await _googleSignIn.initialize(
      serverClientId: '745396676629-2nkvgpsu6df4pp4b9tldnkq9r9sh0hec.apps.googleusercontent.com', // Web Client ID from Google Console
    );
    _isGoogleSignInInitialized = true;
  }

  static Future<bool> signInWithGoogle() async {
    try {
      await _initGoogleSignIn();
      final GoogleSignInAccount? googleUser = await _googleSignIn.authenticate();
      if (googleUser == null) return false; // User cancelled

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) throw Exception('Failed to retrieve Google ID Token');

      // Send to NestJS backend
      final response = await ApiClient.dio.post(
        '/auth/google/mobile',
        data: {'idToken': idToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await ApiClient.saveTokens(
          accessToken: response.data['accessToken'],
          refreshToken: response.data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return false;
    }
  }

  static Future<bool> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('No Identity Token returned from Apple');

      Map<String, dynamic>? nameMap;
      if (credential.givenName != null || credential.familyName != null) {
        nameMap = {
          'firstName': credential.givenName,
          'lastName': credential.familyName,
        };
      }

      // Send to NestJS backend
      final response = await ApiClient.dio.post(
        '/auth/apple/mobile',
        data: {
          'identityToken': identityToken,
          'email': credential.email,
          if (nameMap != null) 'name': nameMap,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        await ApiClient.saveTokens(
          accessToken: response.data['accessToken'],
          refreshToken: response.data['refreshToken'],
        );
        return true;
      }
      return false;
    } catch (e) {
      print('Apple Sign-In Error: $e');
      return false;
    }
  }
}
