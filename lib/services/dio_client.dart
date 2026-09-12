import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

/// Legacy DioClient wrapper that delegates to [ApiClient.dio].
///
/// Consolidates all network traffic to use a single [Dio] instance configured
/// with [AuthInterceptor] (QueuedInterceptor, token refresh mutex, secure storage,
/// and automatic 401 handling), eliminating race conditions from competing interceptors.
class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  DioClient._internal() {
    init();
  }

  bool _isRefreshing = false;
  static SharedPreferences? _cachedPrefs;

  String get _baseUrl => ApiClient.dio.options.baseUrl;

  static Future<SharedPreferences> _getPrefs() async {
    _cachedPrefs ??= await SharedPreferences.getInstance();
    return _cachedPrefs!;
  }

  /// Returns the shared Dio instance from [ApiClient].
  Dio get dio {
    ApiClient.init();
    return ApiClient.dio;
  }

  /// Ensures [ApiClient] is initialized.
  void init() {
    ApiClient.init();
  }

  /// Set the base URL dynamically
  void setBaseUrl(String url) {
    final sanitized = _sanitizeUrl(url);
    ApiClient.dio.options.baseUrl = sanitized;
  }

  static String _sanitizeUrl(String url) {
    var sanitized = url.trim();
    if (sanitized.isEmpty) return sanitized;
    if (sanitized.endsWith('/')) {
      sanitized = sanitized.substring(0, sanitized.length - 1);
    }
    if (!sanitized.endsWith('/api/v1')) {
      sanitized = '$sanitized/api/v1';
    }
    return sanitized;
  }

  /// Refreshes the auth tokens using a clean Dio instance to avoid interceptor recursion.
  Future<bool> refreshToken() => _refreshToken();

  Future<bool> _refreshToken() async {
    if (_isRefreshing) return false;

    try {
      _isRefreshing = true;
      final prefs = await _getPrefs();
      final refreshToken = prefs.getString('refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        print('⚠️ No refresh token available');
        return false;
      }

      print('🔄 Attempting to refresh access token...');
      final refreshDio = Dio(BaseOptions(baseUrl: _baseUrl));
      final response = await refreshDio.post(
        '/auth/refresh',
        options: Options(headers: {'Authorization': 'Bearer $refreshToken'}),
      );
      final data = response.data as Map<String, dynamic>;

      final newAccessToken = data['accessToken']?.toString() ?? '';
      final newRefreshToken = data['refreshToken']?.toString() ?? '';

      if (newAccessToken.isNotEmpty) {
        await prefs.setString('auth_token', newAccessToken);
        print('✅ Token refreshed successfully');
        if (newRefreshToken.isNotEmpty) {
          await prefs.setString('refresh_token', newRefreshToken);
        }
        try {
          await ApiClient.saveTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken.isNotEmpty ? newRefreshToken : refreshToken,
          );
        } catch (_) {}
        return true;
      }

      return false;
    } on DioException catch (e) {
      print('❌ Failed to refresh token: $e');
      final statusCode = e.response?.statusCode;
      if (statusCode == 401 || statusCode == 403) {
        final prefs = await _getPrefs();
        await prefs.remove('auth_token');
        await prefs.remove('refresh_token');
      }
      return false;
    } catch (e) {
      print('❌ Unexpected error refreshing token: $e');
      return false;
    } finally {
      _isRefreshing = false;
    }
  }
}

