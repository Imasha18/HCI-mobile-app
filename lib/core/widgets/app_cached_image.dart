import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class AppCachedImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final double borderRadius;
  final IconData fallbackIcon;
  final Color? placeholderColor;
  final int memCacheWidth;
  final int memCacheHeight;

  const AppCachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
    this.fallbackIcon = Icons.restaurant_menu_rounded,
    this.placeholderColor,
    this.memCacheWidth = 400,
    this.memCacheHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim() ?? '';

    Widget imageWidget;
    if (url.isEmpty || !url.startsWith('http')) {
      imageWidget = _buildFallback();
    } else {
      imageWidget = CachedNetworkImage(
        imageUrl: url,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        memCacheHeight: memCacheHeight,
        placeholder: (context, url) => Container(
          width: width,
          height: height,
          color: placeholderColor ?? const Color(0xFFF3F4F6),
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFFF9800),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildFallback(),
      );
    }

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: imageWidget,
      );
    }

    return imageWidget;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: placeholderColor ?? const Color(0xFFFFF3E0),
      child: Center(
        child: Icon(
          fallbackIcon,
          size: (width != null && height != null)
              ? (width! < height! ? width! * 0.4 : height! * 0.4)
              : 28,
          color: const Color(0xFFFF9800),
        ),
      ),
    );
  }
}
