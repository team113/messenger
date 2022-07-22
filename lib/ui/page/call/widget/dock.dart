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

import '/ui/page/call/widget/animated_transition.dart';
import '/ui/page/home/widget/gallery_popup.dart';

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
  final Function()? onDragEnded;

  /// Callback, called when a dragged item leaves this [Dock].
  final Function()? onLeave;

  /// Callback, called when this [Dock] may accept the dragged item.
  final bool Function(T)? onWillAccept;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of a [Dock] maintaining the reorderable [_items] list.
class _DockState<T extends Object> extends State<Dock<T>> {
  /// [_DraggedItem]s of this [Dock].
  late final List<_DraggedItem<T>> _items;

  /// Duration of animation moving button to its place on end of dragging.
  Duration movingAnimationDuration = 300.milliseconds;

  /// Duration of [AnimatedContainer] width changing animation.
  Duration animationsDuration = 150.milliseconds;

  /// Place where item will be placed.
  int expandBetween = -1;

  /// Place where item was placed before same item was added.
  int compressBetween = -1;

  /// Index of item was started dragging.
  int draggedIndex = -1;

  /// Item that was dragged.
  _DraggedItem<T>? dragged;

  /// [GlobalKey] of [DragTarget].
  final GlobalKey _dockKey = GlobalKey();

  /// [Rect] of item was started dragging.
  Rect? startDragRect;

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
                  duration: animationsDuration,
                  width: expandBetween == 0 && expandBetween == i
                      ? startDragRect == null
                          ? itemConstraints.maxWidth
                          : startDragRect!.width
                      : 0,
                ),
                if (compressBetween == 0 && compressBetween == i)
                  _AnimatedWidth(
                    beginWidth: itemConstraints.maxWidth,
                    endWidth: 0,
                    duration: movingAnimationDuration,
                  ),
                Flexible(
                  flex: expandBetween == 0 && expandBetween == i ? 1 : 0,
                  child: Container(
                    width: expandBetween == 0 && expandBetween == i ? 10 : 0,
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
                          startDragRect = null;
                          widget.onReorder
                              ?.call(_items.map((e) => e.item).toList());
                        },
                        onDragStarted: () {
                          _resetAnimations();
                          widget.onDragStarted?.call(_items[i].item);

                          startDragRect = _items[i].key.globalPaintBounds;

                          expandBetween = i;
                          dragged = e;
                          draggedIndex = i;
                          _items.removeAt(i);

                          setState(() {});
                        },
                        onDraggableCanceled: (_, o) {
                          int savedDraggedIndex = draggedIndex;

                          // Show animation of dragged item returns to its
                          // start position.
                          _showOverlay(
                            item: dragged!,
                            context: context,
                            beginRect: Rect.fromLTWH(
                              o.dx - startDragRect!.width / 2,
                              o.dy - startDragRect!.height / 2,
                              startDragRect!.width,
                              startDragRect!.height,
                            ),
                            endRect: startDragRect!,
                            onEnd: () {
                              if (mounted) {
                                setState(() {
                                  _items[savedDraggedIndex].hidden = false;
                                  widget.onDragEnded?.call();
                                });
                              }
                            },
                          );

                          _items.insert(draggedIndex, dragged!);
                          _items[draggedIndex].hidden = true;

                          startDragRect = null;
                          draggedIndex = -1;
                          dragged = null;
                          expandBetween = -1;

                          setState(() {});
                        },
                        child: Opacity(
                          opacity: (e.hidden) ? 0 : 1,
                          child: KeyedSubtree(
                              key: e.key, child: widget.itemBuilder(e.item)),
                        ),
                      );
                    }),
                  ),
                ),
              ),
              Flexible(
                flex: expandBetween - 1 == i ? 1 : 0,
                child: Container(
                  width: expandBetween - 1 == i ? 10 : 0,
                ),
              ),
              AnimatedContainer(
                duration: animationsDuration,
                width: expandBetween - 1 == i
                    ? startDragRect == null
                        ? itemConstraints.maxWidth
                        : startDragRect!.width
                    : 0,
              ),
              if (compressBetween - 1 == i)
                _AnimatedWidth(
                  beginWidth: itemConstraints.maxWidth,
                  endWidth: 0,
                  duration: movingAnimationDuration,
                ),
              Flexible(
                flex: 1,
                child: Container(
                  width: 10,
                ),
              ),
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
          widget.onLeave?.call();
          setState(() => expandBetween = -1);
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

    if (expandBetween > _items.length) {
      expandBetween = _items.length;
    } else if (expandBetween < 0) {
      expandBetween = 0;
    }

    int i = _items.indexWhere((e) => e == data);
    if (i == -1) {
      var savedStartDragRect = startDragRect;
      var dragOffset = Offset(
        item.offset.dx -
            ((savedStartDragRect != null && dragged != null)
                    ? savedStartDragRect.width
                    : itemSize) /
                2,
        item.offset.dy -
            ((savedStartDragRect != null && dragged != null)
                    ? savedStartDragRect.height
                    : itemSize) /
                2,
      );

      _items.insert(expandBetween, data);

      // Save added item index.
      int whereToPlace = expandBetween;

      // OverlayEntry that will display dragged item at onDragEnded place.
      overlay = OverlayEntry(
        builder: (context) => Positioned(
          left: dragOffset.dx,
          top: dragOffset.dy,
          child: Container(
            constraints: savedStartDragRect != null
                ? BoxConstraints(
                    maxWidth: savedStartDragRect.width,
                    maxHeight: savedStartDragRect.height,
                  )
                : itemConstraints,
            child: widget.itemBuilder(data.item),
          ),
        ),
      );
      Overlay.of(context)?.insert(overlay!);

      _items[whereToPlace].hidden = true;
      _resetAnimations();

      // Post frame callBack to display animation of adding item to items list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _removeOverlay();

        Rect endRect = _items[whereToPlace].key.globalPaintBounds!;
        Rect beginRect;
        if (savedStartDragRect != null) {
          beginRect = Rect.fromLTWH(
            dragOffset.dx,
            dragOffset.dy,
            savedStartDragRect.width,
            savedStartDragRect.height,
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
                dragged = null;
                _items[whereToPlace].hidden = false;
                widget.onDragEnded?.call();
              });
            }
          },
        );
      });
    } else {
      if (i == expandBetween || i + 1 == expandBetween) {
        return setState(() => expandBetween = -1);
      } else {
        _resetAnimations();
      }

      int whereToPlace = expandBetween;
      if (whereToPlace > i) {
        whereToPlace--;
      }

      var beginRect = _items[i].key.globalPaintBounds!;
      var endRect = _items[whereToPlace].defaultRect!;

      _items.removeAt(i);

      // Add item to [_items] list and hide it.
      if (whereToPlace > _items.length) {
        _items.add(data);
        _items.last.hidden = true;
        whereToPlace = _items.length;
      } else {
        _items.insert(whereToPlace, data);
        _items[whereToPlace].hidden = true;
      }

      // Add compressing animation of the old [item] place.
      if (whereToPlace < i) {
        compressBetween = i + 1;
      } else {
        compressBetween = i;
      }

      // Display animation of sliding item from old place to new place.
      _showOverlay(
        item: data,
        context: context,
        beginRect: beginRect,
        endRect: endRect,
        onEnd: () {
          if (mounted) {
            setState(() {
              _items[whereToPlace].hidden = false;
              widget.onDragEnded?.call();
              compressBetween = -1;
            });
          }
        },
      );
    }

    expandBetween = -1;
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

    if (expandBetween < 0) {
      for (var e in _items) {
        e.updateDefaultRect();
      }
    }

    setState(() => expandBetween = indexToPlace);
  }

  /// Resets [AnimatedContainer]'s width changing animations.
  void _resetAnimations() {
    animationsDuration = Duration.zero;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(
        Duration.zero,
        () => animationsDuration = 150.milliseconds,
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
      builder: (context) => AnimatedTransition(
        beginRect: beginRect,
        endRect: endRect,
        animationDuration: movingAnimationDuration,
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

  /// [GlobalKey] of this [_DraggedItem] representing the global position of
  /// this [item].
  final GlobalKey key = GlobalKey();

  /// Default [Rect] of this item.
  ///
  /// Used to play animation on adding an item that already exist.
  Rect? defaultRect;

  /// Indicator whether this [item] should not be displayed.
  bool hidden = false;

  /// Updates [defaultRect].
  void updateDefaultRect() => defaultRect = key.globalPaintBounds;

  @override
  bool operator ==(Object other) => other is _DraggedItem && item == other.item;

  @override
  int get hashCode => item.hashCode;
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
