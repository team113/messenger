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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

/// Item builder function.
typedef ButtonsDockBuilderFunction = Function(
  BuildContext context,
  DraggedItem item,
);

/// Buttons dock in call.
class ReorderableDock<T> extends StatefulWidget {
  const ReorderableDock({
    required this.items,
    required this.onReorder,
    required this.itemBuilder,
    required this.itemConstraints,
    this.onDragStarted,
    this.onDragEnded,
    Key? key,
  }) : super(key: key);

  /// Items this [ReorderableDock] reorders.
  final List<T> items;

  /// Builder building the [items].
  final ButtonsDockBuilderFunction itemBuilder;

  /// Callback, called when the [items] were reordered.
  final Function(List)? onReorder;

  /// Callback, called when any drag of [items] is started.
  final Function()? onDragStarted;

  /// Callback, called when any drag of [items] is ended.
  final Function()? onDragEnded;

  /// [BoxConstraints] of item.
  final BoxConstraints itemConstraints;

  @override
  State<ReorderableDock> createState() => _ReorderableDockState();
}

/// State of [ReorderableDock].
class _ReorderableDockState extends State<ReorderableDock> {
  /// Duration of animation moving button to his place on end of dragging.
  Duration animationMovingDuration = const Duration(milliseconds: 400);

  /// List of items.
  List<DraggedItem> items = [];

  /// Duration of [AnimatedContainer] width changing.
  Duration animationsDuration = 150.milliseconds;

  /// Place where item will be placed.
  int expandBetween = -1;

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

  /// Indicator whether some item is moving now  or not.
  bool isMovingIconNow = false;

  /// List of overlays.
  List<OverlayEntry> overlays = [];

  /// Overlay item used in animations.
  late OverlayEntry overlayEntry;

  /// Returns item width.
  double get itemWidth => (items.first.key.currentState == null ||
          items.first.key.currentState?.mounted == false ||
          items.first.key.currentContext?.size == null)
      ? widget.itemConstraints.maxWidth
      : items.first.key.currentContext!.size!.width;

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
                          ? widget.itemConstraints.maxWidth
                          : startDragConstraints!.maxWidth
                      : 0,
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
                  constraints: widget.itemConstraints,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: LayoutBuilder(
                        builder: (c, constraints) => (isMovingIconNow &&
                                expandBetween != i)
                            ? Opacity(
                                opacity: (e.hide) ? 0 : 1,
                                child: KeyedSubtree(
                                    key: (e.hide) ? e.reserveKey : e.key,
                                    child: widget.itemBuilder(context, e)),
                              )
                            : Draggable(
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
                                  widget.onDragStarted?.call();

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
                                  isMovingIconNow = true;
                                  // Show animation of dragged item returns to its
                                  // start position.
                                  _showOverlay(
                                      dragged!,
                                      context,
                                      Offset(
                                        o.dx -
                                            startDragConstraints!.maxWidth / 2,
                                        o.dy -
                                            startDragConstraints!.maxHeight / 2,
                                      ),
                                      startDragOffset!,
                                      startDragConstraints!,
                                      () => setState(() {
                                            items[savedDraggedIndex].hide =
                                                false;
                                            isMovingIconNow = false;
                                            widget.onDragEnded?.call();
                                          }));

                                  // Insert dragged item to items list.
                                  items.insert(draggedIndex, dragged!);

                                  // Hide recently added item.
                                  items[draggedIndex].hide = true;

                                  expandBetween = -1;
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
                        ? widget.itemConstraints.maxWidth
                        : startDragConstraints!.maxWidth
                    : 0,
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

    return DragTarget(
      key: dragZone,
      onAccept: _onAccept,
      onMove: _onMove,
      onLeave: (a) => setState(() => expandBetween = -1),
      builder: _builder,
    );
  }

  /// Adds the provided [item] to the [items] list and animates the addition.
  void _onAccept(DraggedItem item) {
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

      // Save expandBetween integer.
      int whereToPlace = expandBetween;

      // Reset expandBetween.
      expandBetween = -1;

      // OverlayEntry that will display dragged item at onDragEnded place.
      OverlayEntry overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          left: moveDragOffset!.dx,
          top: moveDragOffset!.dy,
          child: KeyedSubtree(
            key: item.key,
            child: widget.itemBuilder(context, item),
          ),
        ),
      );

      // Insert OverlayEntry to Overlay to display him.
      overlayState?.insert(overlayEntry);

      // Hide added item.
      items[whereToPlace].hide = true;

      // Reset animations.
      setState(_resetAnimations);

      // Remove OverlayEntry with item from Overlay.
      overlayEntry.remove();

      // Save dragged item.
      var localDragged = dragged;

      // Post frame callBack to display animation of adding item to items
      // list.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Get RenderBox of recently added item.
        RenderBox box = items[whereToPlace]
            .reserveKey
            .currentContext!
            .findRenderObject() as RenderBox;

        // Get position of recently added item.
        Offset position = box.localToGlobal(Offset.zero);

        isMovingIconNow = true;

        // Display animation of adding item.
        _showOverlay(
          item,
          context,
          moveDragOffset!,
          position,
          startDragConstraints != null && localDragged != null
              ? startDragConstraints!
              : widget.itemConstraints,
          () => setState(() {
            isMovingIconNow = false;
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
      // Get integer position of same item.
      int i =
          items.indexWhere((e) => e.item.toString() == item.item.toString());
      if (i == expandBetween || i + 1 == expandBetween) {
        return setState(() => expandBetween = -1);
      }

      OverlayEntry? overlayEntry;
      Offset? startPosition;

      // Get RenderBox of same item.
      RenderBox box = items
          .firstWhere((e) => e.item.toString() == item.item.toString())
          .key
          .currentContext!
          .findRenderObject() as RenderBox;

      // Get Offset position of same item.
      startPosition = box.localToGlobal(Offset.zero);

      // OverlayEntry with item that will be showed until animation
      // started.
      overlayEntry = OverlayEntry(
          builder: (context) => Positioned(
                left: startPosition!.dx,
                top: startPosition.dy,
                child: Opacity(
                  key: item.key,
                  opacity: 1,
                  child: widget.itemBuilder(context, item),
                ),
              ));

      // Add OverlayEntry to Overlay.
      overlayState!.insert(overlayEntry);

      // Add GlobalKey's to item and item's divider.
      item.key = GlobalKey();
      item.dividerKey = GlobalKey();
      item.reserveKey = GlobalKey();

      // Remove same item.
      items.removeAt(i);

      // Save integer number of place where item will be added.
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
      setState(() {});

      // Remove OverlayEntry from Overlay.
      overlayEntry.remove();

      // Post frame callBack to show animation of sliding item from old
      // place to new place.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        isMovingIconNow = true;
        // Display animation of sliding item from old place to new place.
        _showOverlay(
            item,
            context,
            startPosition!,
            positionOnSameItem!,
            constraintsOnSameItem!,
            () => setState(() {
                  items[whereToPlace].hide = false;
                  widget.onDragEnded?.call();
                  isMovingIconNow = false;
                }));
      });
    }

    dragged = null;
    widget.onReorder?.call(items.map((e) => e.item).toList());
    expandBetween = -1;

    setState(() {});
  }

  /// Calculates the position to drop the provided item at, if any.
  void _onMove(DragTargetDetails<DraggedItem> d) {
    // Get RenderBox of drag&drop zone.
    RenderBox box = dragZone.currentContext!.findRenderObject() as RenderBox;

    // Get position of drag&drop zone.
    Offset position = box.localToGlobal(Offset.zero);

    // Calculate int number where new item will be placed.
    int intToPlace = ((d.offset.dx -
                position.dx -
                (box.size.width / (items.length + 1)).ceil()) /
            (box.size.width / (items.length + 1)).ceil())
        .ceil();
    if (intToPlace > items.length) {
      intToPlace = items.length;
    } else if (intToPlace < 0) {
      intToPlace = 0;
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
    int sameItemId =
        items.indexWhere((e) => e.item.toString() == d.data.item.toString());
    if (sameItemId >= 0) {
      int sameItemNewId = intToPlace;
      if (sameItemId < sameItemNewId) sameItemNewId--;

      positionOnSameItem = items[sameItemNewId].position;
      constraintsOnSameItem = items[sameItemNewId].constraints;
    }

    expandBetween = intToPlace;

    setState(() {});
  }

  /// Resets items animations.
  void _resetAnimations() {
    Duration oldAnimationsDuration = animationsDuration;
    animationsDuration = Duration.zero;
    SchedulerBinding.instance.addPostFrameCallback((timeStamp) =>
        Future.delayed(
            Duration.zero, () => animationsDuration = oldAnimationsDuration));
  }

  /// Shows item overlay.
  void _showOverlay(
    DraggedItem item,
    BuildContext context,
    Offset from,
    Offset to,
    BoxConstraints itemConstraints,
    Function onEnd, {
    BoxConstraints? endConstraints,
  }) async {
    overlayEntry = OverlayEntry(
      builder: (context) => _OverlayBlock(
        widget.itemBuilder,
        item,
        from,
        to,
        itemConstraints,
        animationMovingDuration,
        overlayEntry,
        onEnd,
        endConstraints: endConstraints,
      ),
    );

    overlays.add(overlayEntry);

    Overlay.of(context)!.insert(overlayEntry);
  }
}

/// Dragged item class.
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
  const _OverlayBlock(
    this.itemBuilder,
    this.item,
    this.from,
    this.to,
    this.itemConstraints,
    this.animationDuration,
    this.overlay,
    this.onEnd, {
    this.endConstraints,
  });

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

  /// Overlay of this block.
  final OverlayEntry overlay;

  /// Callback called when animation is ended.
  final Function onEnd;

  @override
  State<_OverlayBlock> createState() => _OverlayBlockState();
}

/// State of [_OverlayBlock].
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
        onEnd: () {
          widget.onEnd.call();
          widget.overlay.remove();
        },
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
