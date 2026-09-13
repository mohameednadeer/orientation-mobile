import 'episode_model.dart';

class SalesVideoModel {
  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String videoUrl;
  final bool isLocked;

  SalesVideoModel({
    required this.id,
    required this.title,
    this.description = '',
    this.thumbnailUrl = '',
    this.videoUrl = '',
    this.isLocked = false,
  });

  factory SalesVideoModel.fromJson(Map<String, dynamic> json) {
    return SalesVideoModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      thumbnailUrl: json['thumbnailURL']?.toString() ??
          json['thumbnailUrl']?.toString() ??
          json['thumbnail']?.toString() ??
          '',
      videoUrl: json['salesVideoURL']?.toString() ??
          json['salesVideoUrl']?.toString() ??
          json['videoUrl']?.toString() ??
          json['url']?.toString() ??
          '',
      isLocked: json['locked'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'thumbnailURL': thumbnailUrl,
      'salesVideoURL': videoUrl,
      'locked': isLocked,
    };
  }

  EpisodeModel toEpisodeModel(String projectId, {int order = 1}) {
    return EpisodeModel(
      id: id,
      projectId: projectId,
      title: title,
      episodeNumber: order,
      thumbnail: thumbnailUrl,
      isAsset: false,
      videoUrl: videoUrl,
      description: description,
    );
  }
}
