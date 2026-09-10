import 'package:dio/dio.dart';
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
}
