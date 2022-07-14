// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:dough/dough.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Reorderable [item] placed in a [DraggableDough].
class ReorderableDraggableHandle<T extends Object> extends StatelessWidget {
  const ReorderableDraggableHandle({
    Key? key,
    required this.item,
    required this.sharedKey,
    required this.itemBuilder,
    this.onDragEnd,
    this.onDragStarted,
    this.onDragCompleted,
    this.onDraggableCanceled,
    this.onDoughBreak,
    this.useLongPress = false,
    this.enabled = true,
  }) : super(key: key);

  /// Item stored in this [ReorderableDraggableHandle].
  final T item;

  /// [UniqueKey] of this [ReorderableDraggableHandle].
  final UniqueKey sharedKey;

  /// Builder, building the [item].
  final Widget Function(T) itemBuilder;

  /// Callback, called when [item] dragging is started.
  final VoidCallback? onDragStarted;

  /// Callback, called when [item] dragging is ended.
  final Function(Offset)? onDragEnd;

  /// Callback, called when the dragged [item] is accepted by some [DragTarget].
  final VoidCallback? onDragCompleted;

  /// Callback, called when [item] dragging is canceled.
  final Function(Offset)? onDraggableCanceled;

  /// Callback, called when [item] breaks its dough.
  final VoidCallback? onDoughBreak;

  /// Indicator whether a [LongPressDraggable] should be used instead of a
  /// [Draggable].
  final bool useLongPress;

  /// Indicator whether dragging is allowed.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DoughRecipe(
      data: DoughRecipeData(
        adhesion: 4,
        viscosity: 2000,
        draggablePrefs: DraggableDoughPrefs(
          breakDistance: 50,
          useHapticsOnBreak: true,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          var widget = itemBuilder(item);
          return DraggableDough<T>(
            data: item,
            longPress: useLongPress,
            maxSimultaneousDrags: enabled ? 1 : 0,
            onDragEnd: (d) => onDragEnd?.call(d.offset),
            onDragStarted: onDragStarted,
            onDragCompleted: onDragCompleted,
            onDraggableCanceled: (_, d) => onDraggableCanceled?.call(d),
            onDoughBreak: () {
              if (enabled) {
                onDoughBreak?.call();
              }
            },
            feedback: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: KeyedSubtree(
                key: sharedKey,
                child: widget,
              ),
            ),
            childWhenDragging: KeyedSubtree(
              key: sharedKey,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.transparent,
              ),
            ),
            child: KeyedSubtree(
              key: sharedKey,
              child: widget,
            ),
          );
        },
      ),
    );
  }
}

/// Reorderable item data.
class ReorderableItem<T> {
  ReorderableItem(this.item);

  /// Reorderable item.
  final T item;

  /// [GlobalKey] of this [ReorderableItem].
  final GlobalKey key = GlobalKey();

  /// [UniqueKey] of this [ReorderableItem].
  final UniqueKey sharedKey = UniqueKey();

  /// Global key of [AnimatedTransitionState].
  final GlobalKey<AnimatedTransitionState> entryKey =
      GlobalKey<AnimatedTransitionState>();

  /// [OverlayEntry] of this [ReorderableItem].
  OverlayEntry? entry;

  /// [Rect] to return if dragging canceled.
  Rect? dragStartedRect;

  @override
  int get hashCode => item.hashCode;

  @override
  bool operator ==(Object other) =>
      other is ReorderableItem<T> && other.item == item;
}

/// Widget makes transition animation.
class AnimatedTransition extends StatefulWidget {
  const AnimatedTransition({
    Key? key,
    required this.beginRect,
    required this.endRect,
    required this.child,
    this.duration = const Duration(milliseconds: 200),
    this.onEnd,
    this.onDispose,
    this.curve,
  }) : super(key: key);

  /// Initial [Rect].
  final Rect beginRect;

  /// Target [Rect] to animate.
  final Rect endRect;

  /// [Duration] of animation.
  final Duration duration;

  /// Callback called when animation completed.
  final VoidCallback? onEnd;

  /// Child of this [AnimatedTransition].
  final Widget child;

  /// Callback called when this [AnimatedTransition] disposing.
  final VoidCallback? onDispose;

  /// [Curve] of this [AnimatedTransition].
  final Curve? curve;

  @override
  State<AnimatedTransition> createState() => AnimatedTransitionState();
}

/// State of [AnimatedTransition] used to change [rect] with animation.
class AnimatedTransitionState extends State<AnimatedTransition>
    with SingleTickerProviderStateMixin {
  /// [Rect] used to play animation.
  late Rect rect;

  @override
  void initState() {
    rect = widget.beginRect;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() => rect = widget.endRect);
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned.fromRect(
          rect: rect,
          duration: widget.duration,
          curve: widget.curve ?? Curves.linear,
          onEnd: widget.onEnd,
          child: widget.child,
        ),
      ],
    );
  }
}
