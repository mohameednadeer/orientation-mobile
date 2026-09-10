import 'package:flutter/material.dart';

/// Luxury, modern floating toast component for Orientation app
class AppToast {
  static const Color brandRed = Color(0xFFE50914);

  /// Shows a modern floating pill toast
  static void show(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    Duration duration = const Duration(milliseconds: 1800),
    bool isSuccess = true,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        padding: EdgeInsets.zero,
        content: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFF1B1B24),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: (iconColor ?? (isSuccess ? brandRed : Colors.white))
                    .withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: (iconColor ?? brandRed).withValues(alpha: 0.18),
                  blurRadius: 12,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: iconColor ?? (isSuccess ? brandRed : Colors.white70),
                    size: 19,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Specialized toast for Save / Bookmark actions
  static void showSave(BuildContext context, {required bool isSaved}) {
    show(
      context,
      message: isSaved ? 'Added to Saved Projects' : 'Removed from Saved',
      icon: isSaved ? Icons.bookmark_rounded : Icons.bookmark_remove_rounded,
      iconColor: isSaved ? brandRed : Colors.white60,
      isSuccess: isSaved,
    );
  }

  /// Specialized toast for generic success
  static void showSuccess(BuildContext context, String message, {IconData icon = Icons.check_circle_rounded}) {
    show(
      context,
      message: message,
      icon: icon,
      iconColor: const Color(0xFF00C853),
      isSuccess: true,
    );
  }

  /// Specialized toast for error messages
  static void showError(BuildContext context, String message) {
    show(
      context,
      message: message,
      icon: Icons.error_outline_rounded,
      iconColor: const Color(0xFFFF5252),
      isSuccess: false,
    );
  }
}
