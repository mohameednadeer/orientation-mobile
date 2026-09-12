import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/clip_model.dart';
import '../services/clip_service.dart';
import '../reels/reels_screen.dart';
import '../screens/project_details_screen.dart';

/// Centralized deep linking service using AppLinks.
/// Handles external URLs such as:
/// - https://orientationapps.com/project/:id
/// - https://orientationapps.com/projects/:id
/// - https://orientationapps.com/reels/:id
/// - orientation://project/:id
/// - orientation://reels/:id
class DeepLinkService {
  static final DeepLinkService instance = DeepLinkService._internal();
  factory DeepLinkService() => instance;
  DeepLinkService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  bool _isHandling = false;

  /// Initializes deep link listeners for both cold start and warm foreground/background launches.
  Future<void> init() async {
    try {
      // 1. Check for initial link when app launched via deep link (Cold Start)
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        debugPrint('🔗 [DeepLinkService] Cold start link detected: $initialUri');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleUri(initialUri);
        });
      }

      // 2. Listen to subsequent deep links while app is running (Warm Start)
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
    debugPrint(
        '🔗 [DeepLinkService] Parsing URI: scheme=${uri.scheme}, host=${uri.host}, path=${uri.path}');

    List<String> segments = [];
    if (uri.scheme.toLowerCase() == 'orientation') {
      if (uri.host.isNotEmpty) {
        segments = [uri.host, ...uri.pathSegments];
      } else {
        segments = uri.pathSegments;
      }
    } else {
      segments = uri.pathSegments;
    }

    if (segments.length < 2) return;
    final resourceType = segments[0].toLowerCase();
    final resourceId = segments[1];
    if (resourceId.isEmpty) return;

    if (resourceType == 'project' || resourceType == 'projects') {
      debugPrint('🚀 [DeepLinkService] Opening Project: $resourceId');
      _navigateToProject(resourceId);
    } else if (resourceType == 'reels' || resourceType == 'reel') {
      debugPrint('🎬 [DeepLinkService] Opening Reel: $resourceId');
      _navigateToReel(resourceId);
    }
  }

  void _navigateToProject(String projectId) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailsScreen(projectId: projectId),
        ),
      );
    } else {
      Get.to(() => ProjectDetailsScreen(projectId: projectId));
    }
  }

  Future<void> _navigateToReel(String clipId) async {
    if (_isHandling) return;
    _isHandling = true;

    try {
      await Future.delayed(const Duration(milliseconds: 300));

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

        if (navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(
              builder: (_) => ReelsScreen(
                clips: clips,
                initialIndex: initialIndex,
                initialVisible: true,
              ),
            ),
          );
        } else {
          Get.to(() => ReelsScreen(
                clips: clips,
                initialIndex: initialIndex,
                initialVisible: true,
              ));
        }
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
