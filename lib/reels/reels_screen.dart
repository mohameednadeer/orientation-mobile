import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_toast.dart';
import '../services/api/improved_clip_api.dart';
import '../services/api/project_api.dart';
import '../models/clip_model.dart';
import '../models/project_model.dart';
import '../services/clip_service.dart';
import '../services/projects_service.dart';
import '../services/in_memory_cache_service.dart';
import '../utils/auth_helper.dart';
import '../screens/main_screen.dart';
import '../screens/project_details_screen.dart';
import 'video_controller_manager.dart';
import '../main.dart'; // Added for routeObserver

class ReelsScreen extends StatefulWidget {
  final List<ClipModel> clips;
  final int initialIndex;
  final bool initialVisible;
  final VoidCallback? onBack;
  final bool isSavedOnlyContext;
  final Set<String>? initialSavedIds;

  const ReelsScreen({
    super.key,
    required this.clips,
    this.initialIndex = 0,
    this.initialVisible = true,
    this.onBack,
    this.isSavedOnlyContext = false,
    this.initialSavedIds,
  });

  @override
  State<ReelsScreen> createState() => ReelsScreenState();
}

class ReelsScreenState extends State<ReelsScreen>
    with WidgetsBindingObserver, RouteAware {
  late PageController _pageController;
  late VideoControllerManager _videoManager;
  ClipService? _clipService;
  late bool _isScreenVisible;

  late List<ClipModel> _clips;
  int _currentIndex = 0;
  int _currentPage = 1;
  static const int _pageSize = 10;
  bool _isLoadingMore = false;
  bool _hasMore = true;

  bool _hasSavedStateChanged = false;

  static const Color brandRed = Color(0xFFE50914);

  @override
  void initState() {
    super.initState();
    _isScreenVisible = widget.initialVisible;
    _clips = List<ClipModel>.from(widget.clips);
    _videoManager = VideoControllerManager();
    _videoManager.setVisible(widget.initialVisible);
    _pageController = PageController(initialPage: widget.initialIndex);
    _currentIndex = widget.initialIndex;

    if (widget.isSavedOnlyContext) {
      _hasMore = false;
    }

    try {
      if (Get.isRegistered<ClipService>()) {
        _clipService = Get.find<ClipService>();
      }
    } catch (_) {}
    _clipService ??= ClipService(
      clipApi: Get.isRegistered<ImprovedClipApi>()
          ? Get.find<ImprovedClipApi>()
          : ImprovedClipApi(),
      projectApi: Get.isRegistered<ProjectApi>()
          ? Get.find<ProjectApi>()
          : ProjectApi(),
    );

    WidgetsBinding.instance.addObserver(this);

    _syncSavedReelsFromPrefs();

    // Trigger initial page playback & pre-buffering
    if (_clips.isNotEmpty) {
      _videoManager.onPageChanged(widget.initialIndex, _clips);
    } else {
      _loadInitialClips();
    }
  }

  Future<void> _syncSavedReelsFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = (prefs.getStringList('saved_reels') ?? []).toSet();
      if (widget.initialSavedIds != null) {
        savedIds.addAll(widget.initialSavedIds!);
      }
      if (savedIds.isNotEmpty && mounted) {
        setState(() {
          _clips = _clips
              .map((c) => savedIds.contains(c.id) ? c.copyWith(isSaved: true) : c)
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _loadInitialClips() async {
    _clipService ??= ClipService(
      clipApi: Get.isRegistered<ImprovedClipApi>()
          ? Get.find<ImprovedClipApi>()
          : ImprovedClipApi(),
      projectApi: Get.isRegistered<ProjectApi>()
          ? Get.find<ProjectApi>()
          : ProjectApi(),
    );
    try {
      final initial = await _clipService!.getClips(page: 1, limit: _pageSize);
      if (!mounted) return;
      if (initial.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final savedIds = (prefs.getStringList('saved_reels') ?? []).toSet();
        if (widget.initialSavedIds != null) {
          savedIds.addAll(widget.initialSavedIds!);
        }

        final mapped = initial
            .map((c) => savedIds.contains(c.id) ? c.copyWith(isSaved: true) : c)
            .toList();

        setState(() {
          _clips = mapped;
          _currentPage = 1;
          _hasMore = initial.length >= _pageSize;
        });
        _videoManager.onPageChanged(_currentIndex, _clips);
      }
    } catch (e) {
      debugPrint('ReelsScreen: Error loading initial clips: $e');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void didUpdateWidget(covariant ReelsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialVisible != widget.initialVisible) {
      _isScreenVisible = widget.initialVisible;
      _videoManager.setVisible(widget.initialVisible);
    }
    if (oldWidget.clips != widget.clips) {
      if (widget.clips.isNotEmpty) {
        _clips = List<ClipModel>.from(widget.clips);
      }
      if (widget.initialSavedIds != null) {
        _clips = _clips
            .map((c) => widget.initialSavedIds!.contains(c.id)
                ? c.copyWith(isSaved: true)
                : c)
            .toList();
      }
      if (_currentIndex >= _clips.length) {
        _currentIndex = (_clips.length - 1).clamp(0, double.infinity).toInt();
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void didPushNext() {
    _videoManager.setVisible(false);
  }

  @override
  void didPopNext() {
    // CRITICAL: Only resume playback if this reel screen/tab is ACTUALLY visible!
    // If user is on another tab (e.g. Home tab) inside MainScreen's IndexedStack, DO NOT play!
    if (_isScreenVisible) {
      _videoManager.setVisible(true);
    }
  }

  void setVisible(bool visible) {
    _isScreenVisible = visible;
    _videoManager.setVisible(visible);
    if (visible && mounted && _clips.isNotEmpty) {
      _videoManager.onPageChanged(_currentIndex, _clips);
      setState(() {});
    }
  }


  void _onPageChanged(int index) {
    if (index < 0 || index >= _clips.length) return;

    setState(() => _currentIndex = index);

    // Enforce controller pool & preloading
    _videoManager.onPageChanged(index, _clips);

    // Infinite Pagination: When user is within 3 reels of the end, load next page
    if (!widget.isSavedOnlyContext && index >= _clips.length - 3 && !_isLoadingMore && _hasMore) {
      _loadMoreClips();
    }
  }

  Future<void> _loadMoreClips() async {
    if (widget.isSavedOnlyContext || _isLoadingMore || !_hasMore || _clipService == null) return;
    _isLoadingMore = true;

    try {
      final nextPage = _currentPage + 1;
      debugPrint('🎬 [ReelsScreen] Fetching page $nextPage for infinite scroll...');
      final newClips = await _clipService!.getClips(
        page: nextPage,
        limit: _pageSize,
      );

      if (!mounted) return;

      if (newClips.isEmpty) {
        _hasMore = false;
        debugPrint('🎬 [ReelsScreen] Reached end of feed (no more clips)');
      } else {
        // De-duplicate newly fetched clips
        final existingIds = _clips.map((c) => c.id).toSet();
        final uniqueNew =
            newClips.where((c) => !existingIds.contains(c.id)).toList();

        if (uniqueNew.isEmpty) {
          _hasMore = false;
        } else {
          final prefs = await SharedPreferences.getInstance();
          final savedIds = (prefs.getStringList('saved_reels') ?? []).toSet();
          final mappedNew = uniqueNew
              .map((c) => savedIds.contains(c.id) ? c.copyWith(isSaved: true) : c)
              .toList();

          _currentPage = nextPage;
          _clips.addAll(mappedNew);
          debugPrint(
              '🎬 [ReelsScreen] Appended ${mappedNew.length} clips. Total: ${_clips.length}');
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('❌ [ReelsScreen] Error loading more clips: $e');
    } finally {
      _isLoadingMore = false;
    }
  }

  Future<void> _onRefresh() async {
    if (_clipService == null) return;
    try {
      debugPrint('🔄 [ReelsScreen] Pull-to-refresh triggered...');
      final freshClips = await _clipService!.getClips(
        page: 1,
        limit: _pageSize,
        forceRefresh: true,
      );

      if (!mounted) return;

      if (freshClips.isNotEmpty) {
        setState(() {
          _clips = freshClips;
          _currentPage = 1;
          _hasMore = true;
          _currentIndex = 0;
        });

        if (_pageController.hasClients) {
          _pageController.jumpToPage(0);
        }
        _videoManager.onPageChanged(0, _clips);
      }
    } catch (e) {
      debugPrint('❌ [ReelsScreen] Error during pull-to-refresh: $e');
    }
  }

  void _onVideoTap(int index) {
    _videoManager.togglePlayPause(index);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _videoManager.pauseAll();
    } else if (state == AppLifecycleState.resumed) {
      if (_videoManager.isVisible && _clips.isNotEmpty) {
        _videoManager.onPageChanged(_currentIndex, _clips);
      }
    }
  }

  Future<void> _toggleSave(int index) async {
    if (!mounted) return;
    if (index < 0 || index >= _clips.length) return;

    _clipService ??= ClipService(
      clipApi: Get.isRegistered<ImprovedClipApi>()
          ? Get.find<ImprovedClipApi>()
          : ImprovedClipApi(),
      projectApi: Get.isRegistered<ProjectApi>()
          ? Get.find<ProjectApi>()
          : ProjectApi(),
    );

    final clip = _clips[index];
    final wasSaved = clip.isSaved;
    final newSaved = !wasSaved;

    // 1. Instant UI update
    setState(() {
      _clips[index] = clip.copyWith(isSaved: newSaved);
    });
    _hasSavedStateChanged = true;

    // 2. Show Toast feedback
    AppToast.showSave(context, isSaved: newSaved);

    // 3. Persist to local storage immediately
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIds = (prefs.getStringList('saved_reels') ?? []).toSet();
      if (newSaved) {
        savedIds.add(clip.id);
      } else {
        savedIds.remove(clip.id);
      }
      await prefs.setStringList('saved_reels', savedIds.toList());
    } catch (_) {}

    // 4. Sync with backend service in background
    try {
      if (newSaved) {
        await _clipService!.saveReel(clip.id);
      } else {
        await _clipService!.unsaveReel(clip.id);
      }
    } catch (e) {
      debugPrint('⚠️ Error syncing reel save state: $e');
    }
  }

  Future<void> _openProject(String? projectId) async {
    debugPrint('🚀 _openProject called with projectId: "$projectId"');

    if (projectId == null || projectId.isEmpty) {
      debugPrint('❌ projectId is null or empty');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project information not available'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    debugPrint('✅ projectId is valid: "$projectId"');

    debugPrint('🔐 Checking authentication...');
    final ok = await AuthHelper.requireAuth(context);
    debugPrint('🔐 Auth result: $ok');

    if (!ok) {
      debugPrint('❌ User is not authenticated or cancelled login');
      return;
    }

    if (!mounted) {
      debugPrint('❌ Widget not mounted');
      return;
    }

    debugPrint('⏸️ Pausing video...');
    _videoManager.pauseAll();

    debugPrint('🧭 Navigating to ProjectDetailsScreen...');
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProjectDetailsScreen(
            projectId: projectId,
            initialTabIndex: 0, // Project tab
          ),
        ),
      );
      debugPrint('✅ Navigation completed');
    }
  }

  Future<void> _openEpisodes(ClipModel clip) async {
    final ok = await AuthHelper.requireAuth(context);
    if (!ok || !mounted) return;
    _videoManager.pauseAll();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProjectDetailsScreen(
          projectId: clip.projectId,
          initialTabIndex: 1, // Episodes tab
        ),
      ),
    );
  }

  Future<void> _shareClip(ClipModel clip) async {
    final ok = await AuthHelper.requireAuth(context);
    if (!ok || !mounted) return;
    try {
      final shareUrl = 'https://orientation.app/reels/${clip.id}';
      final shareText = clip.title.trim().isNotEmpty
          ? '${clip.title}\n$shareUrl'
          : shareUrl;
      await Share.share(
        shareText,
        subject: clip.title,
      );
    } catch (_) {}
  }

  @override
  void deactivate() {
    // deactivate() fires BEFORE dispose() when the widget leaves the tree.
    // Kill audio here immediately so there is zero gap.
    _videoManager.pauseAll();
    super.deactivate();
  }

  @override
  void dispose() {
    // Belt-and-suspenders: stop audio, dispose controllers, clean up observers.
    _videoManager.pauseAll();
    _videoManager.disposeAll();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    _clipService?.flush();
    _videoManager.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_clips.isEmpty) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Text(
            'No reels available',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        // Kill audio BEFORE the pop so nothing leaks.
        _videoManager.pauseAll();
        _videoManager.disposeAll();
        if (widget.onBack != null) {
          widget.onBack!();
        } else if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(_hasSavedStateChanged);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: RefreshIndicator(
          color: brandRed,
          backgroundColor: Colors.black,
          onRefresh: _onRefresh,
          child: PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            physics: const PageScrollPhysics(),
            onPageChanged: _onPageChanged,
            itemCount: _clips.length,
            itemBuilder: (context, index) {
              final clip = _clips[index];
              return _ReelPage(
                key: ValueKey(clip.id),
                clip: clip,
                index: index,
                isActive: index == _currentIndex,
                videoManager: _videoManager,
                isSaved: clip.isSaved,
                onTap: () => _onVideoTap(index),
                onSaveTap: () => _toggleSave(index),
                onProjectTap: () {
                  debugPrint('🔘 Project icon tapped for clip at index $index');
                  debugPrint('📱 clip.projectId: "${clip.projectId}"');
                  _openProject(clip.projectId);
                },
                onEpisodesTap: () => _openEpisodes(clip),
                onShareTap: () => _shareClip(clip),
                onBack: () {
                  // Kill audio IMMEDIATELY before navigating away
                  _videoManager.pauseAll();
                  _videoManager.disposeAll();
                  if (widget.onBack != null) {
                    widget.onBack!();
                  } else if (Navigator.of(context).canPop()) {
                    Navigator.of(context).pop(_hasSavedStateChanged);
                  } else {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const MainScreen()),
                      (_) => false,
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReelPage extends StatefulWidget {
  final ClipModel clip;
  final int index;
  final bool isActive;
  final VideoControllerManager videoManager;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSaveTap;
  final VoidCallback onProjectTap;
  final VoidCallback onEpisodesTap;
  final VoidCallback onShareTap;
  final VoidCallback onBack;

  const _ReelPage({
    super.key,
    required this.clip,
    required this.index,
    required this.isActive,
    required this.videoManager,
    required this.isSaved,
    required this.onTap,
    required this.onSaveTap,
    required this.onProjectTap,
    required this.onEpisodesTap,
    required this.onShareTap,
    required this.onBack,
  });

  @override
  State<_ReelPage> createState() => _ReelPageState();
}

class _ReelPageState extends State<_ReelPage>
    with AutomaticKeepAliveClientMixin {
  static const Color brandRed = Color(0xFFE50914);

  @override
  bool get wantKeepAlive => true; // Keep alive for smooth swiping

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final canPop = Navigator.canPop(context);
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return AnimatedBuilder(
      animation: widget.videoManager,
      builder: (context, _) {
        final controller = widget.videoManager.controllerAt(widget.index);
        final failed = widget.videoManager.isFailed(widget.index);
        final isVideoReady =
            !failed && controller != null && controller.value.isInitialized;

        return Stack(
          fit: StackFit.expand,
          children: [
            // Solid black background container
            Container(color: Colors.black),

            // Video Player Layer / Error Placeholder
            if (failed)
              _buildErrorPlaceholder()
            else if (isVideoReady)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: widget.onTap,
                child: Center(
                  child: AspectRatio(
                    aspectRatio: controller.value.aspectRatio > 0
                        ? controller.value.aspectRatio
                        : (9 / 16),
                    child: VideoPlayer(controller),
                  ),
                ),
              ),

            // Centered Glass Play Icon (shown when paused)
            if (isVideoReady)
              ListenableBuilder(
                listenable: controller,
                builder: (_, __) {
                  if (controller.value.isPlaying ||
                      controller.value.isBuffering ||
                      !widget.isActive) {
                    return const SizedBox.shrink();
                  }
                  return Center(
                    child: IgnorePointer(
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.45),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.28),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.45),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: const Center(
                              child: Icon(
                                Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

            // Loading / Buffering indicators
            if (!failed && !isVideoReady)
              _buildLoadingOverlay()
            else if (!failed && isVideoReady)
              ListenableBuilder(
                listenable: controller,
                builder: (_, __) {
                  if (controller.value.isBuffering) {
                    return _buildBufferingIndicator();
                  }
                  return const SizedBox.shrink();
                },
              ),

            // Cinematic Top Scrim Gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: safeAreaTop + 90,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.75),
                        Colors.black.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Cinematic Deep Bottom Scrim Gradient
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 380,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      stops: const [0.0, 0.25, 0.55, 0.8, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.94),
                        Colors.black.withValues(alpha: 0.78),
                        Colors.black.withValues(alpha: 0.42),
                        Colors.black.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Top Header: Frosted Glass Back Button & Centered Brand Badge
            Positioned(
              top: safeAreaTop + 8,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (if navigation can pop)
                  if (canPop)
                    GestureDetector(
                      onTap: widget.onBack,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                color: Colors.white,
                                size: 17,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(width: 40), // Spacer for center alignment

                  // Top Center Brand Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.38),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6.5,
                              height: 6.5,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: brandRed,
                                boxShadow: [
                                  BoxShadow(
                                    color: brandRed.withValues(alpha: 0.8),
                                    blurRadius: 5,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 7),
                            const Text(
                              'REELS',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 40), // Spacer for center alignment
                ],
              ),
            ),

            // Right-side Action Buttons (Frosted Glass Floating Rail)
            Positioned(
              right: 14,
              bottom: safeAreaBottom + 90,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DesignActionButton(
                    customIcon: Image.asset(
                      'assets/icons_clips/Frame 2609297 (2).png',
                      width: 22,
                      height: 22,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    label: 'Wha App',
                    onTap: widget.onProjectTap,
                  ),
                  const SizedBox(height: 18),
                  _DesignActionButton(
                    icon: widget.isSaved
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    label: widget.isSaved ? 'Saved' : 'Save',
                    onTap: widget.onSaveTap,
                    isSaved: widget.isSaved,
                  ),
                  // Temporarily hidden share button
                  // const SizedBox(height: 18),
                  // _DesignActionButton(
                  //   icon: Icons.share_rounded,
                  //   label: 'Share',
                  //   onTap: widget.onShareTap,
                  // ),
                ],
              ),
            ),

            // Bottom Left: Project Info Bar, Caption, Audio Track
            Positioned(
              left: 16,
              bottom: safeAreaBottom + 90,
              right: 76,
              child: _ProjectInfoBar(
                clip: widget.clip,
                isActive: widget.isActive,
                onProjectTap: widget.onProjectTap,
                onEpisodesTap: widget.onEpisodesTap,
              ),
            ),

            // Bottom Scrubber / Video Progress Bar
            if (isVideoReady)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: _buildProgressBar(controller),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProgressBar(VideoPlayerController? controller) {
    if (controller == null || !controller.value.isInitialized) {
      return const SizedBox.shrink();
    }
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final totalMs = controller.value.duration.inMilliseconds;
        final currentMs = controller.value.position.inMilliseconds;
        final progress =
            totalMs > 0 ? (currentMs / totalMs).clamp(0.0, 1.0) : 0.0;
        return Container(
          height: 2.5,
          width: double.infinity,
          color: Colors.white.withValues(alpha: 0.15),
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: BoxDecoration(
                color: brandRed,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(color: brandRed.withValues(alpha: 0.6), blurRadius: 3),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingOverlay() {
    return const Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          color: brandRed,
          strokeWidth: 2.5,
        ),
      ),
    );
  }

  Widget _buildBufferingIndicator() {
    return const Center(
      child: SizedBox(
        width: 32,
        height: 32,
        child: CircularProgressIndicator(
          color: Colors.white70,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.white54, size: 48),
            SizedBox(height: 12),
            Text(
              'Video unavailable',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _DesignActionButton extends StatelessWidget {
  final Widget? customIcon;
  final IconData? icon;
  final String label;
  final VoidCallback onTap;
  final bool isSaved;

  const _DesignActionButton({
    this.customIcon,
    this.icon,
    required this.label,
    required this.onTap,
    this.isSaved = false,
  });

  static const Color brandRed = Color(0xFFE50914);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        debugPrint('🔘 _DesignActionButton tapped: $label');
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSaved
                  ? brandRed.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.38),
              border: Border.all(
                color: isSaved
                    ? brandRed.withValues(alpha: 0.85)
                    : Colors.white.withValues(alpha: 0.20),
                width: isSaved ? 1.5 : 1.2,
              ),
              boxShadow: [
                if (isSaved)
                  BoxShadow(
                    color: brandRed.withValues(alpha: 0.5),
                    blurRadius: 12,
                    spreadRadius: 1,
                  )
                else
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Center(
                  child: customIcon ??
                      Icon(
                        icon,
                        color: isSaved ? brandRed : Colors.white,
                        size: 24,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: isSaved
                  ? const Color(0xFFFF5252)
                  : Colors.white.withValues(alpha: 0.92),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 4,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic Project Info Bar with caching, project resolution, title caption & audio tag
class _ProjectInfoBar extends StatefulWidget {
  final ClipModel clip;
  final bool isActive;
  final VoidCallback onProjectTap;
  final VoidCallback onEpisodesTap;

  const _ProjectInfoBar({
    required this.clip,
    required this.isActive,
    required this.onProjectTap,
    required this.onEpisodesTap,
  });

  @override
  State<_ProjectInfoBar> createState() => _ProjectInfoBarState();
}

class _ProjectInfoBarState extends State<_ProjectInfoBar> {
  final InMemoryCacheService _cache = InMemoryCacheService();
  final ProjectsService _projectsService = ProjectsService();
  ProjectModel? _resolvedProject;

  @override
  void initState() {
    super.initState();
    _checkOrResolveProject();
  }

  @override
  void didUpdateWidget(covariant _ProjectInfoBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.clip.id != widget.clip.id ||
        oldWidget.clip.projectId != widget.clip.projectId ||
        oldWidget.isActive != widget.isActive) {
      _checkOrResolveProject();
    }
  }

  void _checkOrResolveProject() {
    // 1. Direct Binding: If clip already contains both project name and logo, 0 network requests!
    if (widget.clip.projectName.isNotEmpty &&
        widget.clip.projectLogo.isNotEmpty) {
      return;
    }

    final pid = widget.clip.projectId;
    if (pid.isEmpty) return;

    // 2. Check in-memory RAM cache first
    final cached = _cache.get<ProjectModel>('project:$pid');
    if (cached != null) {
      _resolvedProject = cached;
      return;
    }

    // 3. Strict Deferral: Do NOT fetch from network for adjacent/prebuffered reels
    if (!widget.isActive) {
      return;
    }

    // 4. Fetch with InMemoryCacheService de-duplication & TTL (Fallback only)
    _projectsService.getProjectById(pid).then((p) {
      if (mounted) {
        setState(() {
          _resolvedProject = p;
        });
      }
    }).catchError((e) {
      debugPrint('⚠️ _ProjectInfoBar: Failed to load project $pid: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Resolve Project Name
    String name = widget.clip.projectName.isNotEmpty
        ? widget.clip.projectName
        : (_resolvedProject != null && _resolvedProject!.title.isNotEmpty
            ? _resolvedProject!.title
            : (widget.clip.developerName.isNotEmpty &&
                    widget.clip.developerName != 'User'
                ? widget.clip.developerName
                : ''));

    // 2. Resolve Project Logo
    String logo = widget.clip.projectLogo.isNotEmpty
        ? widget.clip.projectLogo
        : (_resolvedProject?.logo != null &&
                _resolvedProject!.logo!.isNotEmpty
            ? _resolvedProject!.logo!
            : (_resolvedProject != null &&
                    _resolvedProject!.projectThumbnailUrl.isNotEmpty
                ? _resolvedProject!.projectThumbnailUrl
                : widget.clip.developerLogo));

    final captionText = widget.clip.title.isNotEmpty
        ? widget.clip.title
        : widget.clip.description;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Project Info Bar (Avatar + Name + Verified Badge + Watch Orientation CTA)
        Row(
          children: [
            // Gradient Ring Avatar with Logo
            GestureDetector(
              onTap: widget.onProjectTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE50914),
                      Color(0xFFFF5252),
                      Color(0xFFE50914)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(1.5),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF1E1E1E),
                  ),
                  child: ClipOval(
                    child: logo.isNotEmpty
                        ? Image.network(
                            logo,
                            width: 35,
                            height: 35,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.apartment_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.apartment_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (name.isNotEmpty) ...[
              const SizedBox(width: 8),
              // Project name with verified icon (clickable)
              Flexible(
                child: GestureDetector(
                  onTap: widget.onProjectTap,
                  behavior: HitTestBehavior.opaque,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.36,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                              shadows: [
                                Shadow(
                                  color: Colors.black87,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          color: Color(0xFFE50914),
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 8),
            // Elevated Watch Orientation CTA Button
            GestureDetector(
              onTap: widget.onEpisodesTap,
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE50914), Color(0xFFB30710)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE50914).withValues(alpha: 0.45),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 14),
                    SizedBox(width: 3),
                    Text(
                      'Watch Orientation',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white70, size: 9),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Text Caption
        if (captionText.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            captionText,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 12.5,
              fontWeight: FontWeight.w400,
              height: 1.38,
              shadows: const [
                Shadow(
                  color: Colors.black87,
                  blurRadius: 5,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],

        // Audio / Track Tag Capsule
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.12), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.graphic_eq_rounded,
                  color: Colors.white70, size: 13),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  name.isNotEmpty
                      ? '$name • Original Audio'
                      : 'Original Video',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.music_note_rounded,
                  color: Colors.white54, size: 11),
            ],
          ),
        ),
      ],
    );
  }
}
