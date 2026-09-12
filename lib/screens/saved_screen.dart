import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/project_model.dart';
import '../models/clip_model.dart';
import '../services/api/project_api.dart';
import '../services/clip_service.dart';
import '../utils/auth_helper.dart';
import 'project_details_screen.dart';
import '../reels/reels_screen.dart';
import '../widgets/app_toast.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen>
    with SingleTickerProviderStateMixin {
  final ProjectApi _projectApi = Get.find<ProjectApi>();
  late final ClipService _clipService;
  late TabController _tabController;

  List<ProjectModel> _savedProjects = [];
  List<ClipModel> _savedReels = [];
  bool _isLoadingProjects = true;
  bool _isLoadingReels = true;
  bool _isRefreshing = false; // Prevent multiple simultaneous refreshes

  @override
  void initState() {
    super.initState();
    _clipService = Get.find<ClipService>();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedProjects();
    _loadSavedReels();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProjects() async {
    if (!mounted) return;

    setState(() {
      _isLoadingProjects = true;
    });

    try {
      final projects = await _projectApi.getSavedProjects();
      if (mounted) {
        setState(() {
          _savedProjects = projects;
          _isLoadingProjects = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading saved projects: $e');
      if (mounted) {
        setState(() {
          _isLoadingProjects = false;
        });
      }
    }
  }

  Future<void> _loadSavedReels() async {
    if (!mounted) return;

    setState(() {
      _isLoadingReels = true;
    });

    try {
      // Use exactly what the backend returns. Do NOT call getClipById
      // per-reel — full reel detail is only fetched on tap,
      // not while rendering the list.
      final savedReels = await _clipService.getSavedReels();

      if (mounted) {
        setState(() {
          _savedReels = savedReels;
          _isLoadingReels = false;
        });
      }
    } catch (e) {
      debugPrint('⚠️ Error loading saved reels: $e');
      if (mounted) {
        setState(() {
          _isLoadingReels = false;
        });
      }
    }
  }

  Future<void> _refreshAll() async {
    if (!mounted || _isRefreshing) return;

    _isRefreshing = true;
    try {
      await Future.wait([
        _loadSavedProjects(),
        _loadSavedReels(),
      ]);
    } finally {
      if (mounted) {
        _isRefreshing = false;
      }
    }
  }

  Future<void> _removeFromSaved(ProjectModel project) async {
    if (!mounted) return;

    final isAuth = await AuthHelper.requireAuth(context);
    if (!isAuth || !mounted) return;

    // Optimistic update
    if (mounted) {
      setState(() {
        _savedProjects.removeWhere((p) => p.id == project.id);
      });
    }

    try {
      await _projectApi.unsaveProject(project.id);
      if (mounted) {
        _showSnackBar('Removed from saved');
      }
    } catch (e) {
      debugPrint('⚠️ Error removing project: $e');
      // Revert on error
      if (mounted) {
        _loadSavedProjects();
        _showSnackBar('Error removing project', isError: true);
      }
    }
  }

  Future<void> _removeFromSavedReel(ClipModel reel) async {
    if (!mounted) return;

    final isAuth = await AuthHelper.requireAuth(context);
    if (!isAuth || !mounted) return;

    // Optimistic update
    if (mounted) {
      setState(() {
        _savedReels.removeWhere((r) => r.id == reel.id);
      });
    }

    try {
      await _clipService.unsaveReel(reel.id);
      if (mounted) {
        _showSnackBar('Removed from saved');
      }
    } catch (e) {
      debugPrint('⚠️ Error removing reel: $e');
      // Revert on error
      if (mounted) {
        _loadSavedReels();
        _showSnackBar('Error removing reel', isError: true);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    AppToast.show(
      context,
      message: message,
      isSuccess: !isError,
      icon: isError ? Icons.error_outline_rounded : Icons.check_circle_rounded,
      iconColor: isError ? const Color(0xFFFF5252) : const Color(0xFF00C853),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _buildAppBar(context),
            // Tabs
            _buildTabs(),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Projects Tab
                  _isLoadingProjects
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE50914),
                            strokeWidth: 2.5,
                          ),
                        )
                      : _savedProjects.isEmpty
                          ? _buildEmptyState(
                              'No Saved Projects',
                              'Projects you save will appear here for easy access',
                              Icons.bookmark_outline_rounded,
                            )
                          : _buildSavedProjectsList(),
                  // Reels Tab
                  _isLoadingReels
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFE50914),
                            strokeWidth: 2.5,
                          ),
                        )
                      : _savedReels.isEmpty
                          ? _buildEmptyState(
                              'No Saved Reels',
                              'Reels you save will appear here for easy access',
                              Icons.movie_creation_outlined,
                            )
                          : _buildSavedReelsList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final totalCount = _savedProjects.length + _savedReels.length;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.04),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Circular frosted back button
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFF181820),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Saved',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                if (!_isLoadingProjects && !_isLoadingReels) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$totalCount ${totalCount == 1 ? 'item' : 'items'}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Balanced right placeholder
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.06),
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorColor: const Color(0xFFE50914),
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
        labelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Projects'),
                if (!_isLoadingProjects && _savedProjects.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE50914).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_savedProjects.length}',
                      style: const TextStyle(
                        color: Color(0xFFE50914),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Reels'),
                if (!_isLoadingReels && _savedReels.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE50914).withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFE50914).withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${_savedReels.length}',
                      style: const TextStyle(
                        color: Color(0xFFE50914),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String message, IconData icon) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      color: const Color(0xFFE50914),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFFE50914).withValues(alpha: 0.18),
                          const Color(0xFF14141A),
                        ],
                      ),
                      border: Border.all(
                        color: const Color(0xFFE50914).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE50914).withValues(alpha: 0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: const Color(0xFFE50914),
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSavedProjectsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedProjects,
      color: const Color(0xFFE50914),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: _savedProjects.length,
        itemBuilder: (context, index) {
          final project = _savedProjects[index];
          return _SavedProjectItem(
            project: project,
            onTap: () async {
              final isAuth = await AuthHelper.requireAuth(context);
              if (!isAuth) return;

              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailsScreen(
                    projectId: project.id,
                  ),
                ),
              ).then((changed) {
                if (mounted && changed == true) {
                  _refreshAll();
                }
              });
            },
            onRemove: () => _removeFromSaved(project),
          );
        },
      ),
    );
  }

  Widget _buildSavedReelsList() {
    return RefreshIndicator(
      onRefresh: _loadSavedReels,
      color: const Color(0xFFE50914),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 0.72,
        ),
        itemCount: _savedReels.length,
        itemBuilder: (context, index) {
          final reel = _savedReels[index];
          return _SavedReelItem(
            reel: reel,
            onTap: () async {
              final isAuth = await AuthHelper.requireAuth(context);
              if (!isAuth) return;

              debugPrint(
                  '🎬 [SavedScreen] Opening reel: id="${reel.id}", title="${reel.title}", videoUrl="${reel.videoUrl}"');

              if (reel.id.isEmpty) {
                debugPrint('⚠️ [SavedScreen] Cannot open reel with empty id');
                return;
              }

              // Fetch full reel detail on demand via GET /reels/:id.
              // If reel.videoUrl is empty, forceRefresh: true guarantees GET /reels/:id is sent over the network.
              ClipModel fullReel = reel;
              try {
                final fetched = await _clipService.getClipById(
                  reel.id,
                  forceRefresh: reel.videoUrl.isEmpty,
                );
                if (fetched != null) {
                  fullReel = fetched;
                }
              } catch (e) {
                debugPrint('⚠️ [SavedScreen] Error fetching full reel: $e');
              }

              if (!context.mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReelsScreen(
                    clips: [fullReel], // pass only the resolved reel(s) actually needed
                    initialIndex: 0,
                    initialVisible: true,
                    isSavedOnlyContext: true,
                    initialSavedIds: _savedReels.map((r) => r.id).toSet(),
                  ),
                ),
              ).then((changed) {
                if (mounted && changed == true) {
                  _refreshAll();
                }
              });
            },
            onRemove: () => _removeFromSavedReel(reel),
          );
        },
      ),
    );
  }
}

class _SavedProjectItem extends StatelessWidget {
  static const Color brandRed = Color(0xFFE50914);

  final ProjectModel project;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _SavedProjectItem({
    required this.project,
    this.onTap,
    this.onRemove,
  });

  List<Color> _parseGradientColors() {
    try {
      if (project.gradientColors.isNotEmpty) {
        return project.gradientColors.map((colorStr) {
          final hexColor = colorStr.replaceAll('0x', '').replaceAll('#', '');
          return Color(int.parse(hexColor, radix: 16));
        }).toList();
      }
    } catch (_) {}
    return const [Color(0xFF252532), Color(0xFF161620)];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _parseGradientColors();
    final developerOrArea = project.developerName.isNotEmpty
        ? project.developerName
        : project.area;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF14141A),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          splashColor: brandRed.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Luxury Thumbnail
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildThumbnail(),
                        // Subtle gradient overlay
                        DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.35),
                              ],
                            ),
                          ),
                        ),
                        // Inner border overlay
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),

                // Info Section
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (developerOrArea.isNotEmpty) ...[
                        Row(
                          children: [
                            const Icon(
                              Icons.business_rounded,
                              size: 11,
                              color: brandRed,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                developerOrArea.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: brandRed,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                      ],
                      Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (project.location.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 12,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                project.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 9),
                      // Modern Watch pill button
                      GestureDetector(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 6.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF272733), Color(0xFF1E1E28)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: brandRed,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 11,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Watch',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Remove / Heart Glowing Button
                GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: brandRed.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: brandRed.withValues(alpha: 0.45),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: brandRed.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: brandRed,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    final imagePath = project.projectThumbnailUrl.isNotEmpty
        ? project.projectThumbnailUrl
        : project.image;

    if (imagePath.isEmpty) {
      return _buildPlaceholder();
    }

    if (project.isAsset) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return Image.network(
      imagePath,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Icon(
        Icons.apartment_rounded,
        color: Colors.white.withValues(alpha: 0.4),
        size: 32,
      ),
    );
  }
}

class _SavedReelItem extends StatelessWidget {
  static const Color brandRed = Color(0xFFE50914);

  final ClipModel reel;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const _SavedReelItem({
    required this.reel,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF14141A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              splashColor: brandRed.withValues(alpha: 0.1),
              highlightColor: Colors.white.withValues(alpha: 0.04),
              child: Stack(
                fit: StackFit.expand,
                children: [
                // Thumbnail
                _buildThumbnail(),

                // Deep gradient overlay for cinematic depth & readability
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.9),
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                ),

                // Top Badges
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                        width: 0.8,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.play_circle_fill_rounded,
                          color: brandRed,
                          size: 11,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'REEL',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Top Right Remove / Heart Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onRemove,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: brandRed.withValues(alpha: 0.55),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: brandRed.withValues(alpha: 0.25),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: brandRed,
                        size: 16,
                      ),
                    ),
                  ),
                ),

                // Center Play Icon
                Center(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),

                // Bottom Title & Project Name
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (reel.projectName.isNotEmpty) ...[
                          Text(
                            reel.projectName.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: brandRed,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.4,
                            ),
                          ),
                          const SizedBox(height: 2),
                        ],
                        Text(
                          reel.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

  Widget _buildThumbnail() {
    if (reel.thumbnail.isEmpty) {
      return _buildPlaceholder();
    }

    if (reel.isAsset || reel.thumbnail.startsWith('assets/')) {
      return Image.asset(
        reel.thumbnail,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildPlaceholder(),
      );
    }

    return Image.network(
      reel.thumbnail,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _buildPlaceholder(),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFF1E1E26),
      child: Center(
        child: Icon(
          Icons.video_library_outlined,
          color: Colors.white.withValues(alpha: 0.3),
          size: 36,
        ),
      ),
    );
  }
}
