import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/social_auth_service.dart';
import '../services/dio_client.dart';
import '../models/user_model.dart';
import '../core/api_client.dart';
import '../services/subscription_service.dart';
import '../screens/main_screen.dart';

class AuthController extends GetxController {
  final SocialAuthService _socialAuthService = SocialAuthService();
  final DioClient _dioClient = DioClient();

  var isLoading = false.obs;
  var isGoogleLoading = false.obs;
  var isFacebookLoading = false.obs;
  var errorMessage = ''.obs;

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final Rx<UserSubscriptionStatus> currentSubscription =
      UserSubscriptionStatus(hasAccess: false).obs;

  @override
  void onInit() {
    super.onInit();
    loadCachedAuthState();
  }

  /// Initialize and load cached user & subscription state on app start (0 network calls)
  Future<void> loadCachedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasToken = (prefs.getString('auth_token')?.isNotEmpty ?? false) ||
          (prefs.getString('token')?.isNotEmpty ?? false);
      
      final localAccess = prefs.getBool('user_is_subscribed') ??
          prefs.getBool('user_has_subscription_access') ??
          false;
      currentSubscription.value = UserSubscriptionStatus(hasAccess: localAccess);

      if (hasToken) {
        final userId = prefs.getString('user_id') ?? '';
        final fName = prefs.getString('user_first_name') ?? '';
        final lName = prefs.getString('user_last_name') ?? '';
        final fullName = (fName.isNotEmpty || lName.isNotEmpty) ? '$fName $lName'.trim() : '';
        final username = fullName.isNotEmpty
            ? fullName
            : (prefs.getString('user_name') ?? prefs.getString('username') ?? 'User');
        final email = prefs.getString('user_email') ?? prefs.getString('email') ?? '';
        final role = prefs.getString('user_role') ?? prefs.getString('role') ?? 'user';
        final phone = prefs.getString('user_phone');
        currentUser.value = UserModel(
          id: userId,
          username: username,
          email: email,
          role: role,
          phoneNumber: phone,
        );

        // Fetch /subscriptions/me once globally on root initialization
        fetchGlobalSubscription();
      }
    } catch (e) {
      debugPrint('⚠️ [AuthController] Error loading cached auth state: $e');
    }
  }

  /// Fetches GET /subscriptions/me ONCE globally and updates the reactive state
  Future<void> fetchGlobalSubscription({bool forceRefresh = false}) async {
    try {
      final status = await SubscriptionService.checkMySubscription(forceRefresh: forceRefresh);
      currentSubscription.value = status;
      debugPrint('💎 [AuthController] Global subscription state updated: hasAccess=${status.hasAccess}');
    } catch (e) {
      debugPrint('⚠️ [AuthController] Failed to fetch global subscription: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      isGoogleLoading.value = true;
      isLoading.value = true;
      errorMessage.value = '';
      debugPrint('🔵 [AuthController] signInWithGoogle() started');

      final idToken = await _socialAuthService.signInWithGoogle();
      debugPrint('🔵 [AuthController] idToken received: ${idToken != null ? "present (${idToken.length} chars)" : "NULL"}');

      if (idToken == null) {
        debugPrint('🔵 [AuthController] Google sign-in was canceled or returned no account.');
        Get.snackbar(
          'Google Sign-In',
          'Sign-in was canceled or no Google account was selected.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
        return;
      }

      debugPrint('🔵 [AuthController] Sending idToken to backend /auth/google/mobile ...');
      await _sendTokenToBackend('/auth/google', idToken);
      debugPrint('✅ [AuthController] Google sign-in complete!');
    } catch (e, stackTrace) {
      debugPrint('❌❌❌ [AuthController] signInWithGoogle ERROR: $e');
      debugPrint('❌❌❌ [AuthController] ERROR TYPE: ${e.runtimeType}');
      debugPrint('❌❌❌ [AuthController] STACK TRACE: $stackTrace');

      final errorMsg = e.toString().replaceFirst('Exception: ', '');
      errorMessage.value = errorMsg;
      Get.snackbar(
        'Google Login Failed',
        errorMsg,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: const Color(0xFFD32F2F),
        colorText: const Color(0xFFFFFFFF),
        duration: const Duration(seconds: 5),
      );
    } finally {
      isGoogleLoading.value = false;
      isLoading.value = false;
      debugPrint('🔵 [AuthController] Reset isGoogleLoading to false');
    }
  }

  Future<void> signInWithFacebook() async {
    try {
      isFacebookLoading.value = true;
      isLoading.value = true;
      errorMessage.value = '';

      final accessToken = await _socialAuthService.signInWithFacebook();
      if (accessToken == null) {
        isFacebookLoading.value = false;
        isLoading.value = false;
        return; // User canceled
      }

      await _sendTokenToBackend('/auth/facebook', accessToken);
    } catch (e) {
      errorMessage.value = e.toString();
      Get.snackbar('Facebook Login Failed', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isFacebookLoading.value = false;
      isLoading.value = false;
    }
  }

  Future<void> _sendTokenToBackend(String endpoint, String token) async {
    try {
      // Map endpoint and request payload
      String resolvedEndpoint = endpoint;
      Map<String, dynamic> payload = {'token': token};
      
      if (endpoint == '/auth/google') {
        resolvedEndpoint = '/auth/google/mobile';
        payload = {'idToken': token};
      } else if (endpoint == '/auth/facebook') {
        resolvedEndpoint = '/auth/facebook/mobile';
        payload = {'accessToken': token};
      }

      debugPrint('🔵 [AuthController] POST $resolvedEndpoint');
      final response = await _dioClient.dio.post(
        resolvedEndpoint,
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      debugPrint('🔵 [AuthController] Backend response keys: ${data.keys.toList()}');
      debugPrint('🔵 [AuthController] Backend response: $data');

      final accessToken = data['accessToken']?.toString() ?? data['token']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';
      final userId = data['id']?.toString() ?? '';

      debugPrint('🔵 [AuthController] accessToken: ${accessToken.isNotEmpty ? "present" : "EMPTY"}');
      debugPrint('🔵 [AuthController] refreshToken: ${refreshToken.isNotEmpty ? "present" : "EMPTY"}');
      debugPrint('🔵 [AuthController] userId: $userId');

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      // Fetch profile to get full user model details
      UserModel user;
      try {
        debugPrint('🔵 [AuthController] Fetching /users/profile after social login...');
        final profileResponse = await _dioClient.dio.get('/users/profile');
        debugPrint('🔵 [AuthController] Profile response: ${profileResponse.data}');
        
        // Unwrap 'user' key if present (same pattern as auth_api.dart)
        final responseData = profileResponse.data;
        Map<String, dynamic> profileMap = {};
        if (responseData is Map<String, dynamic>) {
          if (responseData.containsKey('user') && responseData['user'] is Map) {
            profileMap = Map<String, dynamic>.from(responseData['user'] as Map);
          } else if (responseData.containsKey('value') && responseData['value'] is Map) {
            profileMap = Map<String, dynamic>.from(responseData['value'] as Map);
          } else if (responseData.containsKey('data') && responseData['data'] is Map) {
            profileMap = Map<String, dynamic>.from(responseData['data'] as Map);
          } else {
            profileMap = responseData;
          }
        }
        user = UserModel.fromJson(profileMap);
        final pFirstName = profileMap['firstName']?.toString() ?? '';
        final pLastName = profileMap['lastName']?.toString() ?? '';
        final pProfilePicture = profileMap['profilePicture']?.toString()
            ?? profileMap['avatar']?.toString()
            ?? profileMap['photo']?.toString()
            ?? '';
        if (pFirstName.isNotEmpty) await prefs.setString('user_first_name', pFirstName);
        if (pLastName.isNotEmpty) await prefs.setString('user_last_name', pLastName);
        if (pProfilePicture.isNotEmpty) await prefs.setString('user_profile_picture', pProfilePicture);
      } catch (e) {
        debugPrint('⚠️ [AuthController] Profile fetch failed: $e');
        // Fallback: construct skeleton UserModel
        user = UserModel(
          id: userId,
          username: 'User',
          email: '',
          role: 'user',
        );
      }

      await prefs.setString('user_id', user.id);
      await prefs.setString('user_email', user.email);
      await prefs.setString('user_name', user.username);
      await prefs.setString('user_role', user.role);
      if (user.phoneNumber != null) {
        await prefs.setString('user_phone', user.phoneNumber!);
      }

      // Also save to ApiClient (FlutterSecureStorage) for global interceptors
      try {
        await ApiClient.saveTokens(accessToken: accessToken, refreshToken: refreshToken);
        debugPrint('✅ [AuthController] Saved tokens to ApiClient secure storage');
      } catch (storageErr) {
        debugPrint('⚠️ [AuthController] ApiClient saveTokens non-fatal error: $storageErr');
      }

      currentUser.value = user;

      // Cache subscription status immediately if user is subscribed
      if (user.isSubscribed) {
        final subStatus = UserSubscriptionStatus(
          hasAccess: true,
          status: user.subscriptionStatus,
          planName: user.planName,
        );
        currentSubscription.value = subStatus;
        await SubscriptionService.cacheSubscriptionStatus(subStatus);
      }

      // Fetch latest subscription once in background
      fetchGlobalSubscription(forceRefresh: true);

      debugPrint('✅ [AuthController] Social login stored successfully. Navigating to MainScreen...');
      // Navigate to Main Screen
      Get.offAll(() => const MainScreen());
    } catch (e, stackTrace) {
      debugPrint('❌ [AuthController] _sendTokenToBackend ERROR: $e');
      debugPrint('❌ [AuthController] STACK TRACE: $stackTrace');
      throw Exception('Backend authentication failed: $e');
    }
  }
}
