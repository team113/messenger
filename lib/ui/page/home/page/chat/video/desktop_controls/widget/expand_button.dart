import 'package:flutter/material.dart';

import '/themes.dart';

class ExpandButton extends StatelessWidget {
  const ExpandButton({
    super.key,
    required this.height,
    required this.isFullscreen,
    required this.onTap,
  });

  final double? height;

  final bool isFullscreen;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          height: height,
          child: Center(
            child: Icon(
              isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: style.colors.onPrimary,
              size: 21,
            ),
          ),
        ),
      ),
    );
  }
}
