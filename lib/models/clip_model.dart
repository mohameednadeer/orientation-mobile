class ClipModel {
  final String id;
  final String projectId;
  final String title;
  final String description;
  final String videoUrl;
  final String thumbnail;
  final bool isAsset;
  final String developerName;
  final String developerLogo;
  final String projectName;
  final String projectLogo;
  final int likes;
  final bool isLiked;
  final bool hasWhatsApp;
  final DateTime? createdAt;

  ClipModel({
    required this.id,
    required this.projectId,
    this.title = '',
    this.description = '',
    this.videoUrl = '',
    this.thumbnail = '',
    this.isAsset = false,
    this.developerName = '',
    this.developerLogo = '',
    this.projectName = '',
    this.projectLogo = '',
    this.likes = 0,
    this.isLiked = false,
    this.hasWhatsApp = true,
    this.createdAt,
  });

  factory ClipModel.fromJson(Map<String, dynamic> json) {
    String projectId = '';
    String projectName = '';
    String projectLogo = '';

    final rawProj = json['projectId'] ?? json['project'];
    if (rawProj != null) {
      if (rawProj is Map) {
        projectId = rawProj['_id']?.toString() ??
            rawProj['id']?.toString() ??
            '';
        projectName = rawProj['title']?.toString() ??
            rawProj['name']?.toString() ??
            rawProj['projectName']?.toString() ??
            '';
        projectLogo = rawProj['logo']?.toString() ??
            rawProj['logoUrl']?.toString() ??
            rawProj['projectThumbnailUrl']?.toString() ??
            rawProj['image']?.toString() ??
            '';
      } else {
        projectId = rawProj.toString();
      }
    }

    // Top-level fallbacks if provided in json directly
    if (projectName.isEmpty) {
      projectName = json['projectName']?.toString() ??
          json['projectTitle']?.toString() ??
          '';
    }
    if (projectLogo.isEmpty) {
      projectLogo = json['projectLogo']?.toString() ??
          json['projectLogoUrl']?.toString() ??
          json['logo']?.toString() ??
          json['logoUrl']?.toString() ??
          '';
    }

    // developerName/developerLogo from populated developerId or developer object
    String developerName = json['developerName']?.toString() ?? '';
    String developerLogo = json['developerLogo']?.toString() ?? '';
    final dev = json['developerId'] ?? json['developer'];
    if (dev is Map) {
      if (developerName.isEmpty) developerName = dev['name']?.toString() ?? '';
      if (developerLogo.isEmpty) {
        developerLogo =
            dev['logoUrl']?.toString() ?? dev['logo']?.toString() ?? '';
      }
    }

    // Fallbacks between project and developer if one is missing
    if (projectName.isEmpty && developerName.isNotEmpty) {
      projectName = developerName;
    }
    if (projectLogo.isEmpty && developerLogo.isNotEmpty) {
      projectLogo = developerLogo;
    }

    final videoUrl = json['videoUrl']?.toString() ??
        json['url']?.toString() ??
        json['video']?.toString() ??
        json['reelUrl']?.toString() ??
        json['video_url']?.toString() ??
        '';

    final thumbnail = json['thumbnail']?.toString() ??
        json['thumbnailUrl']?.toString() ??
        json['reelThumbnailUrl']?.toString() ??
        json['coverUrl']?.toString() ??
        json['poster']?.toString() ??
        '';

    int likes = 0;
    if (json['likes'] != null) {
      likes = int.tryParse(json['likes'].toString()) ?? 0;
    } else if (json['viewCount'] != null) {
      likes = int.tryParse(json['viewCount'].toString()) ?? 0;
    } else if (json['saveCount'] != null) {
      likes = int.tryParse(json['saveCount'].toString()) ?? 0;
    }

    final description = json['description']?.toString() ??
        json['caption']?.toString() ??
        '';

    return ClipModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      projectId: projectId,
      title: json['title']?.toString() ?? '',
      description: description,
      videoUrl: videoUrl,
      thumbnail: thumbnail,
      isAsset: json['isAsset'] == true,
      developerName: developerName.isNotEmpty ? developerName : 'User',
      developerLogo: developerLogo,
      projectName: projectName,
      projectLogo: projectLogo,
      likes: likes,
      isLiked: json['isLiked'] == true,
      hasWhatsApp: json['hasWhatsApp'] != false, // defaults to true unless explicitly false
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'thumbnail': thumbnail,
      'isAsset': isAsset,
      'developerName': developerName,
      'developerLogo': developerLogo,
      'projectName': projectName,
      'projectLogo': projectLogo,
      'likes': likes,
      'isLiked': isLiked,
      'hasWhatsApp': hasWhatsApp,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  ClipModel copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? videoUrl,
    String? thumbnail,
    bool? isAsset,
    String? developerName,
    String? developerLogo,
    String? projectName,
    String? projectLogo,
    int? likes,
    bool? isLiked,
    bool? hasWhatsApp,
    DateTime? createdAt,
  }) {
    return ClipModel(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoUrl: videoUrl ?? this.videoUrl,
      thumbnail: thumbnail ?? this.thumbnail,
      isAsset: isAsset ?? this.isAsset,
      developerName: developerName ?? this.developerName,
      developerLogo: developerLogo ?? this.developerLogo,
      projectName: projectName ?? this.projectName,
      projectLogo: projectLogo ?? this.projectLogo,
      likes: likes ?? this.likes,
      isLiked: isLiked ?? this.isLiked,
      hasWhatsApp: hasWhatsApp ?? this.hasWhatsApp,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
