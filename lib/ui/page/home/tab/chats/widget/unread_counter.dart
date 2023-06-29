import 'package:flutter/material.dart';

import '/l10n/l10n.dart';
import '/themes.dart';

/// Circle representation of the provided [count] being unread.
class UnreadCounter extends StatelessWidget {
  const UnreadCounter(
    this.count, {
    super.key,
    this.dimmed = false,
    this.inverted = false,
  });

  /// Count to display in this [UnreadCounter].
  final int count;

  /// Indicator whether this [UnreadCounter] should be dimmed, or bright
  /// otherwise.
  final bool dimmed;

  /// Indicator whether this [UnreadCounter] should have its colors
  /// inverted.
  final bool inverted;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Container(
      width: 23,
      height: 23,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: dimmed
            ? inverted
                ? style.colors.onPrimary
                : style.colors.secondaryHighlightDarkest
            : style.colors.dangerColor,
      ),
      alignment: Alignment.center,
      child: Text(
        count > 99 ? '99${'plus'.l10n}' : '$count',
        style: fonts.displaySmall!.copyWith(
          color: dimmed
              ? inverted
                  ? style.colors.secondary
                  : style.colors.onPrimary
              : style.colors.onPrimary,
        ),
        maxLines: 1,
        overflow: TextOverflow.clip,
        textAlign: TextAlign.center,
      ),
    );
  }
}
