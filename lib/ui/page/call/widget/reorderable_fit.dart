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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:dough/dough.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/themes.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/util/audio_utils.dart';
import 'animated_transition.dart';

/// Placing [children] evenly on a screen with an ability to reorder them.
///
/// Layout depends on the provided [axis].
///
/// [left] or [right], [top] or [bottom], [width] and [height] should be
/// specified only if this [ReorderableFit] should take a portion of the screen.
/// Otherwise, the whole available space will be occupied.
class ReorderableFit<T extends Object> extends StatelessWidget {
  const ReorderableFit({
    super.key,
    required this.children,
    required this.itemBuilder,
    this.decoratorBuilder,
    this.overlayBuilder,
    this.dividerColor,
    this.dividerSize = 1,
    this.onReorder,
    this.onAdded,
    this.onDragStarted,
    this.onDoughBreak,
    this.onDragEnd,
    this.onDragCompleted,
    this.onDraggableCanceled,
    this.hoverColor,
    this.axis,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.width,
    this.height,
    this.onWillAccept,
    this.onLeave,
    this.onOffset,
    this.useLongPress = false,
    this.allowEmptyTarget = false,
    this.allowDraggingLast = true,
    this.itemConstraints,
    this.borderRadius,
  });

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Builder decorating the provided item.
  final Widget Function(T data)? decoratorBuilder;

  /// Builder creating overlay of the provided item.
  final Widget Function(T data)? overlayBuilder;

  /// Indicator whether a [LongPressDraggable] should be used instead of a
  /// [Draggable].
  final bool useLongPress;

  /// Indicator whether the [DragTarget] should be allowed when [children] are
  /// empty.
  final bool allowEmptyTarget;

  /// Children widgets needed to be placed in a [Wrap].
  final List<T> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  /// Size of a divider between [children].
  final double dividerSize;

  /// Callback, specifying a [BoxConstraints] of an item when it's dragged.
  final BoxConstraints? Function(T)? itemConstraints;

  /// Callback, called when an item is reordered.
  final Function(T, int)? onReorder;

  /// Callback, called when a new item is added.
  final Function(T, int)? onAdded;

  /// Callback, called when item dragging is started.
  final Function(T)? onDragStarted;

  /// Callback, called when an item breaks its dough.
  final void Function(T)? onDoughBreak;

  /// Callback, called when item dragging is ended.
  final Function(T)? onDragEnd;

  /// Callback, called when an item is accepted by some [DragTarget].
  final Function(T)? onDragCompleted;

  /// Callback, called item dragging is canceled.
  final Function(T)? onDraggableCanceled;

  /// Callback, called when some [DragTarget] may accept the dragged item.
  final bool Function(T?)? onWillAccept;

  /// Callback, called when a dragged item leaves some [DragTarget].
  final void Function(T?)? onLeave;

  /// Callback, specifying an [Offset] of this view.
  final Offset Function()? onOffset;

  /// Indicator whether dragging is allowed when the [children] contain only one
  /// item.
  final bool allowDraggingLast;

  /// Left position of this view.
  final double? left;

  /// Right position of this view.
  final double? right;

  /// Top position of this view.
  final double? top;

  /// Bottom position of this view.
  final double? bottom;

  /// Width of this view to occupy.
  final double? width;

  /// Width of this view to occupy.
  final double? height;

  /// [Axis] to place [children] along.
  ///
  /// If not-`null`, [Wrap] is preferred to be used unless there's not enough
  /// space for all the [children] to be placed along this [Axis].
  final Axis? axis;

  /// Hover color of the [DragTarget].
  final Color? hoverColor;

  /// Optional [BorderRadius] to decorate this [ReorderableFit] with.
  final BorderRadius? borderRadius;

  /// Returns calculated size of a [ReorderableFit] in its [Wrap] form with
  /// [maxSize], [constraints], [axis] and children [length].
  static double calculateSize({
    required double maxSize,
    required Size constraints,
    required Axis axis,
    required int length,
  }) {
    var size = min(
      maxSize,
      axis == Axis.horizontal
          ? constraints.height / length
          : constraints.width / length,
    );

    if (axis == Axis.horizontal) {
      if (size * length >= constraints.height) {
        size = constraints.width / 2;
      }
    } else {
      if (size * length >= constraints.width) {
        size = constraints.height / 2;
      }
    }

    return size;
  }

  /// Indicates whether this [ReorderableFit] should place its [children]
  /// evenly, or use a [Wrap] otherwise.
  static bool useFitView({
    required double maxSize,
    required Size constraints,
    required Axis? axis,
    required int length,
  }) {
    if (axis == null) {
      return true;
    }

    var size = min(
      maxSize,
      axis == Axis.horizontal
          ? constraints.height / length
          : constraints.width / length,
    );

    if (axis == Axis.horizontal) {
      return (size * length >= constraints.height);
    } else {
      return (size * length >= constraints.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      if (allowEmptyTarget) {
        return DragTarget<T>(
          onAcceptWithDetails: (o) => onAdded?.call(o.data, 0),
          onWillAcceptWithDetails: (b) => onWillAccept?.call(b.data) ?? true,
          onLeave: onLeave,
          builder: ((_, __, ___) {
            return SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            );
          }),
        );
      } else {
        return Container();
      }
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        double rWidth = width ?? constraints.maxWidth;
        double rHeight = height ?? constraints.maxHeight;

        double wrapMaxSize = axis == Axis.horizontal ? rWidth : rHeight;
        bool fitView = useFitView(
          maxSize: wrapMaxSize,
          constraints: Size(rWidth, rHeight),
          length: children.length,
          axis: axis,
        );

        // Number of columns.
        int mColumns = 0;

        double? wrapSize;

        if (fitView) {
          // Minimal diagonal of a square.
          double min = double.infinity;

          // To find the [mColumns], iterate through every possible number of
          // columns and pick the arrangement with [min]imal diagonal.
          for (int columns = 1; columns <= children.length; ++columns) {
            int rows = (children.length / columns).ceil();

            // Current diagonal of a single square.
            double diagonal =
                (pow(rWidth / columns, 2) + pow(rHeight / rows, 2)).toDouble();

            // If there's any [children] left outside, then their diagonal will
            // always be bigger, so we need to recalculate.
            int outside = children.length % columns;
            if (outside != 0) {
              // Diagonal of an outside [children] is calculated with some
              // coefficient to force the algorithm to pick non-standard
              // arrangement.
              double coef = 1;

              // Coefficient is hard-coded for some cases in order to [FitView] to
              // look better.
              if (children.length == 3) {
                coef = rWidth > rHeight ? 0.5 : 0.87;
              } else if (children.length == 5) {
                if (rWidth > rHeight) {
                  coef = 0.8;
                } else {
                  coef = outside == 1 ? 0.8 : 1.5;
                }
              } else if (children.length == 10) {
                if (rWidth > rHeight) {
                  coef = outside == 2 ? 0.65 : 0.8;
                } else {
                  coef = 0.8;
                }
              } else if (children.length == 9) {
                if (rWidth > rHeight) {
                  coef = 0.9;
                } else {
                  coef = 0.5;
                }
              } else if (children.length == 8) {
                if (rWidth > rHeight) {
                  coef = outside == 2 ? 0.59 : 0.8;
                } else {
                  coef = 0.8;
                }
              } else if (children.length == 7) {
                if (rWidth > rHeight) {
                  coef = rWidth / rHeight >= 3 ? 0.7 : 0.4;
                } else {
                  coef = 0.4;
                }
              } else if (children.length == 6) {
                if (rWidth > rHeight) {
                  coef = (rWidth / rHeight > 3) ? 0.57 : 0.7;
                } else {
                  coef = 0.7;
                }
              } else {
                if (rWidth > rHeight) {
                  coef = outside == 2 ? 0.59 : 0.77;
                } else {
                  coef = 0.6;
                }
              }

              diagonal =
                  (pow(rWidth / outside * coef, 2) + pow(rHeight / rows, 2))
                      .toDouble();
            }
            // Tweak of a standard arrangement.
            else if (children.length == 4) {
              mColumns = rWidth / rHeight < 0.56 ? 1 : mColumns;
            }

            if (diagonal < min && min - diagonal > 1) {
              mColumns = columns;
              min = diagonal;
            }
          }
        }

        if (axis != null) {
          wrapSize = calculateSize(
            maxSize: wrapMaxSize,
            constraints: Size(rWidth, rHeight),
            length: children.length,
            axis: axis!,
          );
        }

        return _ReorderableFit<T>(
          key: key,
          children: children,
          itemBuilder: itemBuilder,
          decoratorBuilder: decoratorBuilder,
          overlayBuilder: overlayBuilder,
          mColumns: mColumns,
          wrapSize: wrapSize,
          dividerColor: dividerColor,
          dividerSize: dividerSize,
          onReorder: onReorder,
          onAdded: onAdded,
          onDoughBreak: onDoughBreak,
          onDragCompleted: onDragCompleted,
          onDragEnd: onDragEnd,
          onDragStarted: onDragStarted,
          onDraggableCanceled: onDraggableCanceled,
          hoverColor: hoverColor,
          useWrap: !fitView,
          axis: axis,
          left: left,
          right: right,
          top: top,
          bottom: bottom,
          width: width,
          height: height,
          onLeave: onLeave,
          onWillAccept: onWillAccept,
          onOffset: onOffset,
          useLongPress: useLongPress,
          allowDraggingLast: allowDraggingLast,
          itemConstraints: itemConstraints,
          borderRadius: borderRadius,
        );
      }),
    );
  }
}

/// Stateful component of a [ReorderableFit].
class _ReorderableFit<T extends Object> extends StatefulWidget {
  const _ReorderableFit({
    super.key,
    required this.children,
    required this.itemBuilder,
    this.decoratorBuilder,
    this.overlayBuilder,
    required this.mColumns,
    this.dividerColor,
    this.dividerSize = 1,
    this.onReorder,
    this.onAdded,
    this.onDragStarted,
    this.onDoughBreak,
    this.onDragEnd,
    this.onDragCompleted,
    this.onDraggableCanceled,
    this.hoverColor,
    this.wrapSize,
    this.axis,
    this.width,
    this.height,
    this.left,
    this.right,
    this.top,
    this.bottom,
    this.useWrap = false,
    this.onLeave,
    this.onWillAccept,
    this.onOffset,
    this.useLongPress = false,
    this.allowDraggingLast = true,
    this.itemConstraints,
    this.borderRadius,
  });

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Builder decorating the provided item.
  final Widget Function(T data)? decoratorBuilder;

  /// Builder creating overlay of the provided item.
  final Widget Function(T data)? overlayBuilder;

  /// Indicator whether a [LongPressDraggable] should be used instead of a
  /// [Draggable].
  final bool useLongPress;

  /// Children widgets needed to be placed evenly on a screen.
  final List<T> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  /// Size of a divider between [children].
  final double dividerSize;

  /// Callback, specifying a [BoxConstraints] of an item when it's dragged.
  final BoxConstraints? Function(T)? itemConstraints;

  /// Callback, called when an item is reordered.
  final Function(T, int)? onReorder;

  /// Callback, called when a new item is added.
  final Function(T, int)? onAdded;

  /// Callback, called when item dragging is started.
  final Function(T)? onDragStarted;

  /// Callback, called when an item breaks its dough.
  final void Function(T)? onDoughBreak;

  /// Callback, called when item dragging is ended.
  final Function(T)? onDragEnd;

  /// Callback, called when an item is accepted by some [DragTarget].
  final Function(T)? onDragCompleted;

  /// Callback, called item dragging is canceled.
  final Function(T)? onDraggableCanceled;

  /// Callback, called when some [DragTarget] may accept the dragged item.
  final bool Function(T?)? onWillAccept;

  /// Callback, called when a dragged item leaves some [DragTarget].
  final void Function(T?)? onLeave;

  /// Callback, specifying an [Offset] of this view.
  final Offset Function()? onOffset;

  /// Indicator whether dragging is allowed when the [children] contain only one
  /// item.
  final bool allowDraggingLast;

  /// Hover color of the [DragTarget].
  final Color? hoverColor;

  /// Left position of this view.
  final double? left;

  /// Right position of this view.
  final double? right;

  /// Top position of this view.
  final double? top;

  /// Bottom position of this view.
  final double? bottom;

  /// Width of this view to occupy.
  final double? width;

  /// Width of this view to occupy.
  final double? height;

  /// Number of [Column]s to place the [children] onto.
  final int mColumns;

  /// Size of a [Wrap] of this [_ReorderableFit].
  final double? wrapSize;

  /// [Axis] to place the [children] along.
  final Axis? axis;

  /// Indicator whether this [_ReorderableFit] should use a [Wrap].
  final bool useWrap;

  /// Optional [BorderRadius] to decorate this [_ReorderableFit] with.
  final BorderRadius? borderRadius;

  @override
  State<_ReorderableFit<T>> createState() => _ReorderableFitState<T>();
}

/// State of a [_ReorderableFit] maintaining the reorderable [_items] list.
class _ReorderableFitState<T extends Object> extends State<_ReorderableFit<T>> {
  /// [_ReorderableItem]s of this [_ReorderableFit].
  late final List<_ReorderableItem<T>> _items;

  /// Positions of [_items].
  final Map<int, int> _positions = {};

  /// [GlobalKey] of this [_ReorderableFit].
  final GlobalKey _fitKey = GlobalKey();

  /// [_ReorderableItem] being dragged that has already broke its dough.
  _ReorderableItem<T>? _doughDragged;

  @override
  void initState() {
    _items = widget.children.map((e) => _ReorderableItem(e)).toList();
    AudioUtils.ensureInitialized();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _ReorderableFit<T> oldWidget) {
    for (var r in List<_ReorderableItem<T>>.from(_items, growable: false)) {
      if (!widget.children.contains(r.item)) {
        _items.remove(r);
        _positions.remove(r.hashCode);
      }
    }

    for (var r in widget.children) {
      if (!_items.any((e) => e.hashCode == r.hashCode)) {
        int? index = _positions[r.hashCode];
        if (index != null && index < _items.length) {
          _items.insert(index, _ReorderableItem(r));
          _positions.remove(r.hashCode);
        } else {
          _items.add(_ReorderableItem(r));
        }
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    /// Returns a visual representation of the [_ReorderableItem] with provided
    /// [index].
    Widget cell(int index, [bool withOverlay = true]) {
      final style = Theme.of(context).style;

      var item = _items[index];
      return Stack(
        children: [
          if (widget.decoratorBuilder != null)
            widget.decoratorBuilder!.call(item.item),
          KeyedSubtree(
            key: item.cellKey,
            child: item.entry != null
                ? SizedBox(
                    width: widget.wrapSize,
                    height: widget.wrapSize,
                  )
                : _ReorderableDraggable<T>(
                    item: item.item,
                    itemBuilder: (o) => KeyedSubtree(
                      key: item.itemKey,
                      child: widget.itemBuilder(o),
                    ),
                    itemConstraints: widget.itemConstraints,
                    useLongPress: widget.useLongPress,
                    cellKey: item.cellKey,
                    sharedKey: item.sharedKey,
                    enabled:
                        _items.map((e) => e.entry).whereNotNull().isEmpty &&
                            (widget.allowDraggingLast || _items.length != 1),
                    onDragEnd: (d) {
                      widget.onDragEnd?.call(item.item);
                      if (_doughDragged != null) {
                        _animateReturn(item, d);
                        _doughDragged = null;
                      }
                    },
                    onDragStarted: () {
                      item.dragStartedRect = item.cellKey.globalPaintBounds;
                      widget.onDragStarted?.call(item.item);
                    },
                    onDragCompleted: () =>
                        widget.onDragCompleted?.call(item.item),
                    onDraggableCanceled: (d) {
                      widget.onDraggableCanceled?.call(item.item);
                      if (_doughDragged != null) {
                        _animateReturn(item, d);
                        _doughDragged = null;
                      }
                    },
                    onDoughBreak: () {
                      _doughDragged = item;
                      widget.onDoughBreak?.call(item.item);
                      AudioUtils.once(AudioSource.asset('audio/pop.mp3'));
                    },
                  ),
          ),
          Row(
            children: [
              Expanded(
                child: DragTarget<T>(
                  builder: (context, candidates, rejected) {
                    return IgnorePointer(
                      child: Container(
                        color: candidates.isEmpty
                            ? style.colors.transparent
                            : widget.hoverColor ?? style.colors.transparent,
                      ),
                    );
                  },
                  onLeave: widget.onLeave,
                  onMove: (b) {
                    // Reorder the items, if it is [_doughDragged] and accepted.
                    if (_doughDragged?.item == b.data &&
                        b.data != item.item &&
                        (widget.onWillAccept?.call(b.data) ?? true)) {
                      int i = _items.indexWhere((e) => e.item == b.data);
                      if (i != -1) {
                        _onWillAccept(b.data, index, i);
                      }
                    }
                  },
                  onWillAcceptWithDetails: (b) {
                    if (b != item.item &&
                        (widget.onWillAccept?.call(b.data) ?? true)) {
                      int i = _items.indexWhere((e) => e.item == b);
                      if (i != -1) {
                        // If this item is not the [_doughDragged], then ignore
                        // it.
                        if (_doughDragged?.item != b) {
                          return false;
                        }

                        _onWillAccept(b.data, index, i);
                      }

                      return true;
                    }

                    return false;
                  },
                  onAcceptWithDetails: (o) => _onAccept(o.data, index, index),
                ),
              ),
              Expanded(
                child: DragTarget<T>(
                  builder: (context, candidates, rejected) {
                    return IgnorePointer(
                      child: Container(
                        color: candidates.isEmpty
                            ? style.colors.transparent
                            : widget.hoverColor ?? style.colors.transparent,
                      ),
                    );
                  },
                  onLeave: widget.onLeave,
                  onMove: (b) {
                    // Reorder the items, if it is [_doughDragged] and accepted.
                    if (_doughDragged?.item == b.data &&
                        b.data != item.item &&
                        (widget.onWillAccept?.call(b.data) ?? true)) {
                      int i = _items.indexWhere((e) => e.item == b.data);
                      if (i != -1) {
                        _onWillAccept(b.data, index, i);
                      }
                    }
                  },
                  onWillAcceptWithDetails: (b) {
                    if (b != item.item &&
                        (widget.onWillAccept?.call(b.data) ?? true)) {
                      int i = _items.indexWhere((e) => e.item == b);
                      if (i != -1) {
                        // If this item is not the [_doughDragged], then ignore
                        // it.
                        if (_doughDragged?.item != b) {
                          return false;
                        }

                        _onWillAccept(b.data, index, i);
                      }

                      return true;
                    }

                    return false;
                  },
                  onAcceptWithDetails: (o) =>
                      _onAccept(o.data, index, index + 1),
                ),
              ),
            ],
          ),
          if (withOverlay && widget.overlayBuilder != null)
            widget.overlayBuilder!.call(item.item),
        ],
      );
    }

    /// Creates a column of a row at [rowIndex] index.
    List<Widget> createColumn(int rowIndex, Widget Function(int) builder) {
      final List<Widget> column = [];

      for (int columnIndex = 0; columnIndex < widget.mColumns; columnIndex++) {
        final cellIndex = rowIndex * widget.mColumns + columnIndex;
        if (cellIndex <= _items.length - 1) {
          column.add(Expanded(child: builder(cellIndex)));
          if (widget.dividerColor != null &&
              columnIndex < widget.mColumns - 1 &&
              cellIndex < _items.length - 1) {
            column.add(IgnorePointer(
              child: Container(
                width: widget.dividerSize,
                height: double.infinity,
                color: widget.dividerColor,
              ),
            ));
          }
        }
      }

      return column;
    }

    /// Creates a row of a [_createColumn]s.
    List<Widget> createRows(Widget Function(int) builder) {
      final List<Widget> rows = [];
      final rowCount = (_items.length / widget.mColumns).ceil();

      for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        final List<Widget> column = createColumn(rowIndex, builder);
        rows.add(Expanded(child: Row(children: column)));
        if (widget.dividerColor != null && rowIndex < rowCount - 1) {
          rows.add(IgnorePointer(
            child: Container(
              height: widget.dividerSize,
              width: double.infinity,
              color: widget.dividerColor,
            ),
          ));
        }
      }

      return rows;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height,
      ),
      child: Stack(
        key: _fitKey,
        fit: StackFit.expand,
        children: [
          if (widget.useWrap)
            Positioned(
              left: widget.left,
              top: widget.top,
              right: widget.right,
              bottom: widget.bottom,
              child: DragTarget<T>(
                onAcceptWithDetails: (o) =>
                    _onAccept(o.data, _items.length, _items.length),
                onLeave: widget.onLeave,
                onWillAcceptWithDetails: (o) =>
                    !_items.contains(o.data) &&
                    (widget.onWillAccept?.call(o.data) ?? true),
                builder: (context, candidates, rejected) {
                  return IgnorePointer(
                    ignoring: candidates.isNotEmpty && rejected.isEmpty,
                    child: SizedBox(
                      width: widget.axis == Axis.horizontal
                          ? widget.wrapSize
                          : MediaQuery.of(context).size.width,
                      height: widget.axis == Axis.horizontal
                          ? MediaQuery.of(context).size.height
                          : widget.wrapSize,
                    ),
                  );
                },
              ),
            ),

          Positioned(
            left: widget.left,
            top: widget.top,
            right: widget.right,
            bottom: widget.bottom,
            child: ClipRRect(
              borderRadius: widget.borderRadius ?? BorderRadius.zero,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: widget.useWrap
                    ? Wrap(
                        direction: widget.axis ?? Axis.horizontal,
                        alignment: WrapAlignment.start,
                        runAlignment: WrapAlignment.start,
                        spacing: 0,
                        runSpacing: 0,
                        children: _items
                            .mapIndexed(
                              (i, e) => SizedBox(
                                width: widget.wrapSize,
                                height: widget.wrapSize,
                                child: cell(i, false),
                              ),
                            )
                            .toList(),
                      )
                    : Column(children: createRows((i) => cell(i, false))),
              ),
            ),
          ),

          // Draw the overlay in its own [Wrap]/[Column] to fix double
          // [ClipRRect] bug.
          if (widget.overlayBuilder != null)
            Positioned(
              left: widget.left,
              top: widget.top,
              right: widget.right,
              bottom: widget.bottom,
              child: SizedBox(
                width: widget.width,
                height: widget.height,
                child: widget.useWrap
                    ? Wrap(
                        direction: widget.axis ?? Axis.horizontal,
                        alignment: WrapAlignment.start,
                        runAlignment: WrapAlignment.start,
                        spacing: 0,
                        runSpacing: 0,
                        children: _items
                            .map(
                              (e) => SizedBox(
                                width: widget.wrapSize,
                                height: widget.wrapSize,
                                child: widget.overlayBuilder!(e.item),
                              ),
                            )
                            .toList(),
                      )
                    : Column(
                        children: createRows(
                          (i) => widget.overlayBuilder!(_items[i].item),
                        ),
                      ),
              ),
            ),

          // Pseudo-[Overlay].
          ..._items.map((e) => e.entry).whereNotNull().map(
                (e) => IgnorePointer(
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height,
                    child: e.builder(context),
                  ),
                ),
              ),
        ],
      ),
    );
  }

  /// Adds the provided [object] to the [_items].
  void _onAccept(T object, int i, int to) {
    _positions[object.hashCode] = to;
    widget.onAdded?.call(object, to);
  }

  /// Reorders the [object] from [i] into [to] position.
  void _onWillAccept(T object, int i, int to) {
    final _ReorderableItem<T> start = _items[i];
    final _ReorderableItem<T> end = _items[to];

    Rect beginRect = start.cellKey.globalPaintBounds!;
    Rect endRect = end.cellKey.globalPaintBounds!;

    if (beginRect != endRect) {
      Offset offset = widget.onOffset?.call() ?? Offset.zero;
      beginRect = beginRect.shift(offset);
      endRect = endRect.shift(offset);

      if (start.entry != null && start.entryKey.currentState != null) {
        start.entryKey.currentState?.rect = endRect;
      } else {
        start.entry = OverlayEntry(builder: (context) {
          return AnimatedTransition(
            key: start.entryKey,
            beginRect: beginRect,
            endRect: endRect,
            onEnd: () => setState(() => start.entry = null),
            child: widget.itemBuilder(start.item),
          );
        });
      }
    }

    _items[i] = end;
    _items[to] = start;

    widget.onReorder?.call(object, i);

    setState(() {});
  }

  /// Constructs a returning [OverlayEntry] animation of the [to] item.
  void _animateReturn(_ReorderableItem<T> to, Offset d) {
    if (to.dragStartedRect == null) return;

    Rect beginRect = to.itemKey.globalPaintBounds ??
        to.dragStartedRect ??
        to.cellKey.globalPaintBounds!;
    Rect endRect = to.cellKey.globalPaintBounds!;

    if (beginRect != endRect) {
      Offset offset = widget.onOffset?.call() ?? Offset.zero;
      beginRect = beginRect.shift(offset);
      endRect = endRect.shift(offset);

      if (to.entry != null && to.entryKey.currentState != null) {
        to.entryKey.currentState?.rect = endRect;
      } else {
        to.entry = OverlayEntry(builder: (context) {
          return AnimatedTransition(
            key: to.entryKey,
            curve: Curves.linearToEaseOut,
            beginRect: beginRect,
            endRect: endRect,
            onEnd: () => setState(() => to.entry = null),
            child: widget.itemBuilder(to.item),
          );
        });
      }

      setState(() {});
    }
  }
}

/// [_ReorderableItem] wrapped in a [DraggableDough].
class _ReorderableDraggable<T extends Object> extends StatefulWidget {
  const _ReorderableDraggable({
    super.key,
    required this.item,
    required this.sharedKey,
    required this.cellKey,
    required this.itemBuilder,
    this.onDragEnd,
    this.onDragStarted,
    this.onDragCompleted,
    this.onDraggableCanceled,
    this.onDoughBreak,
    this.useLongPress = false,
    this.enabled = true,
    this.itemConstraints,
  });

  /// Item stored in this [_ReorderableDraggable].
  final T item;

  /// [GlobalKey] of a cell this [_ReorderableDraggable] occupies.
  final GlobalKey cellKey;

  /// [UniqueKey] of this [_ReorderableDraggable].
  final UniqueKey sharedKey;

  /// Builder building the [item].
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

  /// Callback, specifying a [BoxConstraints] of this [_ReorderableDraggable]
  /// when it's dragged.
  final BoxConstraints? Function(T)? itemConstraints;

  @override
  State<_ReorderableDraggable<T>> createState() =>
      _ReorderableDraggableState<T>();
}

/// State of a [_ReorderableDraggable] maintaining the [isDragged] indicator.
class _ReorderableDraggableState<T extends Object>
    extends State<_ReorderableDraggable<T>> {
  /// Indicator whether this [_ReorderableDraggable] is dragged.
  bool _isDragged = false;

  /// Reactive [Offset] of an anchor of this [_ReorderableDraggable] when it's
  /// dragged.
  final Rx<Offset?> _position = Rx(Offset.zero);

  /// Reactive [BoxConstraints] the [_ReorderableDraggable.item] should occupy
  /// passed to a [_Resizable] to animate its changes.
  final Rx<BoxConstraints?> _constraints = Rx(null);

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return DoughRecipe(
      data: DoughRecipeData(
        adhesion: 4,
        viscosity: 2000,
        draggablePrefs: DraggableDoughPrefs(
          breakDistance: 50,
          useHapticsOnBreak: false,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final Widget child = widget.itemBuilder(widget.item);

          return DraggableDough<T>(
            data: widget.item,
            longPress: widget.useLongPress,
            maxSimultaneousDrags: widget.enabled ? 1 : 0,
            onDragEnd: (d) {
              widget.onDragEnd?.call(d.offset);
              _isDragged = false;
            },
            onDragStarted: () {
              _constraints.value = constraints;
              widget.onDragStarted?.call();
              HapticFeedback.lightImpact();
              _isDragged = true;
            },
            dragAnchorStrategy: (
              Draggable<Object> draggable,
              BuildContext context,
              Offset position,
            ) {
              _position.value = position;
              final RenderBox renderObject =
                  context.findRenderObject()! as RenderBox;
              return renderObject.globalToLocal(position);
            },
            onDragCompleted: () {
              widget.onDragCompleted?.call();
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _constraints.value = constraints;
              });
            },
            onDraggableCanceled: (_, d) {
              widget.onDraggableCanceled?.call(d);
              SchedulerBinding.instance.addPostFrameCallback((_) {
                _constraints.value = constraints;
              });
            },
            onDoughBreak: () {
              if (widget.enabled && _isDragged) {
                widget.onDoughBreak?.call();

                final BoxConstraints? itemConstraints =
                    widget.itemConstraints?.call(widget.item);

                if (itemConstraints != null &&
                    itemConstraints.biggest.longestSide <
                        constraints.biggest.longestSide) {
                  final double coefficient = constraints.biggest.longestSide /
                      itemConstraints.biggest.longestSide;

                  _constraints.value = BoxConstraints(
                    maxWidth: constraints.maxWidth / coefficient,
                    maxHeight: constraints.maxHeight / coefficient,
                  );
                } else {
                  _constraints.value = constraints;
                }

                HapticFeedback.lightImpact();
              }
            },
            feedback: _Resizable(
              key: widget.sharedKey,
              cellKey: widget.cellKey,
              layout: constraints,
              position: _position,
              constraints: _constraints,
              child: child,
            ),
            childWhenDragging: KeyedSubtree(
              key: widget.sharedKey,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: style.colors.transparent,
              ),
            ),
            child: KeyedSubtree(
              key: widget.sharedKey,
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// [Widget] animating its size changes from the provided [layout] to the
/// specified reactive [constraints].
class _Resizable extends StatelessWidget {
  const _Resizable({
    super.key,
    required this.cellKey,
    required this.layout,
    required this.position,
    required this.constraints,
    required this.child,
  });

  /// [GlobalKey] of a cell this [_Resizable] occupies.
  final GlobalKey cellKey;

  /// Initial [BoxConstraints] of this [_Resizable].
  final BoxConstraints layout;

  /// [Offset] position of a drag anchor.
  final Rx<Offset?> position;

  /// Target [BoxConstraints] of this [_Resizable] to occupy.
  final Rx<BoxConstraints?> constraints;

  /// [Widget] to animate.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      Offset offset = Offset.zero;
      if (position.value != null && constraints.value != layout) {
        final Rect delta = cellKey.globalPaintBounds ?? Rect.zero;
        final Offset position = Offset(
          this.position.value!.dx - delta.left,
          this.position.value!.dy - delta.top,
        );

        offset = Offset(
          position.dx -
              (constraints.value!.maxWidth * position.dx / layout.maxWidth),
          position.dy -
              (constraints.value!.maxHeight * position.dy / layout.maxHeight),
        );
      }

      return AnimatedContainer(
        duration: 300.milliseconds,
        curve: Curves.ease,
        transform: Matrix4.translationValues(offset.dx, offset.dy, 0),
        width: constraints.value?.maxWidth,
        height: constraints.value?.maxHeight,
        child: child,
      );
    });
  }
}

/// Data of an [Object] used in a [_ReorderableFit] to be reordered around.
class _ReorderableItem<T> {
  _ReorderableItem(this.item);

  /// Reorderable [Object] itself.
  final T item;

  /// [GlobalKey] of a cell this [_ReorderableItem] occupies.
  final GlobalKey cellKey = GlobalKey();

  /// [GlobalKey] of an [item] this [_ReorderableItem] builds.
  final GlobalKey itemKey = GlobalKey();

  /// [UniqueKey] of this [_ReorderableItem] representing the position in a
  /// [_ReorderableFit] of this [item].
  final UniqueKey sharedKey = UniqueKey();

  /// [GlobalKey] of the [entry].
  final GlobalKey<AnimatedTransitionState> entryKey =
      GlobalKey<AnimatedTransitionState>();

  /// [OverlayEntry] of this [_ReorderableItem] used to animate the [item]
  /// changing its position.
  OverlayEntry? entry;

  /// [Rect] of this [item] at the moment when a drag started, used to animate
  /// this [item] returning back.
  Rect? dragStartedRect;

  @override
  int get hashCode => item.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _ReorderableItem<T> && other.item == item;
}
