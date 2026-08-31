import '../core/api_client.dart';

class UserSubscriptionStatus {
  final bool hasAccess;
  final String? status;
  final String? planName;
  final DateTime? periodEnd;

  UserSubscriptionStatus({
    required this.hasAccess,
    this.status,
    this.planName,
    this.periodEnd,
  });

  factory UserSubscriptionStatus.fromJson(dynamic json) {
    if (json is! Map) {
      return UserSubscriptionStatus(hasAccess: false);
    }
    final sub = json['subscription'];
    return UserSubscriptionStatus(
      hasAccess: json['hasAccess'] == true,
      status: sub is Map ? sub['status']?.toString() : null,
      planName: sub is Map ? sub['planName']?.toString() : null,
      periodEnd: (sub is Map && sub['currentPeriodEnd'] != null)
          ? DateTime.tryParse(sub['currentPeriodEnd'].toString())
          : null,
    );
  }
}

class SubscriptionService {
  static Future<UserSubscriptionStatus> checkMySubscription() async {
    try {
      final response = await ApiClient.dio.get('/subscriptions/me');
      return UserSubscriptionStatus.fromJson(response.data);
    } catch (e) {
      print('Error checking subscription status: $e');
      // Default fallback if query fails (no access)
      return UserSubscriptionStatus(hasAccess: false);
    }
  }
}
