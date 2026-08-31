import '../core/api_client.dart';
import '../models/episode_model.dart';

class ProjectSummary {
  final String id;
  final String title;
  final String slug;
  final String? location;
  final String? thumbnailUrl;

  ProjectSummary({
    required this.id,
    required this.title,
    required this.slug,
    this.location,
    this.thumbnailUrl,
  });

  factory ProjectSummary.fromJson(Map<String, dynamic> json) {
    return ProjectSummary(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      location: json['location'],
      thumbnailUrl: json['projectThumbnailUrl'],
    );
  }
}

class EpisodeItem {
  final String id;
  final String title;
  final String? videoUrl;
  final String? duration;
  final bool isLocked;
  final int episodeNumber;
  final String? thumbnail;
  final bool isAsset;

  EpisodeItem({
    required this.id,
    required this.title,
    this.videoUrl,
    this.duration,
    required this.isLocked,
    required this.episodeNumber,
    this.thumbnail,
    required this.isAsset,
  });

  factory EpisodeItem.fromJson(Map<String, dynamic> json) {
    int epNum = json['episodeNumber'] ?? 1;
    if (json['episodeOrder'] != null) {
      final orderStr = json['episodeOrder'].toString();
      final orderMatch = RegExp(r'\d+').firstMatch(orderStr);
      if (orderMatch != null) {
        epNum = int.tryParse(orderMatch.group(0) ?? '1') ?? 1;
      }
    }
    return EpisodeItem(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      videoUrl: json['episodeUrl'] ?? json['videoUrl'],
      duration: json['duration'],
      isLocked: json['isLocked'] ?? true, // Default to locked
      episodeNumber: epNum,
      thumbnail: json['thumbnail'] ?? json['thumbnailUrl'],
      isAsset: json['isAsset'] ?? false,
    );
  }

  EpisodeModel toEpisodeModel(String projectId) {
    return EpisodeModel(
      id: id,
      projectId: projectId,
      title: title,
      episodeNumber: episodeNumber,
      thumbnail: thumbnail ?? '',
      isAsset: isAsset,
      videoUrl: videoUrl ?? '',
      duration: duration ?? '',
    );
  }
}

class ProjectDetails {
  final String id;
  final String title;
  final String slug;
  final String? location;
  final String? description;
  final String? projectThumbnailUrl;
  final bool hasAccess;
  final List<EpisodeItem> episodes;

  ProjectDetails({
    required this.id,
    required this.title,
    required this.slug,
    this.location,
    this.description,
    this.projectThumbnailUrl,
    required this.hasAccess,
    required this.episodes,
  });

  factory ProjectDetails.fromJson(Map<String, dynamic> json) {
    final episodesList = json['episodes'] as List? ?? [];
    return ProjectDetails(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      slug: json['slug'] ?? '',
      location: json['location'],
      description: json['description'],
      projectThumbnailUrl: json['projectThumbnailUrl'],
      hasAccess: json['hasAccess'] ?? false,
      episodes: episodesList.map((e) => EpisodeItem.fromJson(e)).toList(),
    );
  }
}

class ProjectService {
  static Future<List<ProjectSummary>> getFreeProjects({int page = 1, int limit = 10}) async {
    try {
      final response = await ApiClient.dio.get(
        '/projects/free',
        queryParameters: {'page': page, 'limit': limit},
      );

      final List data = response.data;
      return data.map((json) => ProjectSummary.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching free projects: $e');
      rethrow;
    }
  }

  static Future<ProjectDetails> getProjectDetails(String projectId) async {
    try {
      final response = await ApiClient.dio.get('/projects/$projectId');
      return ProjectDetails.fromJson(response.data);
    } catch (e) {
      print('Error fetching project details: $e');
      rethrow;
    }
  }
}
