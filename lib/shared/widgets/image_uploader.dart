import 'package:flutter/material.dart';
import 'package:loadme_mobile/core/theme/theme_extensions.dart';

// Mirrors web `ImageUploader`: grid of square tiles with add button on the
// trailing slot. Backend wiring is left as a TODO — for now stores local URI
// strings (after the host plugs in image_picker).
class ImageUploader extends StatelessWidget {
  const ImageUploader({
    super.key,
    required this.urls,
    required this.onAdd,
    required this.onRemove,
    this.maxCount = 5,
    this.tileSize = 76,
  });

  final List<String> urls;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  final int maxCount;
  final double tileSize;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final t = context.types;
    final canAdd = urls.length < maxCount;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (var i = 0; i < urls.length; i++)
          _ImageTile(
            url: urls[i],
            size: tileSize,
            onRemove: () => onRemove(i),
          ),
        if (canAdd)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: tileSize,
              height: tileSize,
              decoration: BoxDecoration(
                color: c.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: c.border, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, color: c.primary, size: 22),
                  const SizedBox(height: 4),
                  Text('${urls.length}/$maxCount', style: t.overline.copyWith(color: c.textSecondary)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ImageTile extends StatelessWidget {
  const _ImageTile({required this.url, required this.size, required this.onRemove});
  final String url;
  final double size;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
              image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            ),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: c.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.surface, width: 1.5),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
