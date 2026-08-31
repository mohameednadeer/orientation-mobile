import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/social_auth_service.dart';
import '../services/dio_client.dart';
import '../models/user_model.dart';
import '../screens/main_screen.dart';

class AuthController extends GetxController {
  final SocialAuthService _socialAuthService = SocialAuthService();
  final DioClient _dioClient = DioClient();

  var isLoading = false.obs;
  var isGoogleLoading = false.obs;
  var isFacebookLoading = false.obs;
  var errorMessage = ''.obs;

  Future<void> signInWithGoogle() async {
    try {
      isGoogleLoading.value = true;
      isLoading.value = true;
      errorMessage.value = '';

      final idToken = await _socialAuthService.signInWithGoogle();
      if (idToken == null) {
        isGoogleLoading.value = false;
        isLoading.value = false;
        return; // User canceled
      }

      await _sendTokenToBackend('/auth/google', idToken);
    } catch (e) {
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('cancel')) {
        isGoogleLoading.value = false;
        isLoading.value = false;
        return; // User canceled, suppress error
      }
      errorMessage.value = 'Failed to sign in with Google. Please try again.';
      Get.snackbar('Google Login Failed', errorMessage.value,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      isGoogleLoading.value = false;
      isLoading.value = false;
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

      final response = await _dioClient.dio.post(
        resolvedEndpoint,
        data: payload,
      );

      final data = response.data as Map<String, dynamic>;
      final accessToken = data['accessToken']?.toString() ?? data['token']?.toString() ?? '';
      final refreshToken = data['refreshToken']?.toString() ?? '';
      final userId = data['id']?.toString() ?? '';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);

      // Fetch profile to get full user model details
      UserModel user;
      try {
        final profileResponse = await _dioClient.dio.get('/users/profile');
        user = UserModel.fromJson(profileResponse.data as Map<String, dynamic>);
      } catch (e) {
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

      // Navigate to Home Feed
      Get.offAll(() => const MainScreen());
    } catch (e) {
      throw Exception('Backend authentication failed: $e');
    }
  }
}
