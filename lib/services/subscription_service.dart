import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class UserSubscriptionStatus {
  final bool hasAccess;
  final String? status;
  final String? planName;
  final DateTime? periodEnd;
  final dynamic rawData;

  UserSubscriptionStatus({
    required this.hasAccess,
    this.status,
    this.planName,
    this.periodEnd,
    this.rawData,
  });

  factory UserSubscriptionStatus.fromJson(dynamic raw) {
    if (raw == null) {
      return UserSubscriptionStatus(hasAccess: false);
    }
    if (raw is! Map) {
      // If raw is a boolean or primitive
      if (raw == true || raw.toString().toLowerCase() == 'true') {
        return UserSubscriptionStatus(hasAccess: true);
      }
      return UserSubscriptionStatus(hasAccess: false);
    }

    Map<String, dynamic> json = Map<String, dynamic>.from(raw);

    // Unwrap 'data', 'value', 'result' wrappers if present
    if (json.containsKey('data') && json['data'] is Map) {
      json = Map<String, dynamic>.from(json['data'] as Map);
    } else if (json.containsKey('value') && json['value'] is Map) {
      json = Map<String, dynamic>.from(json['value'] as Map);
    } else if (json.containsKey('result') && json['result'] is Map) {
      json = Map<String, dynamic>.from(json['result'] as Map);
    }

    final sub = json['subscription'];
    String? statusStr;
    String? planNameStr;
    DateTime? periodEndDt;

    if (sub is Map) {
      statusStr = sub['status']?.toString();
      planNameStr = sub['planName']?.toString() ??
          (sub['plan'] is Map ? sub['plan']['name']?.toString() : null);
      if (sub['currentPeriodEnd'] != null) {
        periodEndDt = DateTime.tryParse(sub['currentPeriodEnd'].toString());
      } else if (sub['endDate'] != null) {
        periodEndDt = DateTime.tryParse(sub['endDate'].toString());
      }
    } else if (sub is String) {
      statusStr = sub;
    }

    // NOTE: Only use subscriptionStatus, NOT json['status'] which is user account status
    statusStr ??= json['subscriptionStatus']?.toString();
    planNameStr ??= json['planName']?.toString() ??
        (json['plan'] is Map ? json['plan']['name']?.toString() : json['plan']?.toString());
    if (periodEndDt == null && json['currentPeriodEnd'] != null) {
      periodEndDt = DateTime.tryParse(json['currentPeriodEnd'].toString());
    }

    final s = (sub is Map ? sub['status']?.toString() : null) ?? json['subscriptionStatus']?.toString();
    final isStatusActive = s != null && (s.toLowerCase() == 'active' || s.toLowerCase() == 'trialing' || s.toLowerCase() == 'paid');

    bool hasAccess = false;
    if (json['hasAccess'] == false || json['isSubscribed'] == false) {
      hasAccess = false;
    } else {
      hasAccess = json['hasAccess'] == true ||
          json['isSubscribed'] == true ||
          json['hasActivePlan'] == true ||
          json['subscribed'] == true ||
          isStatusActive ||
          (sub is Map &&
              (sub['isActive'] == true ||
                  sub['hasAccess'] == true ||
                  (sub['status']?.toString().toLowerCase() == 'active'))) ||
          (sub == true);
    }

    return UserSubscriptionStatus(
      hasAccess: hasAccess,
      status: statusStr,
      planName: planNameStr,
      periodEnd: periodEndDt,
      rawData: json,
    );
  }
}

class SubscriptionService {
  static const String _prefKeyHasAccess = 'is_subscribed';
  static const String _prefKeyStatus = 'subscription_status';
  static const String _prefKeyPlanName = 'subscription_plan_name';

  static UserSubscriptionStatus? _cachedStatus;

  /// In-memory fast check (instantaneous for UI build methods)
  static bool get isSubscribedInMemory => _cachedStatus?.hasAccess ?? false;

  /// Checks local SharedPreferences cache for subscription status
  static Future<bool> isSubscribedLocally() async {
    if (_cachedStatus != null) {
      return _cachedStatus!.hasAccess;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasAccess = prefs.getBool(_prefKeyHasAccess) ?? false;
      final status = prefs.getString(_prefKeyStatus);
      final planName = prefs.getString(_prefKeyPlanName);
      if (hasAccess) {
        _cachedStatus = UserSubscriptionStatus(
          hasAccess: true,
          status: status,
          planName: planName,
        );
      }
      return hasAccess;
    } catch (_) {
      return false;
    }
  }

  /// Cache a subscription status locally in SharedPreferences & in-memory
  static Future<void> cacheSubscriptionStatus(UserSubscriptionStatus status) async {
    _cachedStatus = status;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKeyHasAccess, status.hasAccess);
      if (status.status != null) {
        await prefs.setString(_prefKeyStatus, status.status!);
      }
      if (status.planName != null) {
        await prefs.setString(_prefKeyPlanName, status.planName!);
      }
      debugPrint('💾 [SubscriptionService] Cached subscription state locally: hasAccess=${status.hasAccess}, status="${status.status}", plan="${status.planName}"');
    } catch (e) {
      debugPrint('⚠️ [SubscriptionService] Error caching subscription status: $e');
    }
  }

  /// Clear subscription cache on logout
  static Future<void> clearSubscriptionCache() async {
    _cachedStatus = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyHasAccess);
      await prefs.remove(_prefKeyStatus);
      await prefs.remove(_prefKeyPlanName);
      debugPrint('🗑️ [SubscriptionService] Cleared subscription local cache');
    } catch (_) {}
  }

  /// Checks subscription from backend API (/subscriptions/me) with token injection,
  /// full raw JSON logging, and local caching.
  static Future<UserSubscriptionStatus> checkMySubscription({bool forceRefresh = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // Check if user is logged in
      final isLoggedIn = token != null && token.isNotEmpty;
      if (!isLoggedIn) {
        debugPrint('ℹ️ [SubscriptionService] User not logged in, returning hasAccess = false');
        _cachedStatus = UserSubscriptionStatus(hasAccess: false);
        return _cachedStatus!;
      }

      debugPrint('💳 [SubscriptionService] Calling GET /subscriptions/me...');
      final response = await ApiClient.dio.get(
        '/subscriptions/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      debugPrint('═══════════════════════════════════════════');
      debugPrint('💳 [SubscriptionService] GET /subscriptions/me — STATUS: ${response.statusCode}');
      debugPrint('💳 [SubscriptionService] RAW RESPONSE TYPE: ${response.data.runtimeType}');
      debugPrint('💳 [SubscriptionService] RAW RESPONSE DATA: ${response.data}');
      debugPrint('═══════════════════════════════════════════');

      final status = UserSubscriptionStatus.fromJson(response.data);
      debugPrint('💳 [SubscriptionService] PARSED RESULT → hasAccess: ${status.hasAccess}, status: "${status.status}", plan: "${status.planName}"');

      await cacheSubscriptionStatus(status);
      return status;
    } catch (e) {
      debugPrint('❌ [SubscriptionService] Error checking subscription status: $e');
      // On error (such as 401 Unauthorized or network issue), never assume active access
      _cachedStatus = UserSubscriptionStatus(hasAccess: false);
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_prefKeyHasAccess, false);
      } catch (_) {}
      return _cachedStatus!;
    }
  }
}
