import 'package:flutter/material.dart';

import '/themes.dart';

/// Widget which returns an [InkWell] circular button with an [child].
class CircularInkWell extends StatelessWidget {
  const CircularInkWell({super.key, this.child, this.onTap});

  /// [Widget] to display.
  final Widget? child;

  /// Callback, called when this [CircularInkWell] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Material(
      type: MaterialType.circle,
      color: style.colors.onPrimary,
      shadowColor: style.colors.onBackgroundOpacity27,
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          width: 42,
          height: 42,
          child: Center(child: child),
        ),
      ),
    );
  }
}
