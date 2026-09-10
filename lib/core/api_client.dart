import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'auth_interceptor.dart';

/// Result of checking authentication status on app startup.
enum AuthStatus {
  /// User has a valid session (tokens refreshed or cached locally).
  authenticated,

  /// No stored tokens or refresh token was rejected by server (401/403).
  unauthenticated,
}

/// Central API Client configuring Dio with timeouts, headers, and authentication interceptors.
class ApiClient {
  static const String baseUrl = ApiConfig.baseUrl;
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      sendTimeout: ApiConfig.sendTimeout,
      headers: ApiConfig.defaultHeaders,
    ),
  );

  static bool _initialized = false;

  /// Initializes the Dio instance with the AuthInterceptor.
  static void init() {
    if (_initialized) return;
    _initialized = true;

    dio.interceptors.add(
      AuthInterceptor(
        dio: dio,
        storage: _storage,
      ),
    );
  }

  /// Checks if the user is authenticated.
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsToken = prefs.getString('auth_token');
    if (prefsToken != null && prefsToken.isNotEmpty) {
      return true;
    }

    try {
      final secureToken = await _storage.read(key: 'accessToken');
      if (secureToken != null && secureToken.isNotEmpty) {
        await prefs.setString('auth_token', secureToken);
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Retrieves the current access token.
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsToken = prefs.getString('auth_token');
    if (prefsToken != null && prefsToken.isNotEmpty) return prefsToken;

    try {
      final token = await _storage.read(key: 'accessToken');
      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        return token;
      }
    } catch (_) {}

    return null;
  }

  /// Retrieves the current refresh token.
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final prefsToken = prefs.getString('refresh_token');
    if (prefsToken != null && prefsToken.isNotEmpty) return prefsToken;

    try {
      final token = await _storage.read(key: 'refreshToken');
      if (token != null && token.isNotEmpty) {
        await prefs.setString('refresh_token', token);
        return token;
      }
    } catch (_) {}

    return null;
  }

  /// Saves the authenticated session tokens securely.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);

    try {
      await _storage.write(key: 'accessToken', value: accessToken);
      await _storage.write(key: 'refreshToken', value: refreshToken);
    } catch (_) {}
  }

  /// Clears all stored authentication tokens.
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_name');
    await prefs.remove('user_role');
    await prefs.remove('user_phone');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_profile_picture');

    try {
      await _storage.deleteAll();
    } catch (_) {}
  }

  /// ─── Session Restoration (Splash Screen) ───────────────────────────────
  ///
  /// Called on cold app start to determine whether the user should be sent
  /// to MainScreen (still logged in) or LoginScreen (session expired).
  ///
  /// Flow:
  /// 1. Read refreshToken from secure storage.
  /// 2. If absent → [AuthStatus.unauthenticated].
  /// 3. If present → POST /auth/refresh with a CLEAN Dio (no interceptor loop).
  /// 4. If 200 → save rotated tokens → [AuthStatus.authenticated].
  /// 5. If 401/403 → clear tokens → [AuthStatus.unauthenticated].
  /// 6. If network error → trust cached token → [AuthStatus.authenticated].
  static Future<AuthStatus> checkAuthStatus() async {
    try {
      // 1. Read stored refresh token
      final refreshToken = await getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('🔑 [checkAuthStatus] No refresh token found → unauthenticated');
        return AuthStatus.unauthenticated;
      }

      // 2. Attempt token refresh with a CLEAN Dio instance (avoids interceptor recursion)
      final cleanDio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      debugPrint('🔄 [checkAuthStatus] Attempting POST /auth/refresh...');
      final response = await cleanDio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map) {
          final newAccessToken =
              data['accessToken']?.toString() ?? data['token']?.toString();
          final newRefreshToken =
              data['refreshToken']?.toString() ?? refreshToken;

          if (newAccessToken != null && newAccessToken.isNotEmpty) {
            await saveTokens(
              accessToken: newAccessToken,
              refreshToken:
                  (newRefreshToken.isNotEmpty) ? newRefreshToken : refreshToken,
            );
            debugPrint('✅ [checkAuthStatus] Tokens refreshed → authenticated');
            return AuthStatus.authenticated;
          }
        }
      }

      // Unexpected response shape
      debugPrint('⚠️ [checkAuthStatus] Unexpected refresh response → unauthenticated');
      return AuthStatus.unauthenticated;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        // Server explicitly rejected the refresh token → session is dead
        debugPrint('🚫 [checkAuthStatus] Refresh rejected ($statusCode) → clearing tokens');
        await clearTokens();
        return AuthStatus.unauthenticated;
      }

      // Network error / timeout → trust the cached session (offline-friendly)
      debugPrint('📡 [checkAuthStatus] Network error during refresh → trusting cached session');
      return AuthStatus.authenticated;
    } catch (e) {
      // Unknown error → trust cached session
      debugPrint('❌ [checkAuthStatus] Unexpected error: $e → trusting cached session');
      return AuthStatus.authenticated;
    }
  }
}
