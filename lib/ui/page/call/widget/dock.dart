// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/ui/page/home/widget/gallery_popup.dart';
import 'animated_delayed_width.dart';
import 'animated_transition.dart';

/// Reorderable [Row] of provided [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.onReorder,
    this.itemWidth = 48,
    this.delayed = true,
    this.onDragStarted,
    this.onDragEnded,
    this.onLeave,
    this.onWillAccept,
  });

  /// Items this [Dock] reorders.
  final List<T> items;

  /// Builder building the provided item.
  final Widget Function(T item) itemBuilder;

  /// Max width [itemBuilder] is allowed to build within.
  final double itemWidth;

  /// Indicator whether [Draggable] used over [items] should be delay activated.
  final bool delayed;

  /// Callback, called when the [items] are reordered.
  final Function(List<T>)? onReorder;

  /// Callback, called when an item dragging is started.
  final Function(T)? onDragStarted;

  /// Callback, called when an item dragging is ended.
  final Function(T)? onDragEnded;

  /// Callback, called when the dragged item leaves this [Dock].
  final Function(T?)? onLeave;

  /// Callback, called when this [Dock] may accept the dragged item.
  final bool Function(T?)? onWillAccept;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of a [Dock] maintaining a reorderable [_items] list.
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [Duration] of [_DraggedItem] jumping from one position to another.
  static const Duration jumpDuration = Duration(milliseconds: 300);

  /// [Duration] of [AnimatedContainer]s representing the animations of
  /// [_DraggedItem]s being added and removed.
  static const Duration animateDuration = Duration(milliseconds: 150);

  /// [_DraggedItem]s of this [Dock].
  List<_DraggedItem<T>> _items = [];

  /// [GlobalKey]s of the expanding [AnimatedContainer]s.
  List<GlobalKey> _expandedKeys = [];

  /// Current [Duration] of the [AnimatedContainer]s.
  Duration _animateDuration = animateDuration;

  /// Position in [_items] to add expanding [AnimatedContainer] to.
  ///
  /// Represents a place to add the dragged item to.
  int __expanded = -1;

  /// Indicator whether the [_expanded] has been changed during the current
  /// frame.
  bool _expandedChanged = false;

  /// Position in [_items] to add shrinking [AnimatedContainer] to.
  int _compressed = -1;

  /// [MapEntry] of the currently moved [_DraggedItem] along with its index.
  MapEntry<int, _DraggedItem<T>>? _dragged;

  /// [GlobalKey] of the [DragTarget] this [Dock] contains.
  final GlobalKey _dockKey = GlobalKey();

  /// [RenderObject.paintBounds] of the [_dragged] item.
  Rect? _rect;

  /// [OverlayEntry] of the [_DraggedItem] being animated right now.
  OverlayEntry? _entry;

  /// Returns the width single [_DraggedItem] occupies.
  double get _size => _items.isEmpty ||
          _items.first.key.currentState == null ||
          _items.first.key.currentState?.mounted == false ||
          _items.first.key.currentContext?.size == null
      ? widget.itemWidth
      : _items.first.key.currentContext!.size!.width;

  /// Returns a position in [_items] to add expanding [AnimatedContainer] to.
  int get _expanded => __expanded;

  /// Sets the [_expanded] position to the provided [index].
  ///
  /// Accounts possible double invokes during a single frame by scheduling the
  /// change in the next frame on such occasions.
  set _expanded(int index) {
    if (_expanded != index && mounted) {
      // If [__expanded] has been changed during this frame, then schedule this
      // change for a next frame.
      if (_expandedChanged) {
        return SchedulerBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            setState(() => __expanded = index);
          }
        });
      } else {
        setState(() => __expanded = index);
      }

      _expandedChanged = true;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _expandedChanged = false;
      });
    }
  }

  @override
  void didUpdateWidget(covariant Dock<T> oldWidget) {
    if (!const ListEquality().equals(
      oldWidget.items.map((e) => e.runtimeType).toList(),
      widget.items.map((e) => e.runtimeType).toList(),
    )) {
      _items = widget.items.map((e) => _DraggedItem<T>(e)).toList();
      _populateExpandedKeys();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    _items = widget.items.map((e) => _DraggedItem<T>(e)).toList();
    _expandedKeys = List.generate(_items.length + 10, (_) => GlobalKey());
    super.initState();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Builds a [Row] of the [_items].
    ///
    /// The [Row] is constructed in the following way:
    /// `{Flexible}{Item}...{Item}{Flexible}`
    ///
    /// The [Flexible]s are animated, thus creating the expanding/shrinking
    /// effects.
    Widget builder(
      BuildContext context,
      List<T?> candidates,
      List<dynamic> rejected,
    ) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _items.mapMany((e) {
          int i = _items.indexOf(e);
          return [
            // Add the leading [Flexible]s, if this is the first item.
            if (i == 0) ...[
              const Flexible(flex: 1, child: SizedBox(width: 10)),
              AnimatedContainer(
                key: _expandedKeys[0],
                duration: _animateDuration,
                width: _expanded == 0
                    ? _items.firstOrNull?.key.globalPaintBounds?.width ?? _size
                    : 0,
              ),
              if (_compressed == 0)
                AnimatedDelayedWidth(
                  beginWidth: _size,
                  endWidth: 0,
                  duration: jumpDuration,
                ),
              Flexible(
                flex: _expanded == 0 ? 1 : 0,
                child: SizedBox(
                  width: _expanded == 0 ? 10 : 0,
                ),
              ),
            ],

            // [Draggable] item itself.
            Flexible(
              flex: 5,
              child: Container(
                constraints: BoxConstraints(maxWidth: _size, maxHeight: _size),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: LayoutBuilder(builder: (c, constraints) {
                    return DelayedDraggable(
                      maxSimultaneousDrags: _entry == null ? 1 : 0,
                      distance: widget.delayed ? 6 : 0,
                      dragAnchorStrategy: pointerDragAnchorStrategy,
                      feedback: Transform.translate(
                        offset: -Offset(
                          constraints.maxWidth / 2,
                          constraints.maxHeight / 2,
                        ),
                        child: ConstrainedBox(
                          constraints: constraints,
                          child: widget.itemBuilder(e.item),
                        ),
                      ),
                      data: e.item,
                      onDragCompleted: () {
                        _rect = null;
                        widget.onReorder
                            ?.call(_items.map((e) => e.item).toList());
                      },
                      onDragStarted: () {
                        _resetAnimations();
                        widget.onDragStarted?.call(_items[i].item);

                        _rect = _items[i].key.globalPaintBounds;
                        _expanded = i;
                        _dragged = MapEntry(i, e);

                        _items.removeAt(i);

                        setState(() {});
                      },
                      onDraggableCanceled: (_, o) {
                        int index = _dragged!.key;

                        _expanded = index;
                        final _DraggedItem<T> dragged = _dragged!.value;

                        // Animate the item returning to its position.
                        _animate(
                          item: _dragged!.value,
                          context: context,
                          beginRect: Rect.fromLTWH(
                            o.dx - _rect!.width / 2,
                            o.dy - _rect!.height / 2,
                            _rect!.width,
                            _rect!.height,
                          ),
                          endRect: _rect!,
                          onEnd: () {
                            if (mounted) {
                              setState(() {
                                _resetAnimations();
                                _expanded = -1;
                                _items.insert(index, dragged);
                                _populateExpandedKeys();
                                widget.onDragEnded?.call(_items[index].item);
                              });
                            }
                          },
                        );

                        _rect = null;
                        _dragged = null;

                        setState(() {});
                      },
                      child: Opacity(
                        opacity: e.hidden ? 0 : 1,
                        child: KeyedSubtree(
                          key: e.key,
                          child: widget.itemBuilder(e.item),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // Add the trailing [Flexible]s.
            Flexible(
              flex: _expanded - 1 == i ? 1 : 0,
              child: SizedBox(width: _expanded - 1 == i ? 10 : 0),
            ),
            AnimatedContainer(
              key: _expandedKeys[i + 1],
              duration: _animateDuration,
              width: _expanded - 1 == i
                  ? _items.firstOrNull?.key.globalPaintBounds?.width ?? _size
                  : 0,
            ),
            if (_compressed - 1 == i)
              AnimatedDelayedWidth(
                beginWidth: _size,
                endWidth: 0,
                duration: jumpDuration,
              ),
            const Flexible(flex: 1, child: SizedBox(width: 10)),
          ];
        }).toList(),
      );
    }

    return DragTarget<T>(
      key: _dockKey,
      onMove: _onMove,
      onAcceptWithDetails: _onAcceptWithDetails,
      onLeave: (e) {
        if (e == null || (widget.onWillAccept?.call(e) ?? true)) {
          widget.onLeave?.call(e);
          _expanded = -1;
        }
      },
      onWillAcceptWithDetails: (e) =>
          (widget.onWillAccept?.call(e.data) ?? true) && _entry == null,
      builder: builder,
    );
  }

  /// Adds the provided [item] to the [_items] and animates the addition.
  void _onAcceptWithDetails(DragTargetDetails<T> item) {
    var data = _DraggedItem(item.data);

    if (_expanded > _items.length) {
      _expanded = _items.length;
    } else if (_expanded < 0) {
      _expanded = 0;
    }

    int i = _items.indexWhere((e) => e == data);
    if (i == -1) {
      int to = _expanded;

      Rect? rect = _rect ?? _items.firstOrNull?.key.globalPaintBounds;

      Offset dragOffset = Offset(
        item.offset.dx -
            (rect != null && _dragged != null ? rect.width : _size) / 2,
        item.offset.dy -
            (rect != null && _dragged != null ? rect.height : _size) / 2,
      );

      Rect begin;
      if (rect != null) {
        begin = Rect.fromLTWH(
          dragOffset.dx,
          dragOffset.dy,
          rect.width,
          rect.height,
        );
      } else {
        begin = Rect.fromLTWH(dragOffset.dx, dragOffset.dy, _size, _size);
      }

      Rect endRect = _expandedKeys[_expanded].globalPaintBounds!;

      // Compensate another [_expandedKeys].
      for (var e in _expandedKeys) {
        if (_expandedKeys.indexOf(e) < _expanded) {
          endRect = endRect.translate(
            -(e.globalPaintBounds ?? Rect.zero).width / 2,
            0,
          );
        }

        if (_expandedKeys.indexOf(e) > _expanded) {
          endRect = endRect.translate(
            (e.globalPaintBounds ?? Rect.zero).width / 2,
            0,
          );
        }
      }

      final double size = rect?.width ?? _size;
      if (endRect.height < size) {
        endRect = Rect.fromCenter(
          center: endRect.center,
          width: size,
          height: size,
        );
      }

      _animate(
        item: data,
        context: context,
        beginRect: begin,
        endRect: endRect,
        onEnd: () {
          if (mounted) {
            setState(() {
              _resetAnimations();
              _expanded = -1;
              _dragged = null;
              _items.insert(to, data);
              _populateExpandedKeys();
              widget.onDragEnded?.call(_items[to].item);
            });
          }
        },
      );
    } else {
      if (i == _expanded || i + 1 == _expanded) {
        // If this position is already expanded, then the item is at this
        // position, so no action is needed.
        _expanded = -1;
        return;
      }

      if (_expanded > i) {
        setState(() => _expanded--);
      }

      int to = _expanded;
      if (to > _items.length) {
        to = _items.length;
      }

      Rect begin = _items[i].key.globalPaintBounds!;
      Rect end = _items[to].paintBounds!;

      _items.removeAt(i);
      _expandedKeys.removeAt(i);

      // Add compressing animation to the previous position.
      _compressed = i;

      // Display the [data] moving from the previous to its new position.
      _animate(
        item: data,
        context: context,
        beginRect: begin,
        endRect: end,
        onEnd: () {
          if (mounted) {
            setState(() {
              _resetAnimations();
              _expanded = -1;
              widget.onDragEnded?.call(data.item);
              _items.insert(to, data);
              _populateExpandedKeys();
              _compressed = -1;
            });
          }
        },
      );
    }

    widget.onReorder?.call(_items.map((e) => e.item).toList());
  }

  /// Calculates the position to drop the provided item at.
  void _onMove(DragTargetDetails<T> d) {
    if (widget.onWillAccept?.call(d.data) == false) {
      return;
    }

    Rect? rect = _dockKey.globalPaintBounds ?? Rect.zero;
    int indexToPlace = ((d.offset.dx -
                rect.left -
                (rect.size.width / (_items.length + 1)).ceil()) /
            (rect.size.width / (_items.length + 1)).ceil())
        .ceil();
    if (indexToPlace > _items.length) {
      indexToPlace = _items.length;
    } else if (indexToPlace < 0) {
      indexToPlace = 0;
    }

    if (_expanded < 0) {
      for (_DraggedItem<T> e in _items) {
        e.paintBounds = e.key.globalPaintBounds;
      }
    }

    // Update the [__expanded] here directly, if [_dragged] is `null`, meaning
    // this [_onMove] was invoked before the [onDragStarted].
    //
    // Otherwise the [__expanded] will be assigned to an invalid value, causing
    // the animation to flicker.
    if (_dragged == null) {
      setState(() => __expanded = indexToPlace);
    } else {
      _expanded = indexToPlace;
    }
  }

  /// Sets the [_animateDuration] to [Duration.zero] for one frame.
  void _resetAnimations() {
    _animateDuration = Duration.zero;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => _animateDuration = animateDuration,
    );
  }

  /// Populates the [_entry] with the [AnimatedTransition].
  void _animate({
    required _DraggedItem<T> item,
    required BuildContext context,
    required Rect beginRect,
    required Rect endRect,
    required VoidCallback onEnd,
  }) {
    _entry = OverlayEntry(
      builder: (_) => AnimatedTransition(
        beginRect: beginRect,
        endRect: endRect,
        duration: jumpDuration,
        onEnd: () {
          onEnd();
          _removeOverlay();
        },
        child: widget.itemBuilder(item.item),
      ),
    );

    Overlay.of(context).insert(_entry!);
  }

  /// Removes the [_entry].
  void _removeOverlay() {
    if (_entry?.mounted == true) {
      _entry?.remove();
    }
    _entry = null;
  }

  /// Populates the [_expandedKeys] according to the [_items].
  void _populateExpandedKeys() {
    final int length = _items.length + 1;

    if (_expandedKeys.length > length) {
      _expandedKeys.removeRange(length, _expandedKeys.length);
    } else if (_expandedKeys.length < length) {
      _expandedKeys.addAll(
        List.generate(length - _expandedKeys.length, (_) => GlobalKey()),
      );
    }
  }
}

/// Data of an [Object] used in a [Dock] to be reordered around.
class _DraggedItem<T> {
  _DraggedItem(this.item);

  /// Reorderable [Object] itself.
  final T item;

  /// [GlobalKey] representing the global position of this [item].
  final GlobalKey key = GlobalKey();

  /// Stored [RenderObject.paintBounds] of this [_DraggedItem] used to display
  /// the sliding animation.
  Rect? paintBounds;

  /// Indicator whether this [item] should not be displayed.
  bool hidden = false;

  @override
  int get hashCode => item.hashCode;

  @override
  bool operator ==(Object other) => other is _DraggedItem && item == other.item;
}

/// [Draggable] starting its dragging after some distance threshold is reached.
class DelayedDraggable<T extends Object> extends Draggable<T> {
  const DelayedDraggable({
    super.key,
    required super.child,
    required super.feedback,
    super.data,
    super.dragAnchorStrategy,
    super.maxSimultaneousDrags,
    super.onDragStarted,
    super.onDragEnd,
    super.onDraggableCanceled,
    super.onDragCompleted,
    this.distance = 6,
  });

  /// Distance in pixels, that must be traveled by pointer for gesture
  /// recognition.
  final double distance;

  @override
  MultiDragGestureRecognizer createRecognizer(
    GestureMultiDragStartCallback onStart,
  ) {
    return _ImmediateDelayedMultiDragGestureRecognizer(
      debugOwner: '$hashCode',
      distance: distance,
    )..onStart = (Offset position) {
        final Drag? result = onStart(position);
        if (result != null) {
          HapticFeedback.selectionClick();
        }
        return result;
      };
  }
}

/// [MultiDragGestureRecognizer] recognizing a drag gesture after some distance
/// threshold is reached.
class _ImmediateDelayedMultiDragGestureRecognizer
    extends MultiDragGestureRecognizer {
  _ImmediateDelayedMultiDragGestureRecognizer({
    super.debugOwner,
    this.distance = 6,
  });

  /// Distance in pixels, that must be traveled by pointer for gesture
  /// recognition.
  final double distance;

  @override
  MultiDragPointerState createNewPointerState(PointerDownEvent event) =>
      _ImmediateDelayedPointerState(
        event.position,
        event.kind,
        gestureSettings,
        distance: distance,
      );

  @override
  String get debugDescription => 'ImmediateDelayedMultiDragGestureRecognizer';
}

/// [MultiDragPointerState] of a [_ImmediateDelayedMultiDragGestureRecognizer].
class _ImmediateDelayedPointerState extends MultiDragPointerState {
  _ImmediateDelayedPointerState(
    super.initialPosition,
    super.kind,
    super.deviceGestureSettings, {
    this.distance = 6,
  });

  /// Distance in pixels, that must be traveled by pointer for gesture
  /// recognition.
  final double distance;

  @override
  void checkForResolutionAfterMove() {
    if (pendingDelta!.distance > distance) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void accepted(starter) => starter(initialPosition);
}
