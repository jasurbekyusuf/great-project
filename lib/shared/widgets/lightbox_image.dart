import 'package:flutter/material.dart';

// Mirrors web `LightboxImage`: tap to open full-screen, pinch/zoom, swipe down
// to dismiss. Pure Flutter using InteractiveViewer + Hero.
class LightboxImage extends StatelessWidget {
  const LightboxImage({
    super.key,
    required this.imageUrl,
    this.heroTag,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderColor,
  });

  final String imageUrl;
  final Object? heroTag;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final Color? placeholderColor;

  @override
  Widget build(BuildContext context) {
    final tag = heroTag ?? imageUrl;
    final child = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: placeholderColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
      loadingBuilder: (ctx, w, p) => p == null
          ? w
          : Container(
              width: width,
              height: height,
              color: placeholderColor ?? Theme.of(context).colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
    );

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (_, __, ___) => _LightboxPage(imageUrl: imageUrl, heroTag: tag),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          ),
        );
      },
      child: Hero(
        tag: tag,
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: child,
        ),
      ),
    );
  }
}

class _LightboxPage extends StatelessWidget {
  const _LightboxPage({required this.imageUrl, required this.heroTag});
  final String imageUrl;
  final Object heroTag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Hero(
                  tag: heroTag,
                  child: Image.network(imageUrl, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
