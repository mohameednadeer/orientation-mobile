import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/clip_model.dart';
import '../services/clip_service.dart';
import '../reels/reels_screen.dart';

/// Centralized deep linking service using AppLinks.
/// Handles external URLs such as:
/// - https://orientation.app/reels/:id
/// - https://orientationapps.com/reels/:id
/// - orientation://reels/:id
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isHandling = false;

  /// Initializes deep link listeners for both cold start and warm foreground/background launches.
  Future<void> init() async {
    try {
      // 1. Check for initial link when app launched via deep link
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 [DeepLinkService] Cold start link detected: $initialUri');
        _handleUri(initialUri);
      }

      // 2. Listen to subsequent deep links while app is running
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (uri) {
          debugPrint('🔗 [DeepLinkService] Stream link received: $uri');
          _handleUri(uri);
        },
        onError: (err) {
          debugPrint('❌ [DeepLinkService] Link stream error: $err');
        },
      );
    } catch (e) {
      debugPrint('❌ [DeepLinkService] Initialization error: $e');
    }
  }

  void _handleUri(Uri uri) {
    debugPrint('🔗 [DeepLinkService] Parsing URI: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}');

    String? clipId;

    // Pattern 1: https://orientation.app/reels/:id or https://orientationapps.com/reels/:id
    final segments = uri.pathSegments;
    if (segments.isNotEmpty && segments[0].toLowerCase() == 'reels' && segments.length >= 2) {
      clipId = segments[1];
    }
    // Pattern 2: orientation://reels/:id
    else if (uri.scheme.toLowerCase() == 'orientation' && uri.host.toLowerCase() == 'reels') {
      if (segments.isNotEmpty) {
        clipId = segments[0];
      }
    }

    if (clipId != null && clipId.isNotEmpty) {
      debugPrint('🎬 [DeepLinkService] Extracted target reel ID: $clipId');
      _navigateToReel(clipId);
    }
  }

  Future<void> _navigateToReel(String clipId) async {
    if (_isHandling) return;
    _isHandling = true;

    try {
      // Small delay to ensure Flutter widget tree / GetMaterialApp is mounted
      await Future.delayed(const Duration(milliseconds: 400));

      ClipService? clipService;
      if (Get.isRegistered<ClipService>()) {
        clipService = Get.find<ClipService>();
      }

      List<ClipModel> clips = [];
      ClipModel? targetClip;

      if (clipService != null) {
        try {
          final fetchedClips = await clipService.getClips(page: 1, limit: 50);
          clips = List<ClipModel>.from(fetchedClips);
          final existingIdx = clips.indexWhere((c) => c.id == clipId);
          if (existingIdx != -1) {
            targetClip = clips[existingIdx];
          }
        } catch (e) {
          debugPrint('⚠️ [DeepLinkService] Error loading clip list: $e');
        }

        // If not found in page 1, fetch single clip by ID
        if (targetClip == null) {
          try {
            targetClip = await clipService.getClipById(clipId);
            if (targetClip != null) {
              clips.insert(0, targetClip);
            }
          } catch (e) {
            debugPrint('⚠️ [DeepLinkService] Error loading single clip: $e');
          }
        }
      }

      if (targetClip != null) {
        final targetIndex = clips.indexWhere((c) => c.id == clipId);
        final initialIndex = targetIndex != -1 ? targetIndex : 0;

        debugPrint('🚀 [DeepLinkService] Navigating to ReelsScreen with clip: $clipId at index $initialIndex');
        Get.to(() => ReelsScreen(
          clips: clips,
          initialIndex: initialIndex,
          initialVisible: true,
        ));
      } else {
        debugPrint('⚠️ [DeepLinkService] Could not resolve clip model for ID: $clipId');
      }
    } catch (e) {
      debugPrint('❌ [DeepLinkService] Navigation error: $e');
    } finally {
      _isHandling = false;
    }
  }

  void dispose() {
    _linkSubscription?.cancel();
  }
}
