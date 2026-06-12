import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Renders a Figma-exported icon from `assets/icons/<name>.svg`.
///
/// Pass [color] to tint a monochrome icon; pass null to keep the SVG's own
/// colours (e.g. the gradient verified badge).
Widget appSvgIcon(String name, {double size = 16, Color? color}) {
  return SvgPicture.asset(
    'assets/icons/$name.svg',
    width: size,
    height: size,
    colorFilter:
        color == null ? null : ColorFilter.mode(color, BlendMode.srcIn),
  );
}
