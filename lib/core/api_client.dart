import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiClient {
  static const String baseUrl = ApiConfig.baseUrl;
  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: ApiConfig.connectTimeout,
      receiveTimeout: ApiConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static const _storage = FlutterSecureStorage();

  static void init() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          var token = await _storage.read(key: 'accessToken');
          if (token == null || token.isEmpty) {
            final prefs = await SharedPreferences.getInstance();
            token = prefs.getString('auth_token');
          }
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
      ),
    );
  }

  static Future<bool> isLoggedIn() async {
    final secureToken = await _storage.read(key: 'accessToken');
    if (secureToken != null && secureToken.isNotEmpty) {
      return true;
    }
    final prefs = await SharedPreferences.getInstance();
    final prefsToken = prefs.getString('auth_token');
    return prefsToken != null && prefsToken.isNotEmpty;
  }

  static Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
  }

  static Future<void> clearTokens() async {
    await _storage.deleteAll();
  }
}
