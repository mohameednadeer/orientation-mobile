import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/project_card.dart';
import '../services/api/project_api.dart';
import '../services/api/home_api.dart';
import '../models/project_model.dart';
import '../models/episode_model.dart';
import 'episode_player_screen.dart';
import 'project_details_screen.dart';
import '../widgets/app_toast.dart';
import '../utils/share_helper.dart';

class ProjectsListScreen extends StatefulWidget {
  final String title;
  final int resultCount;
  final bool showSearch;
  final String? areaName; // New parameter for filtering

  const ProjectsListScreen({
    super.key,
    required this.title,
    this.resultCount = 24,
    this.showSearch = true,
    this.areaName,
  });

  @override
  State<ProjectsListScreen> createState() => _ProjectsListScreenState();
}

class _ProjectsListScreenState extends State<ProjectsListScreen> {
  static const Color brandRed = Color(0xFFE50914);
  final HomeApi _homeApi = HomeApi();
  final ProjectApi _projectApi = ProjectApi();
  bool _isLoading = true;
  List<ProjectModel> _projects = [];
  Map<String, bool> _savedProjects = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProjects() async {
    try {
      List<ProjectModel> projects;
      
      // Load projects based on title/section or specific area
      if (widget.areaName != null && widget.areaName!.isNotEmpty) {
        projects = await _homeApi.getProjectsByArea(widget.areaName!);
      } else if (widget.title.contains('Northcoast') || widget.title.contains('North Coast')) {
        projects = await _homeApi.getProjectsByArea('North Coast');
      } else if (widget.title.contains('New Cairo')) {
        projects = await _homeApi.getProjectsByArea('New Cairo');
      } else if (widget.title.contains('October')) {
        projects = await _homeApi.getProjectsByArea('October');
      } else if (widget.title.contains('Top 10')) {
        projects = await _homeApi.getTop10Projects();
      } else if (widget.title.contains('Upcoming')) {
        projects = await _homeApi.getUpcomingProjects();
      } else {
        // Default: latest projects
        projects = await _homeApi.getLatestProjects();
      }
      
      // Load saved status for all projects with a single SharedPreferences read
      final prefs = await SharedPreferences.getInstance();
      final savedIds = (prefs.getStringList('saved_projects') ?? []).toSet();
      final savedStatus = <String, bool>{};
      for (final project in projects) {
        savedStatus[project.id] = savedIds.contains(project.id);
      }

      if (mounted) {
        setState(() {
          _projects = projects;
          _savedProjects = savedStatus;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Error loading projects: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleWatch(ProjectModel project) async {
    try {
      // Get episodes for this project
      final episodes = await _projectApi.getEpisodes(project.id);
      
      if (episodes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No episodes available for this project'),
              backgroundColor: brandRed,
            ),
          );
        }
        return;
      }

      // Find the episode with the highest watch progress (last watched)
      EpisodeModel? episodeToPlay;
      double maxProgress = 0.0;

      for (final episode in episodes) {
        final progress = await _projectApi.getWatchingProgress(project.id, episode.id);
        if (progress > maxProgress) {
          maxProgress = progress;
          episodeToPlay = episode;
        }
      }

      // If no episode has progress, use first episode
      episodeToPlay ??= episodes.first;
      
      if (mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EpisodePlayerScreen(
              episode: episodeToPlay!,
              projectTitle: project.title,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: brandRed,
          ),
        );
      }
    }
  }

  Future<void> _handleBookmark(ProjectModel project) async {
    final isSaved = _savedProjects[project.id] ?? false;
    setState(() {
      _savedProjects[project.id] = !isSaved;
    });

    try {
      if (isSaved) {
        await _projectApi.unsaveProject(project.id);
        if (mounted) {
          AppToast.showSave(context, isSaved: false);
        }
      } else {
        await _projectApi.saveProject(project.id);
        if (mounted) {
          AppToast.showSave(context, isSaved: true);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _savedProjects[project.id] = isSaved;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: brandRed,
          ),
        );
      }
    }
  }

  Future<void> _handleShare(ProjectModel project) async {
    ShareHelper.shareProject(projectId: project.id, title: project.title);
  }

  @override
  Widget build(BuildContext context) {
    final filteredProjects = _searchQuery.isEmpty
        ? _projects
        : _projects.where((p) {
            final q = _searchQuery.toLowerCase();
            return p.title.toLowerCase().contains(q) ||
                p.developerName.toLowerCase().contains(q) ||
                p.location.toLowerCase().contains(q) ||
                p.area.toLowerCase().contains(q);
          }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0B0B0F),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.85, -0.9),
            radius: 1.2,
            colors: [
              Color(0x1CE50914), // subtle red ambient lighting from top-left
              Color(0xFF0B0B0F),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              _buildAppBar(context),
              // Search bar (optional)
              if (widget.showSearch) _buildSearchBar(),
              // Results header
              _buildResultsHeader(filteredProjects.length),
              // List
              Expanded(
                child: _buildProjectList(filteredProjects),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF181822),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.09),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          Expanded(
            child: Text(
              widget.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 42), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: const Color(0xFF15151D),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            const Icon(
              Icons.search_rounded,
              color: brandRed,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (val) {
                  setState(() {
                    _searchQuery = val.trim();
                  });
                },
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                cursorColor: brandRed,
                decoration: InputDecoration(
                  hintText: 'Search for a project....',
                  hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            if (_searchQuery.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white70,
                    size: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 3.5,
                height: 18,
                decoration: BoxDecoration(
                  color: brandRed,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: brandRed.withValues(alpha: 0.5),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Results',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: brandRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: brandRed.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: brandRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$count Orientation',
                  style: const TextStyle(
                    color: brandRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectList(List<ProjectModel> displayProjects) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: brandRed,
              strokeWidth: 2.5,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading projects...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (displayProjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF161620),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 1,
                  ),
                ),
                child: Icon(
                  _searchQuery.isNotEmpty
                      ? Icons.search_off_rounded
                      : Icons.movie_filter_outlined,
                  color: Colors.white.withValues(alpha: 0.4),
                  size: 34,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No matching projects found'
                    : 'No projects found',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _searchQuery.isNotEmpty
                    ? 'Try searching with a different keyword or area'
                    : 'Projects for this category will appear here',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4, bottom: 24),
      physics: const BouncingScrollPhysics(),
      itemCount: displayProjects.length,
      itemBuilder: (context, index) {
        final project = displayProjects[index];
        final gradientColors = project.gradientColors.map((c) {
          final hex = c.replaceAll('0x', '');
          return Color(int.parse(hex, radix: 16));
        }).toList();

        final isSaved = _savedProjects[project.id] ?? false;

        final isImageVideo = project.image.toLowerCase().contains('.mp4') ||
            project.image.toLowerCase().contains('.mov') ||
            project.image.toLowerCase().contains('.avi') ||
            project.image.toLowerCase().contains('video');

        final fallbackImage = (!isImageVideo && project.image.isNotEmpty)
            ? project.image
            : (project.logo != null && project.logo!.isNotEmpty)
                ? project.logo!
                : null;

        final imageUrl = (project.isAsset &&
                project.projectThumbnailUrl.startsWith('assets/'))
            ? null
            : (project.projectThumbnailUrl.isNotEmpty
                ? project.projectThumbnailUrl
                : fallbackImage);
        final imageAsset = (project.isAsset &&
                project.projectThumbnailUrl.startsWith('assets/'))
            ? (project.projectThumbnailUrl.isNotEmpty
                ? project.projectThumbnailUrl
                : (fallbackImage != null &&
                        fallbackImage.startsWith('assets/')
                    ? fallbackImage
                    : null))
            : null;

        return ProjectListItem(
          projectId: project.id,
          developerName: project.developerName,
          projectName: project.title,
          location:
              project.location.isNotEmpty ? project.location : project.area,
          gradientColors: gradientColors,
          isSaved: isSaved,
          imageUrl: imageUrl,
          imageAsset: imageAsset,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProjectDetailsScreen(
                  projectId: project.id,
                ),
              ),
            ).then((_) => _loadProjects()); // Refresh after returning
          },
          onWatch: () => _handleWatch(project),
          onBookmark: () => _handleBookmark(project),
          onShare: () => _handleShare(project),
        );
      },
    );
  }
}

