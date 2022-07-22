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

import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/ui/page/home/widget/gallery_popup.dart';
import 'animated_transition.dart';

/// Reorderable [Row] of the provided [items].
class Dock<T extends Object> extends StatefulWidget {
  const Dock({
    Key? key,
    required this.items,
    required this.itemBuilder,
    this.onReorder,
    this.itemWidth = 48,
    this.onDragStarted,
    this.onDragEnded,
    this.onLeave,
    this.onWillAccept,
  }) : super(key: key);

  /// Items this [Dock] reorders.
  final List<T> items;

  /// Builder building the provided item.
  final Widget Function(T item) itemBuilder;

  /// Max width [itemBuilder] is allowed to build within.
  final double itemWidth;

  /// Callback, called when the [items] list is reordered.
  final Function(List<T>)? onReorder;

  /// Callback, called when item dragging is started.
  final Function(T)? onDragStarted;

  /// Callback, called when item dragging is ended.
  final Function(T)? onDragEnded;

  /// Callback, called when a _dragged item leaves this [Dock].
  final Function(T?)? onLeave;

  /// Callback, called when this [Dock] may accept the _dragged item.
  final bool Function(T)? onWillAccept;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of a [Dock] maintaining the reorderable [_items] list.
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [Duration] of [_DraggedItem] jumping from one position to another.
  static const Duration jumpDuration = Duration(milliseconds: 300);

  /// [Duration] of [AnimatedContainer]s representing [_DraggedItem]s being
  /// added and removed animations.
  static const Duration animateDuration = Duration(milliseconds: 150);

  /// [_DraggedItem]s of this [Dock].
  late final List<_DraggedItem<T>> _items;

  /// Current [Duration] of [AnimatedContainer]s.
  Duration _animateDuration = animateDuration;

  /// Position in [_items] to add expanding [AnimatedContainer] to.
  int _expanded = -1;

  /// Position in [_items] to add shrinking [AnimatedContainer] to.
  int _compressed = -1;

  /// [MapEntry] of the currently moved [_DraggedItem] along with its index.
  MapEntry<int, _DraggedItem<T>>? _dragged;

  /// [GlobalKey] of [DragTarget].
  final GlobalKey _dockKey = GlobalKey();

  /// [Rect] of [_DraggedItem].
  Rect? _rect;

  /// Currently displayed [OverlayEntry].
  OverlayEntry? overlay;

  /// Returns item size.
  double get itemSize => _items.isEmpty ||
          _items.first.key.currentState == null ||
          _items.first.key.currentState?.mounted == false ||
          _items.first.key.currentContext?.size == null
      ? widget.itemWidth
      : _items.first.key.currentContext!.size!.width;

  /// [BoxConstraints] of item.
  BoxConstraints get itemConstraints =>
      BoxConstraints(maxHeight: itemSize, maxWidth: itemSize);

  @override
  void initState() {
    _items = widget.items.map((e) => _DraggedItem<T>(e)).toList();
    super.initState();
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Builds a [Row] of the [_items] itself.
    Widget _builder(
      BuildContext context,
      List<T?> candidates,
      List<dynamic> rejected,
    ) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: _items.mapMany(
          (e) {
            int i = _items.indexOf(e);
            return [
              if (_items.firstOrNull == e) ...[
                Flexible(
                  flex: 1,
                  child: Container(width: 10),
                ),
                AnimatedContainer(
                  duration: _animateDuration,
                  width: _expanded == 0 && _expanded == i
                      ? _rect == null
                          ? itemConstraints.maxWidth
                          : _rect!.width
                      : 0,
                ),
                if (_compressed == 0 && _compressed == i)
                  _AnimatedWidth(
                    beginWidth: itemConstraints.maxWidth,
                    endWidth: 0,
                    duration: jumpDuration,
                  ),
                Flexible(
                  flex: _expanded == 0 && _expanded == i ? 1 : 0,
                  child: Container(
                    width: _expanded == 0 && _expanded == i ? 10 : 0,
                  ),
                ),
              ],
              Flexible(
                flex: 5,
                child: Container(
                  constraints: itemConstraints,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(builder: (c, constraints) {
                      return Draggable(
                        maxSimultaneousDrags: overlay == null ? 1 : 0,
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
                          int savedDraggedIndex = _dragged!.key;

                          // Show animation of _dragged item returns to its
                          // start position.
                          _showOverlay(
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
                                  _items[savedDraggedIndex].hidden = false;
                                  widget.onDragEnded
                                      ?.call(_items[savedDraggedIndex].item);
                                });
                              }
                            },
                          );

                          _items.insert(_dragged!.key, _dragged!.value);
                          _items[_dragged!.key].hidden = true;

                          _rect = null;
                          _dragged = null;
                          _expanded = -1;

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
              Flexible(
                flex: _expanded - 1 == i ? 1 : 0,
                child: SizedBox(width: _expanded - 1 == i ? 10 : 0),
              ),
              AnimatedContainer(
                duration: _animateDuration,
                width: _expanded - 1 == i
                    ? _rect == null
                        ? itemConstraints.maxWidth
                        : _rect!.width
                    : 0,
              ),
              if (_compressed - 1 == i)
                _AnimatedWidth(
                  beginWidth: itemConstraints.maxWidth,
                  endWidth: 0,
                  duration: jumpDuration,
                ),
              const Flexible(flex: 1, child: SizedBox(width: 10)),
            ];
          },
        ).toList(),
      );
    }

    return DragTarget<T>(
      key: _dockKey,
      onMove: _onMove,
      onAcceptWithDetails: _onAcceptWithDetails,
      onLeave: (e) {
        if (e == null || (widget.onWillAccept?.call(e) ?? true)) {
          widget.onLeave?.call(e);
          setState(() => _expanded = -1);
        }
      },
      onWillAccept: (e) {
        return e != null &&
            (widget.onWillAccept?.call(e) ?? true) &&
            overlay == null;
      },
      builder: _builder,
    );
  }

  /// Adds the provided [item] to the [_items] list and animates the addition.
  void _onAcceptWithDetails(DragTargetDetails<T> item) {
    var data = _DraggedItem(item.data);

    if (_expanded > _items.length) {
      _expanded = _items.length;
    } else if (_expanded < 0) {
      _expanded = 0;
    }

    int i = _items.indexWhere((e) => e == data);
    if (i == -1) {
      var dragOffset = Offset(
        item.offset.dx -
            (_rect != null && _dragged != null ? _rect!.width : itemSize) / 2,
        item.offset.dy -
            (_rect != null && _dragged != null ? _rect!.height : itemSize) / 2,
      );

      _items.insert(_expanded, data);

      // Save added item index.
      int to = _expanded;

      // [OverlayEntry] that will display [_dragged] item at onDragEnded place.
      overlay = OverlayEntry(
        builder: (context) => Positioned(
          left: dragOffset.dx,
          top: dragOffset.dy,
          child: Container(
            constraints: _rect != null
                ? BoxConstraints(
                    maxWidth: _rect!.width,
                    maxHeight: _rect!.height,
                  )
                : itemConstraints,
            child: widget.itemBuilder(data.item),
          ),
        ),
      );
      Overlay.of(context)?.insert(overlay!);

      _items[to].hidden = true;
      _resetAnimations();

      // Post frame callBack to display animation of adding item to items list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _removeOverlay();

        Rect endRect = _items[to].key.globalPaintBounds!;
        Rect beginRect;
        if (_rect != null) {
          beginRect = Rect.fromLTWH(
            dragOffset.dx,
            dragOffset.dy,
            _rect!.width,
            _rect!.height,
          );
        } else {
          beginRect = Rect.fromLTWH(
            dragOffset.dx,
            dragOffset.dy,
            itemConstraints.maxWidth,
            itemConstraints.maxHeight,
          );
        }

        // Display animation of adding item.
        _showOverlay(
          item: data,
          context: context,
          beginRect: beginRect,
          endRect: endRect,
          onEnd: () {
            if (mounted) {
              setState(() {
                _dragged = null;
                _items[to].hidden = false;
                widget.onDragEnded?.call(_items[to].item);
              });
            }
          },
        );
      });
    } else {
      if (i == _expanded || i + 1 == _expanded) {
        return setState(() => _expanded = -1);
      } else {
        _resetAnimations();
      }

      int to = _expanded;
      if (to > i) {
        to--;
      }

      _items.removeAt(i);

      // Add item to [_items] list and hide it.
      if (to > _items.length) {
        _items.add(data);
        _items.last.hidden = true;
        to = _items.length;
      } else {
        _items.insert(to, data);
        _items[to].hidden = true;
      }

      // Add compressing animation of the old [item] place.
      if (to < i) {
        _compressed = i + 1;
      } else {
        _compressed = i;
      }

      // Display animation of sliding item from old place to new place.
      _showOverlay(
        item: data,
        context: context,
        beginRect: _items[i].key.globalPaintBounds!,
        endRect: _items[to].paintBounds!,
        onEnd: () {
          if (mounted) {
            setState(() {
              _items[to].hidden = false;
              widget.onDragEnded?.call(_items[to].item);
              _compressed = -1;
            });
          }
        },
      );
    }

    _expanded = -1;
    widget.onReorder?.call(_items.map((e) => e.item).toList());
    setState(() {});
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

    setState(() => _expanded = indexToPlace);
  }

  /// Resets [AnimatedContainer]'s width changing animations.
  void _resetAnimations() {
    _animateDuration = Duration.zero;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(
        Duration.zero,
        () => _animateDuration = 150.milliseconds,
      ),
    );
  }

  /// Shows item animation in overlay.
  void _showOverlay({
    required _DraggedItem<T> item,
    required BuildContext context,
    required Rect beginRect,
    required Rect endRect,
    required VoidCallback onEnd,
  }) {
    overlay = OverlayEntry(
      builder: (_) => AnimatedTransition(
        beginRect: beginRect,
        endRect: endRect,
        animationDuration: jumpDuration,
        onEnd: () {
          onEnd();
          _removeOverlay();
        },
        child: widget.itemBuilder(item.item),
      ),
    );

    Overlay.of(context)!.insert(overlay!);
  }

  /// Removes currently displayed [OverlayEntry].
  void _removeOverlay() {
    if (overlay?.mounted == true) {
      overlay!.remove();
    }
    overlay = null;
  }
}

/// Data of an [Object] used in a [Dock] to be reordered around.
class _DraggedItem<T> {
  _DraggedItem(this.item);

  /// Reorderable [Object] itself.
  final T item;

  /// [GlobalKey] representing the global position of this [item].
  final GlobalKey key = GlobalKey();

  /// Default [Rect] of this item.
  ///
  /// Used to play animation on adding an item that already exist.
  Rect? paintBounds;

  /// Indicator whether this [item] should not be displayed.
  bool hidden = false;

  @override
  int get hashCode => item.hashCode;

  @override
  bool operator ==(Object other) => other is _DraggedItem && item == other.item;
}

/// [AnimatedContainer] changing its width from [beginWidth] to [endWidth].
class _AnimatedWidth extends StatefulWidget {
  const _AnimatedWidth({
    Key? key,
    required this.beginWidth,
    required this.endWidth,
    required this.duration,
  }) : super(key: key);

  /// [Duration] of resize animation.
  final Duration duration;

  /// Initial width of an [AnimatedContainer].
  final double beginWidth;

  /// Target width of an [AnimatedContainer].
  final double endWidth;

  @override
  State<_AnimatedWidth> createState() => _AnimatedWidthState();
}

/// State of an [_AnimatedWidth] maintaining the [width].
class _AnimatedWidthState extends State<_AnimatedWidth> {
  /// Current width value.
  late double width;

  @override
  void initState() {
    super.initState();

    width = widget.beginWidth;
    Future.delayed(Duration.zero, () {
      if (mounted) {
        setState(() => width = widget.endWidth);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: widget.duration,
      width: width,
      curve: Curves.ease,
    );
  }
}
