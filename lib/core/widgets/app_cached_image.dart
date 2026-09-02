import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable high-performance cached network image widget with offline
/// caching, smooth fade-in animations, shimmer skeleton loader, and fallback icon.
class AppCachedImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final Color? backgroundColor;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.backgroundColor,
  });

  bool get _isValidUrl {
    final clean = imageUrl.trim();
    return clean.startsWith('http://') || clean.startsWith('https://');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fallbackBg = backgroundColor ??
        (isDark ? AppColors.surfaceDark : const Color(0xFFF1F5F9));

    Widget imageContent;

    if (!_isValidUrl) {
      imageContent = _buildPlaceholder(context, isDark, fallbackBg);
    } else {
      imageContent = CachedNetworkImage(
        imageUrl: imageUrl.trim(),
        width: width,
        height: height,
        fit: fit,
        fadeInDuration: Duration.zero,
        fadeOutDuration: Duration.zero,
        placeholder: (context, url) =>
            placeholder ?? _buildShimmer(context, isDark, fallbackBg),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildErrorFallback(context, isDark, fallbackBg),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageContent,
      );
    }

    return imageContent;
  }

  Widget _buildShimmer(BuildContext context, bool isDark, Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: (height != null && height! < 60) ? 18 : 24,
          color: isDark ? Colors.white24 : Colors.black12,
        ),
      ),
    );
  }

  Widget _buildErrorFallback(BuildContext context, bool isDark, Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: (height != null && height! < 60) ? 18 : 26,
            color: isDark ? Colors.white38 : Colors.black26,
          ),
          if (height == null || height! >= 90) ...[
            const SizedBox(height: 4),
            Text(
              'Cherish',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white30 : Colors.black26,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context, bool isDark, Color bgColor) {
    return Container(
      width: width,
      height: height,
      color: bgColor,
      child: Icon(
        Icons.child_care_rounded,
        size: (height != null && height! < 60) ? 20 : 32,
        color: isDark ? Colors.white24 : Colors.black12,
      ),
    );
  }
}
