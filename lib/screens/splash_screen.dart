import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:audioplayers/audioplayers.dart';
import '../widgets/orientation_logo.dart';
import '../widgets/loading_indicator.dart';
import '../core/api_client.dart';
import '../controllers/auth_controller.dart';
import 'main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _progressAnimation;
  AudioPlayer? _audioPlayer;
  bool _didNavigate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2800),
      vsync: this,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _playIntroSound();
    _startAppInitialization();
  }

  Future<void> _playIntroSound() async {
    try {
      _audioPlayer = AudioPlayer();
      await _audioPlayer?.setVolume(1.0);
      await _audioPlayer?.play(AssetSource('sounds/intro_sound.mp3'));
    } catch (e) {
      debugPrint('⚠️ [SplashScreen] Intro sound note: $e');
    }
  }

  Future<void> _startAppInitialization() async {
    // 1. Kick off token verification concurrently with the splash animation.
    // Use a safety timeout so slow networks do not freeze the splash indefinitely.
    final authFuture = ApiClient.checkAuthStatus().timeout(
      const Duration(seconds: 6),
      onTimeout: () {
        debugPrint('⏱️ [SplashScreen] checkAuthStatus timed out → trusting cached session');
        return AuthStatus.authenticated;
      },
    );

    // 2. Await the visual progress bar animation to complete smoothly
    try {
      await _controller.forward();
    } catch (_) {
      // Controller disposed or animation canceled
    }

    // 3. Await the auth status result
    final authStatus = await authFuture;

    if (!mounted || _didNavigate) return;
    _didNavigate = true;

    if (authStatus == AuthStatus.authenticated) {
      debugPrint('🚀 [SplashScreen] Authenticated → navigating to MainScreen');
      if (Get.isRegistered<AuthController>()) {
        try {
          await Get.find<AuthController>().loadCachedAuthState();
        } catch (_) {}
      }

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      });
    } else {
      debugPrint('🚀 [SplashScreen] Unauthenticated / Guest → navigating to MainScreen');
      if (Get.isRegistered<AuthController>()) {
        try {
          Get.find<AuthController>().currentUser.value = null;
        } catch (_) {}
      }

      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const MainScreen(),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    try {
      _audioPlayer?.stop();
      _audioPlayer?.dispose();
    } catch (_) {}
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 400;
            final logoScale = isSmallScreen ? 0.82 : 1.0;

            return Column(
              children: [
                // Main content area with logo centered and ambient aura
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Soft cinematic radial red glow
                        Container(
                          width: 280,
                          height: 280,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                const Color(0xFFE50914).withValues(alpha: 0.12),
                                const Color(0xFFE50914).withValues(alpha: 0.03),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                        // Animated Logo with glint & aura
                        Transform.scale(
                          scale: logoScale,
                          child: const OrientationLogo(
                            animate: true,
                            showAura: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Loading section at bottom
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth * 0.15,
                    vertical: 40,
                  ),
                  child: AnimatedBuilder(
                    animation: _progressAnimation,
                    builder: (context, child) {
                      return LoadingIndicator(
                        progress: _progressAnimation.value,
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
