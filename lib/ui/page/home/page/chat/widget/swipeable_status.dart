// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';

import '/themes.dart';

/// Swipeable widget allowing its [child] to be swiped to reveal [swipeable]
/// with a status next to it.
class SwipeableStatus extends StatelessWidget {
  const SwipeableStatus({
    Key? key,
    required this.child,
    required this.swipeable,
    this.animation,
    this.asStack = false,
    this.isSent = false,
    this.isDelivered = false,
    this.isRead = false,
    this.isSending = false,
    this.isError = false,
    this.crossAxisAlignment = CrossAxisAlignment.end,
    this.padding = const EdgeInsets.only(bottom: 13),
  }) : super(key: key);

  /// Expanded width of the [swipeable].
  static const double width = 65;

  /// Child to swipe to reveal [swipeable].
  final Widget child;

  /// Widget to display upon swipe.
  final Widget swipeable;

  /// [AnimationController] controlling this widget.
  final AnimationController? animation;

  /// Indicator whether [swipeable] should be put in a [Stack] instead of a
  /// [Row].
  final bool asStack;

  /// Indicator whether status is sent.
  final bool isSent;

  /// Indicator whether status is delivered.
  final bool isDelivered;

  /// Indicator whether status is read.
  final bool isRead;

  /// Indicator whether status is sending.
  final bool isSending;

  /// Indicator whether status is error.
  final bool isError;

  /// Position of a [swipeable] relatively to the [child].
  final CrossAxisAlignment crossAxisAlignment;

  /// Padding of a [swipeable].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (animation == null) {
      return child;
    }

    if (asStack) {
      return Stack(
        alignment: crossAxisAlignment == CrossAxisAlignment.end
            ? Alignment.bottomRight
            : Alignment.centerRight,
        children: [
          child,
          _animatedBuilder(
            Padding(
              padding: padding,
              child:
                  SizedBox(width: width, child: _swipeableWithStatus(context)),
            ),
          ),
        ],
      );
    }

    return _animatedBuilder(
      Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Expanded(child: child),
          Padding(
            padding: padding,
            child: SizedBox(width: width, child: _swipeableWithStatus(context)),
          ),
        ],
      ),
    );
  }

  /// Returns a [Row] of [swipeable] and a status.
  Widget _swipeableWithStatus(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return DefaultTextStyle.merge(
      textAlign: TextAlign.end,
      maxLines: 1,
      overflow: TextOverflow.visible,
      style: style.systemMessageStyle.copyWith(fontSize: 11),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3),
        margin: const EdgeInsets.only(right: 2, left: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: style.systemMessageBorder,
          color: style.systemMessageColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSent || isDelivered || isRead || isSending || isError)
              Icon(
                (isRead || isDelivered)
                    ? Icons.done_all
                    : isSending
                        ? Icons.access_alarm
                        : isError
                            ? Icons.error_outline
                            : Icons.done,
                color: isRead
                    ? Theme.of(context).colorScheme.secondary
                    : isError
                        ? Colors.red
                        : Theme.of(context).colorScheme.primary,
                size: 12,
              ),
            const SizedBox(width: 3),
            swipeable,
          ],
        ),
      ),
    );
  }

  /// Returns an [AnimatedBuilder] with a [Transform.translate] transition.
  Widget _animatedBuilder(Widget child) => AnimatedBuilder(
        animation: animation!,
        builder: (context, child) {
          return Transform.translate(
            offset: Tween(
              begin: const Offset(width, 0),
              end: Offset.zero,
            ).evaluate(animation!),
            child: child,
          );
        },
        child: child,
      );
}
