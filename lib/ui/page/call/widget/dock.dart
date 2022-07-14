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

/// Item builder function.
typedef ButtonsDockBuilderFunction = Function(
  BuildContext context,
  DraggedItem item,
);

/// Dock reordering it's [items].
class Dock<T> extends StatefulWidget {
  const Dock({
    required this.items,
    required this.itemBuilder,
    required this.onReorder,
    this.itemSize = 48,
    this.onDragStarted,
    this.onDragEnded,
    this.onLeave,
    this.onWillAccept,
    Key? key,
  }) : super(key: key);

  /// Items this [Dock] reorders.
  final List<T> items;

  /// Builder building the [items].
  final ButtonsDockBuilderFunction itemBuilder;

  /// Max size of [items].
  final double itemSize;

  /// Callback, called when the [items] were reordered.
  final Function(List)? onReorder;

  /// Callback, called when any drag of [items] is started.
  final Function(DraggedItem)? onDragStarted;

  /// Callback, called when any drag of [items] is ended.
  final Function()? onDragEnded;

  /// Callback, called when any dragged item leave this [Dock].
  final Function()? onLeave;

  /// Callback, called to determine whether this widget is interested in
  /// receiving a given piece of data being dragged over drag target.
  final bool Function(T)? onWillAccept;

  @override
  State<Dock<T>> createState() => _DockState<T>();
}

/// State of [Dock] used to handle reordering.
class _DockState<T> extends State<Dock<T>> {
  /// Duration of animation moving button to his place on end of dragging.
  Duration movingAnimationDuration = const Duration(milliseconds: 150);

  /// List of items.
  List<DraggedItem> items = [];

  /// Duration of [AnimatedContainer] width changing.
  Duration animationsDuration = 150.milliseconds;

  /// Place where item will be placed.
  int expandBetween = -1;

  /// Place where item was placed.
  int compressBetween = -1;

  /// Index of item was started dragging.
  int draggedIndex = -1;

  /// Element that was dragged.
  DraggedItem? dragged;

  /// [GlobalKey] of zone where items can be dragged or placed.
  GlobalKey dragZone = GlobalKey();

  /// [Offset] of item that was dragging.
  Offset? startDragOffset;

  /// [Offset] where item was dragged.
  Offset? moveDragOffset;

  /// Size of dragged item.
  BoxConstraints? startDragConstraints;

  /// [Offset] position of same item.
  Offset? positionOnSameItem;

  /// [BoxConstraints] constraints of same item.
  BoxConstraints? constraintsOnSameItem;

  /// Indicator whether some item is animated.
  bool isAnimated = false;

  /// List of currently displayed overlays.
  List<OverlayEntry> overlays = [];

  /// Returns item width.
  double get itemWidth => items.isEmpty ||
          items.first.key.currentState == null ||
          items.first.key.currentState?.mounted == false ||
          items.first.key.currentContext?.size == null
      ? widget.itemSize
      : items.first.key.currentContext!.size!.width;

  /// [BoxConstraints] of item.
  BoxConstraints get itemConstraints =>
      BoxConstraints(maxHeight: itemWidth, maxWidth: itemWidth);

  @override
  void initState() {
    items = widget.items.map((e) => DraggedItem(e)).toList();
    super.initState();
  }

  @override
  void dispose() {
    for (var e in overlays) {
      if (e.mounted) {
        e.remove();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    /// Builder of the [DropTarget] building a [Row] of the reorderable [items].
    Widget _builder(
      BuildContext context,
      List<DraggedItem?> candidates,
      List<dynamic> rejected,
    ) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: items.mapMany(
          (e) {
            int i = items.indexOf(e);
            return [
              if (items.firstOrNull == e) ...[
                Flexible(
                  flex: 1,
                  child: Container(width: 10),
                ),
                AnimatedContainer(
                  duration: animationsDuration,
                  width: expandBetween == 0 && expandBetween == i
                      ? startDragConstraints == null
                          ? itemConstraints.maxWidth
                          : startDragConstraints!.maxWidth
                      : 0,
                ),
                if (compressBetween == 0 && compressBetween == i)
                  AnimatedWidth(
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
                    child: LayoutBuilder(
                        builder: (c, constraints) => Draggable(
                              maxSimultaneousDrags: isAnimated ? 0 : 1,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              feedback: Transform.translate(
                                offset: -Offset(constraints.maxWidth / 2,
                                    constraints.maxHeight / 2),
                                child: ConstrainedBox(
                                  constraints: constraints,
                                  child: KeyedSubtree(
                                      key: e.key,
                                      child: widget.itemBuilder(context, e)),
                                ),
                              ),
                              data: e,
                              onDragCompleted: () => widget.onReorder
                                  ?.call(items.map((e) => e.item).toList()),
                              onDragStarted: () {
                                _resetAnimations();
                                widget.onDragStarted?.call(items[i]);

                                // Get RenderBox of dragged item.
                                RenderBox box = items[i]
                                    .key
                                    .currentContext
                                    ?.findRenderObject() as RenderBox;

                                // Get Offset of dragged item.
                                startDragOffset =
                                    box.localToGlobal(Offset.zero);
                                startDragConstraints = box.constraints;

                                expandBetween = i;
                                dragged = e;
                                draggedIndex = i;
                                items.removeAt(i);

                                setState(() {});
                              },
                              onDraggableCanceled: (v, o) {
                                int savedDraggedIndex = draggedIndex;
                                isAnimated = true;
                                // Show animation of dragged item returns to its
                                // start position.
                                _showOverlay(
                                  item: dragged!,
                                  context: context,
                                  from: Offset(
                                    o.dx - startDragConstraints!.maxWidth / 2,
                                    o.dy - startDragConstraints!.maxHeight / 2,
                                  ),
                                  to: startDragOffset!,
                                  itemConstraints: startDragConstraints!,
                                  onEnd: () {
                                    items[savedDraggedIndex].hide = false;
                                    isAnimated = false;
                                    widget.onDragEnded?.call();
                                    if (mounted) {
                                      setState(() {});
                                    }
                                  },
                                );

                                // Insert dragged item to items list.
                                items.insert(draggedIndex, dragged!);

                                // Hide recently added item.
                                items[draggedIndex].hide = true;

                                draggedIndex = -1;
                                dragged = null;
                                expandBetween = draggedIndex;

                                setState(() {});
                              },
                              child: Opacity(
                                opacity: (e.hide) ? 0 : 1,
                                child: KeyedSubtree(
                                    key: (e.hide) ? e.reserveKey : e.key,
                                    child: widget.itemBuilder(context, e)),
                              ),
                            )),
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
                key: e.dividerKey,
                duration: animationsDuration,
                width: expandBetween - 1 == i
                    ? startDragConstraints == null
                        ? itemConstraints.maxWidth
                        : startDragConstraints!.maxWidth
                    : 0,
              ),
              if (compressBetween - 1 == i)
                AnimatedWidth(
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

    return DragTarget<DraggedItem<T>>(
      key: dragZone,
      onAccept: _onAccept,
      onMove: _onMove,
      onLeave: (e) {
        if (e == null || (widget.onWillAccept?.call(e.item) ?? true)) {
          widget.onLeave?.call();
          setState(() => expandBetween = -1);
        }
      },
      onWillAccept: (e) {
        return e == null ||
            (widget.onWillAccept?.call(e.item) ??
                true); //e?.chatId == widget.chatId;
      },
      builder: _builder,
    );
  }

  /// Adds the provided [item] to the [items] list and animates the addition.
  void _onAccept(DraggedItem<T> item) {
    OverlayState? overlayState = Overlay.of(context);

    if (expandBetween > items.length) {
      expandBetween = items.length;
    } else if (expandBetween < 0) {
      expandBetween = 0;
    }

    // If there's no such item.
    if (items.firstWhereOrNull(
            (e) => e.item.toString() == item.item.toString()) ==
        null) {
      // Insert item to item's list.
      items.insert(expandBetween, item);

      // Save place where item will be added.
      int whereToPlace = expandBetween;

      // Reset expandBetween.
      expandBetween = -1;

      // OverlayEntry that will display dragged item at onDragEnded place.
      OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: moveDragOffset!.dx,
          top: moveDragOffset!.dy,
          child: Container(
            constraints: startDragConstraints != null
                ? startDragConstraints!
                : itemConstraints,
            child: KeyedSubtree(
              key: item.key,
              child: widget.itemBuilder(context, item),
            ),
          ),
        ),
      );

      // Insert OverlayEntry to Overlay to display him.
      overlayState?.insert(overlayEntry);
      overlays.add(overlayEntry);

      // Hide added item.
      items[whereToPlace].hide = true;

      // Reset animations.
      _resetAnimations();
      setState(() {});

      // Save dragged item.
      var localDragged = dragged;

      // Post frame callBack to display animation of adding item to items
      // list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Remove OverlayEntry with item from Overlay.
        overlayEntry.remove();
        overlays.remove(overlayEntry);

        setState(() => isAnimated = true);

        // Get RenderBox of recently added item.
        RenderBox box = items[whereToPlace]
            .reserveKey
            .currentContext!
            .findRenderObject() as RenderBox;

        // Get position of recently added item.
        Offset position = box.localToGlobal(Offset.zero);

        // Display animation of adding item.
        _showOverlay(
          item: item,
          context: context,
          from: moveDragOffset!,
          to: position,
          itemConstraints: startDragConstraints != null && localDragged != null
              ? startDragConstraints!
              : itemConstraints,
          onEnd: () => setState(() {
            isAnimated = false;
            items[whereToPlace].hide = false;
            widget.onDragEnded?.call();
          }),
          endConstraints: startDragConstraints != null && localDragged != null
              ? startDragConstraints!
              : box.constraints,
        );
      });
    }

    // Otherwise the provided [item] is already in the list.
    else {
      // Get position of same item.
      int i =
          items.indexWhere((e) => e.item.toString() == item.item.toString());
      if (i == expandBetween || i + 1 == expandBetween) {
        return setState(() => expandBetween = -1);
      } else {
        _resetAnimations();
      }

      Offset? startPosition;

      // Get RenderBox of same item.
      RenderBox box = items
          .firstWhere((e) => e.item.toString() == item.item.toString())
          .key
          .currentContext!
          .findRenderObject() as RenderBox;

      // Get Offset position of same item.
      startPosition = box.localToGlobal(Offset.zero);

      // Remove same item.
      items.removeAt(i);

      // Save place where item will be added.
      int whereToPlace = expandBetween;
      if (whereToPlace > i) {
        whereToPlace--;
      }

      if (whereToPlace > items.length) {
        // Add item to items list and hide it.
        items.add(item);
        items.last.hide = true;

        // Change saved place where item will be added.
        whereToPlace = items.length;
      } else {
        // Add item to items list and hide it.
        items.insert(whereToPlace, item);
        items[whereToPlace].hide = true;
      }
      expandBetween = -1;

      if (whereToPlace < i) {
        compressBetween = i + 1;
      } else {
        compressBetween = i;
      }

      isAnimated = true;
      dragged = null;

      // Display animation of sliding item from old place to new place.
      _showOverlay(
        item: item,
        context: context,
        from: startPosition,
        to: positionOnSameItem!,
        itemConstraints: constraintsOnSameItem!,
        onEnd: () => setState(() {
          items[whereToPlace].hide = false;
          widget.onDragEnded?.call();
          isAnimated = false;
          compressBetween = -1;
        }),
      );
    }

    widget.onReorder?.call(items.map((e) => e.item).toList());

    setState(() {});
  }

  /// Calculates the position to drop the provided item at.
  void _onMove(DragTargetDetails<DraggedItem<T>> d) {
    if (widget.onWillAccept?.call(d.data.item) == false) {
      return;
    }
    // Get RenderBox of drag&drop zone.
    RenderBox box = dragZone.currentContext!.findRenderObject() as RenderBox;

    // Get position of drag&drop zone.
    Offset position = box.localToGlobal(Offset.zero);

    // Calculate int number where new item will be placed.
    int indexToPlace = ((d.offset.dx -
                position.dx -
                (box.size.width / (items.length + 1)).ceil()) /
            (box.size.width / (items.length + 1)).ceil())
        .ceil();
    if (indexToPlace > items.length) {
      indexToPlace = items.length;
    } else if (indexToPlace < 0) {
      indexToPlace = 0;
    }

    // Save last drag Offset.
    moveDragOffset = Offset(
      d.offset.dx -
          ((startDragConstraints != null && dragged != null)
                  ? startDragConstraints!.maxWidth
                  : itemWidth) /
              2,
      d.offset.dy -
          ((startDragConstraints != null && dragged != null)
                  ? startDragConstraints!.maxHeight
                  : itemWidth) /
              2,
    );

    if (expandBetween < 0) {
      for (var e in items) {
        e.updateCurrentPosition();
      }
    }
    int sameItemIndex =
        items.indexWhere((e) => e.item.toString() == d.data.item.toString());
    if (sameItemIndex >= 0) {
      int sameItemNewIndex = indexToPlace;
      if (sameItemIndex < sameItemNewIndex) sameItemNewIndex--;

      positionOnSameItem = items[sameItemNewIndex].position;
      constraintsOnSameItem = items[sameItemNewIndex].constraints;
    }

    expandBetween = indexToPlace;

    setState(() {});
  }

  /// Resets items animations.
  void _resetAnimations() {
    animationsDuration = Duration.zero;
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => Future.delayed(
          Duration.zero, () => animationsDuration = 150.milliseconds),
    );
  }

  /// Shows item overlay.
  void _showOverlay({
    required DraggedItem item,
    required BuildContext context,
    required Offset from,
    required Offset to,
    required BoxConstraints itemConstraints,
    required Function onEnd,
    BoxConstraints? endConstraints,
  }) async {
    var overlayEntry = OverlayEntry(
      builder: (context) => _OverlayBlock(
        itemBuilder: widget.itemBuilder,
        item: item,
        from: from,
        to: to,
        itemConstraints: itemConstraints,
        animationDuration: movingAnimationDuration,
        endConstraints: endConstraints,
      ),
    );

    overlays.add(overlayEntry);
    Overlay.of(context)!.insert(overlayEntry);

    await Future.delayed(movingAnimationDuration);

    overlayEntry.remove();
    overlays.remove(overlayEntry);
    onEnd();
  }
}

/// Dragged item data.
class DraggedItem<T> {
  DraggedItem(this.item);

  /// Dragged item.
  T item;

  /// [GlobalKey] of item.
  GlobalKey key = GlobalKey();

  /// [GlobalKey] reserve key of item.
  GlobalKey reserveKey = GlobalKey();

  /// [GlobalKey] of divider.
  GlobalKey dividerKey = GlobalKey();

  /// [Offset] position of this item.
  Offset? position;

  /// [BoxConstraints] constraints of this item.
  BoxConstraints? constraints;

  /// Indicator whether item should be hidden or not.
  bool hide = false;

  /// Updates [position] and [constraints].
  void updateCurrentPosition() {
    RenderBox? box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null) {
      position = box.localToGlobal(Offset.zero);
      constraints = box.constraints;
    }
  }
}

/// Overlay block of item.
class _OverlayBlock extends StatefulWidget {
  const _OverlayBlock({
    Key? key,
    required this.itemBuilder,
    required this.item,
    required this.from,
    required this.to,
    required this.itemConstraints,
    required this.animationDuration,
    this.endConstraints,
  }) : super(key: key);

  /// [DraggedItem] of this overlay.
  final DraggedItem item;

  /// Start [Offset] place of this overlay.
  final Offset from;

  /// Final [Offset] place of this overlay.
  final Offset to;

  /// Start size of item.
  final BoxConstraints itemConstraints;

  /// Final item size.
  final BoxConstraints? endConstraints;

  /// Builder of item.
  final ButtonsDockBuilderFunction itemBuilder;

  /// Duration of animation.
  final Duration animationDuration;

  @override
  State<_OverlayBlock> createState() => _OverlayBlockState();
}

/// State of [_OverlayBlock], used to play animation.
class _OverlayBlockState extends State<_OverlayBlock> {
  /// Offset of this widget.
  late Offset offset = widget.from;

  /// Size of item.
  late BoxConstraints constraints = widget.itemConstraints;

  @override
  void initState() {
    Future.delayed(Duration.zero).whenComplete(() => setState(() {
          offset = widget.to;
          if (widget.endConstraints != null &&
              widget.endConstraints != constraints) {
            constraints = widget.endConstraints!;
          }
        }));
    super.initState();
  }

  @override
  Widget build(BuildContext context) => AnimatedPositioned(
        duration: widget.animationDuration,
        left: offset.dx,
        top: offset.dy,
        curve: Curves.ease,
        child: AnimatedContainer(
          duration: widget.animationDuration,
          constraints: constraints,
          child: KeyedSubtree(
            child: widget.itemBuilder(context, widget.item),
            key: widget.item.key,
          ),
        ),
      );
}

/// Container changes width with animation.
class AnimatedWidth extends StatefulWidget {
  const AnimatedWidth({
    Key? key,
    required this.beginWidth,
    required this.endWidth,
    required this.duration,
    this.child,
  }) : super(key: key);

  /// [Duration] of animation.
  final Duration duration;

  /// Initial width of [child].
  final double beginWidth;

  /// Target width of [child] to animate.
  final double endWidth;

  /// Child [Widget].
  final Widget? child;

  @override
  State<AnimatedWidth> createState() => _AnimatedWidthState();
}

/// State of [AnimatedWidth] used to keep track of [width].
class _AnimatedWidthState extends State<AnimatedWidth> {
  /// Scale of this [_AnimatedDelayedScaleState].
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
      child: widget.child,
    );
  }
}
