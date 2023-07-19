import 'package:flutter/material.dart';

import '/themes.dart';

class ExpandButton extends StatelessWidget {
  const ExpandButton({
    super.key,
    required this.isFullscreen,
    required this.height,
    required this.onTap,
  });

  final bool isFullscreen;

  final double? height;

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        // onTap: _onExpandCollapse,
        onTap: onTap,
        child: SizedBox(
          // height: _barHeight,
          height: height,
          child: Center(
            child: Icon(
              // widget.isFullscreen?.value == true
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
