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

import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:dough/dough.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '/ui/page/home/widget/gallery_popup.dart';

/// Placing [children] evenly on a screen with an ability to reorder them.
///
/// Layout depends on the provided [axis].
///
/// [left] or [right], [top] or [bottom], [width] and [height] should be
/// specified only if this [ReorderableFit] should take a portion of the screen.
/// Otherwise, the whole available space will be occupied.
class ReorderableFit<T extends Object> extends StatelessWidget {
  const ReorderableFit({
    Key? key,
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
    this.allowDraggingLast = true,
    this.hoverColor = const Color(0x00000000),
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
  }) : super(key: key);

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

  /// Indicator whether dragging allowed when only one item present.
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
  final Color hoverColor;

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
          onAccept: (o) => onAdded?.call(o, 0),
          onWillAccept: (b) => onWillAccept?.call(b) ?? true,
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

            if (diagonal < min) {
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
        );
      }),
    );
  }
}

/// Stateful component of a [ReorderableFit].
class _ReorderableFit<T extends Object> extends StatefulWidget {
  const _ReorderableFit({
    Key? key,
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
    this.hoverColor = const Color(0x00000000),
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
  }) : super(key: key);

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

  /// Indicator whether dragging allowed when only one item present.
  final bool allowDraggingLast;

  /// Hover color of the [DragTarget].
  final Color hoverColor;

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

  /// [AudioPlayer] playing a pop sound.
  AudioPlayer? _audioPlayer;

  /// [_ReorderableItem] being dragged that has already broke its dough.
  _ReorderableItem<T>? _doughDragged;

  @override
  void initState() {
    _items = widget.children.map((e) => _ReorderableItem(e)).toList();
    _initAudio();
    super.initState();
  }

  @override
  void dispose() {
    _audioPlayer?.dispose();
    [AudioCache.instance.loadedFiles['audio/pop.mp3']]
        .whereNotNull()
        .forEach(AudioCache.instance.clear);

    super.dispose();
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
    Widget _cell(int index) {
      var item = _items[index];
      return Stack(
        children: [
          if (widget.decoratorBuilder != null)
            widget.decoratorBuilder!.call(item.item),
          KeyedSubtree(
            key: item.key,
            child: item.entry != null
                ? SizedBox(
                    width: widget.wrapSize,
                    height: widget.wrapSize,
                  )
                : _ReorderableDraggable<T>(
                    item: item.item,
                    itemBuilder: widget.itemBuilder,
                    useLongPress: widget.useLongPress,
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
                      item.dragStartedRect = item.key.globalPaintBounds;
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
                      _audioPlayer?.play(
                        AssetSource('audio/pop.mp3'),
                        volume: 0.3,
                        position: Duration.zero,
                        mode: PlayerMode.lowLatency,
                      );
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
                            ? const Color(0x00000000)
                            : widget.hoverColor,
                      ),
                    );
                  },
                  onLeave: widget.onLeave,
                  onWillAccept: (b) {
                    if (b != item.item &&
                        (widget.onWillAccept?.call(b) ?? true)) {
                      int i = _items.indexWhere((e) => e.item == b);
                      if (i != -1) {
                        _onWillAccept(b!, index, i);
                      }

                      return true;
                    }

                    return false;
                  },
                  onAccept: (o) => _onAccept(o, index, index),
                ),
              ),
              Expanded(
                child: DragTarget<T>(
                  builder: (context, candidates, rejected) {
                    return IgnorePointer(
                      child: Container(
                        color: candidates.isEmpty
                            ? const Color(0x00000000)
                            : widget.hoverColor,
                      ),
                    );
                  },
                  onLeave: widget.onLeave,
                  onWillAccept: (b) {
                    if (b != item.item &&
                        (widget.onWillAccept?.call(b) ?? true)) {
                      int i = _items.indexWhere((e) => e.item == b);
                      if (i != -1) {
                        _onWillAccept(b!, index, i);
                      }

                      return true;
                    }

                    return false;
                  },
                  onAccept: (o) => _onAccept(o, index, index + 1),
                ),
              ),
            ],
          ),
          if (widget.overlayBuilder != null)
            widget.overlayBuilder!.call(item.item),
        ],
      );
    }

    /// Creates a column of a row at [rowIndex] index.
    List<Widget> _createColumn(int rowIndex) {
      final List<Widget> column = [];

      for (int columnIndex = 0; columnIndex < widget.mColumns; columnIndex++) {
        final cellIndex = rowIndex * widget.mColumns + columnIndex;
        if (cellIndex <= _items.length - 1) {
          column.add(Expanded(child: _cell(cellIndex)));
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
    List<Widget> _createRows() {
      final List<Widget> rows = [];
      final rowCount = (_items.length / widget.mColumns).ceil();

      for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) {
        final List<Widget> column = _createColumn(rowIndex);
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
                onAccept: (o) => _onAccept(o, _items.length, _items.length),
                onLeave: widget.onLeave,
                onWillAccept: (o) =>
                    !_items.contains(o) &&
                    (widget.onWillAccept?.call(o) ?? true),
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
                              child: _cell(i),
                            ),
                          )
                          .toList(),
                    )
                  : Column(children: _createRows()),
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

  /// Reorders the [object] from [i] into [to] position, if [_items] contains
  /// the item, otherwise just marks its position.
  void _onWillAccept(T object, int i, int to) {
    int index = _items.indexWhere((e) => e.item == object);
    if (index != -1) {
      var from = _items[i];
      var to = _items[index];

      var beginRect = from.key.globalPaintBounds!;
      var endRect = to.key.globalPaintBounds!;

      if (beginRect != endRect) {
        Offset offset = widget.onOffset?.call() ?? Offset.zero;
        beginRect = beginRect.shift(offset);
        endRect = endRect.shift(offset);

        if (from.entry != null && from.entryKey.currentState != null) {
          from.entryKey.currentState!.setState(() {
            from.entryKey.currentState!.rect = endRect;
          });
        } else {
          from.entry = OverlayEntry(builder: (context) {
            return _AnimatedTransition(
              key: from.entryKey,
              beginRect: beginRect,
              endRect: endRect,
              onEnd: () {
                setState(() => from.entry = null);
              },
              child: widget.itemBuilder(from.item),
            );
          });
        }
      }

      _items[i] = to;
      _items[index] = from;

      widget.onReorder?.call(object, i);
    } else {
      _positions[object.hashCode] = to;
      widget.onAdded?.call(object, to);
    }

    setState(() {});
  }

  /// Constructs a returning [OverlayEntry] animation of the [to] item.
  void _animateReturn(_ReorderableItem<T> to, Offset d) {
    if (to.dragStartedRect == null) return;

    var beginRect = to.dragStartedRect ?? to.key.globalPaintBounds!;
    var endRect = to.key.globalPaintBounds!;

    beginRect = Rect.fromLTRB(
      d.dx,
      d.dy,
      (d.dx - beginRect.left) + beginRect.right,
      (d.dy - beginRect.top) + beginRect.bottom,
    );

    if (beginRect != endRect) {
      Offset offset = widget.onOffset?.call() ?? Offset.zero;
      beginRect = beginRect.shift(offset);
      endRect = endRect.shift(offset);

      if (to.entry != null && to.entryKey.currentState != null) {
        to.entryKey.currentState!.setState(() {
          to.entryKey.currentState!.rect = endRect;
        });
      } else {
        to.entry = OverlayEntry(builder: (context) {
          return _AnimatedTransition(
            key: to.entryKey,
            curve: Curves.linearToEaseOut,
            beginRect: beginRect,
            endRect: endRect,
            onEnd: () {
              setState(() => to.entry = null);
            },
            child: widget.itemBuilder(to.item),
          );
        });
      }

      setState(() {});
    }
  }

  /// Initializes the [_audioPlayer].
  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer(playerId: 'reorderableFitWrap');
      await AudioCache.instance.loadAll(['audio/pop.mp3']);
    } on MissingPluginException {
      _audioPlayer = null;
    }
  }
}

/// [_ReorderableItem] wrapped in a [DraggableDough].
class _ReorderableDraggable<T extends Object> extends StatefulWidget {
  const _ReorderableDraggable({
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

  /// Item stored in this [_ReorderableDraggable].
  final T item;

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

  @override
  State<_ReorderableDraggable<T>> createState() => _ReorderableDraggableState<T>();
}

class _ReorderableDraggableState<T extends Object> extends State<_ReorderableDraggable<T>> {
  /// Indicator whether dragging is started.
  bool isDragged = false;

  @override
  Widget build(BuildContext context) {
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
          var child = widget.itemBuilder(widget.item);
          return DraggableDough<T>(
            data: widget.item,
            longPress: widget.useLongPress,
            maxSimultaneousDrags: widget.enabled ? 1 : 0,
            onDragEnd: (d) {
              widget.onDragEnd?.call(d.offset);
              isDragged = false;
            },
            onDragStarted: () {
              widget.onDragStarted?.call();
              HapticFeedback.lightImpact();
              isDragged = true;
            },
            onDragCompleted: widget.onDragCompleted,
            onDraggableCanceled: (_, d) => widget.onDraggableCanceled?.call(d),
            onDoughBreak: () {
              if (widget.enabled && isDragged) {
                widget.onDoughBreak?.call();
                HapticFeedback.lightImpact();
              }
            },
            feedback: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: KeyedSubtree(
                key: widget.sharedKey,
                child: child,
              ),
            ),
            childWhenDragging: KeyedSubtree(
              key: widget.sharedKey,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.transparent,
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

/// Data of an [Object] used in a [_ReorderableFit] to be reordered around.
class _ReorderableItem<T> {
  _ReorderableItem(this.item);

  /// Reorderable [Object] itself.
  final T item;

  /// [GlobalKey] of this [_ReorderableItem] representing the global position of
  /// this [item].
  final GlobalKey key = GlobalKey();

  /// [UniqueKey] of this [_ReorderableItem] representing the position in a
  /// [_ReorderableFit] of this [item].
  final UniqueKey sharedKey = UniqueKey();

  /// [GlobalKey] of the [entry].
  final GlobalKey<_AnimatedTransitionState> entryKey =
      GlobalKey<_AnimatedTransitionState>();

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

/// Animated transform of the provided [child] from the [beginRect] to the
/// [endRect].
class _AnimatedTransition extends StatefulWidget {
  const _AnimatedTransition({
    Key? key,
    required this.beginRect,
    required this.endRect,
    required this.child,
    this.onEnd,
    this.curve,
  }) : super(key: key);

  /// Initial [Rect] this [child] takes.
  final Rect beginRect;

  /// Target [Rect] to animate this [child] to.
  final Rect endRect;

  /// Callback, called when animation ends.
  final VoidCallback? onEnd;

  /// [Widget] to transform around.
  final Widget child;

  /// [Curve] of animation.
  final Curve? curve;

  @override
  State<_AnimatedTransition> createState() => _AnimatedTransitionState();
}

/// State of an [_AnimatedTransition] changing the [rect].
class _AnimatedTransitionState extends State<_AnimatedTransition>
    with SingleTickerProviderStateMixin {
  /// [Rect] that [_AnimatedTransition.child] occupies.
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
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedPositioned.fromRect(
          rect: rect,
          duration: const Duration(milliseconds: 200),
          curve: widget.curve ?? Curves.linear,
          onEnd: widget.onEnd,
          child: widget.child,
        ),
      ],
    );
  }
}
