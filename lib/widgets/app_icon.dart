import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Nova Line icons by Streamline, bundled for offline use. See assets/README.md.
class AppIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const AppIcon(this.name, {super.key, this.size = 24, this.color});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ??
            IconTheme.of(context).color ??
            Theme.of(context).colorScheme.onSurface,
        BlendMode.srcIn,
      ),
    ),
  );
}
