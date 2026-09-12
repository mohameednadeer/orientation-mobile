import 'package:share_plus/share_plus.dart';

class ShareHelper {
  /// Shares ONLY the website project URL: https://orientationapps.com/project/:id
  static void shareProject({
    required String projectId,
    String? title,
  }) {
    final url = 'https://orientationapps.com/project/$projectId';
    Share.share(
      url,
      subject: title ?? 'Orientation Project',
    );
  }

  /// Shares ONLY the website reel URL: https://orientationapps.com/reels/:id
  static void shareReel({
    required String reelId,
    String? title,
  }) {
    final url = 'https://orientationapps.com/reels/$reelId';
    Share.share(
      url,
      subject: title ?? 'Orientation Reel',
    );
  }
}
