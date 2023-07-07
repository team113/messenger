import 'package:flutter/material.dart';

import '/l10n/l10n.dart';
import '/themes.dart';

/// Rounded [Container] indicating the rewinding for the provided [seconds]
/// forward or backward.
class RewindIndicator extends StatelessWidget {
  const RewindIndicator({
    super.key,
    this.seconds = 1,
    this.opacity = 1,
    this.forward = true,
  });

  /// Seconds of rewind to display.
  final int seconds;

  /// Opacity of this [RewindIndicator].
  final double opacity;

  /// Indicator whether this [RewindIndicator] should display a forward rewind,
  /// or backward otherwise.
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: style.colors.onBackgroundOpacity27,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                forward ? Icons.fast_forward : Icons.fast_rewind,
                color: style.colors.onPrimary,
              ),
              Text(
                'label_count_seconds'.l10nfmt({'count': seconds}),
                style:
                    fonts.bodyMedium?.copyWith(color: style.colors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
