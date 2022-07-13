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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/ui/page/home/widget/gallery_popup.dart';
import 'reorderable_common.dart';

/// Widget placing its [children] evenly on a screen with an ability to reorder
/// them.
class ReorderableFitView<T extends Object> extends StatelessWidget {
  const ReorderableFitView({
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
    this.onWillAccept,
    this.onLeave,
    this.onOffset,
    this.useLongPress = false,
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

  /// Size of the divider between [children].
  final double dividerSize;

  /// Indicator dragging should be allowed when [children] have only one child.
  final bool allowDraggingLast;

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
  final void Function(T?)? onWillAccept;

  /// Callback, called when a dragged item leaves some [DragTarget].
  final void Function(T?)? onLeave;

  /// Callback, specifying an [Offset] of this view.
  final Offset Function()? onOffset;

  /// Hover color of the [DragTarget].
  final Color hoverColor;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return DragTarget<T>(
        onAccept: (o) => onAdded?.call(o, 0),
        onWillAccept: (b) {
          onWillAccept?.call(b);
          return true;
        },
        onLeave: onLeave,
        builder: ((_, __, ___) {
          return SizedBox(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
          );
        }),
      );
    }

    return LayoutBuilder(builder: (context, constraints) {
      // Number of columns.
      int mColumns = 0;

      // Minimal diagonal of a square.
      double min = double.infinity;

      // To find the [mColumns], iterate through every possible number of
      // columns and pick the arrangement with [min]imal diagonal.
      for (int columns = 1; columns <= children.length; ++columns) {
        int rows = (children.length / columns).ceil();

        // Current diagonal of a single square.
        double diagonal = (pow(constraints.maxWidth / columns, 2) +
                pow(constraints.maxHeight / rows, 2))
            .toDouble();

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
            coef = constraints.maxWidth > constraints.maxHeight ? 0.5 : 0.87;
          } else if (children.length == 5) {
            if (constraints.maxWidth > constraints.maxHeight) {
              coef = 0.8;
            } else {
              coef = outside == 1 ? 0.8 : 1.5;
            }
          } else if (children.length == 10) {
            if (constraints.maxWidth > constraints.maxHeight) {
              coef = outside == 2 ? 0.65 : 0.8;
            } else {
              coef = 0.8;
            }
          } else if (children.length == 9) {
            if (constraints.maxWidth > constraints.maxHeight) {
              coef = 0.9;
            } else {
              coef = 0.5;
            }
          } else if (children.length == 8) {
            if (constraints.maxWidth > constraints.maxHeight) {
              coef = outside == 2 ? 0.59 : 0.8;
            } else {
              coef = 0.8;
            }
          } else if (children.length == 7) {
            if (constraints.maxWidth > constraints.maxHeight) {
              coef =
                  constraints.maxWidth / constraints.maxHeight >= 3 ? 0.7 : 0.4;
            } else {
              coef = 0.4;
            }
          } else if (children.length == 6) {
            if (constraints.maxWidth > constraints.maxHeight) {
              coef = (constraints.maxWidth / constraints.maxHeight > 3)
                  ? 0.57
                  : 0.7;
            } else {
              coef = 0.7;
            }
          } else {
            if (constraints.maxWidth > constraints.maxHeight) {
              coef = outside == 2 ? 0.59 : 0.77;
            } else {
              coef = 0.6;
            }
          }

          diagonal = (pow(constraints.maxWidth / outside * coef, 2) +
                  pow(constraints.maxHeight / rows, 2))
              .toDouble();
        }
        // Tweak of a standard arrangement.
        else if (children.length == 4) {
          mColumns = constraints.maxWidth / constraints.maxHeight < 0.56
              ? 1
              : mColumns;
        }

        if (diagonal < min) {
          mColumns = columns;
          min = diagonal;
        }
      }

      return _ReorderableFitView<T>(
        children: children,
        itemBuilder: itemBuilder,
        decoratorBuilder: decoratorBuilder,
        overlayBuilder: overlayBuilder,
        mColumns: mColumns,
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
        onLeave: onLeave,
        onWillAccept: onWillAccept,
        onOffset: onOffset,
        useLongPress: useLongPress,
        allowDraggingLast: allowDraggingLast,
      );
    });
  }
}

/// Stateful component of the [ReorderableFitView].
class _ReorderableFitView<T extends Object> extends StatefulWidget {
  const _ReorderableFitView({
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

  /// Size of the divider between [children].
  final double dividerSize;

  /// Indicator dragging should be allowed when [children] have only one child.
  final bool allowDraggingLast;

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
  final void Function(T?)? onWillAccept;

  /// Callback, called when a dragged item leaves some [DragTarget].
  final void Function(T?)? onLeave;

  /// Callback, specifying an [Offset] of this view.
  final Offset Function()? onOffset;

  /// Hover color of the [DragTarget].
  final Color hoverColor;

  /// Number of [Column]s to place the [children] onto.
  final int mColumns;

  @override
  State<_ReorderableFitView<T>> createState() => _ReorderableFitViewState<T>();
}

/// State of a [_ReorderableFitView] maintaining the reorderable [_items] list.
class _ReorderableFitViewState<T extends Object>
    extends State<_ReorderableFitView<T>> {
  /// [ReorderableItem]s of this [_ReorderableFitView].
  late final List<ReorderableItem<T>> _items;

  /// Positions to place new [ReorderableItem]s in [_items].
  final Map<int, int> _positions = {};

  /// [GlobalKey] of this [_ReorderableFitView].
  final GlobalKey _fitKey = GlobalKey();

  /// [AudioPlayer] playing a pop sound.
  AudioPlayer? _audioPlayer;

  /// [ReorderableItem] being dragged that has already broke its dough.
  ReorderableItem<T>? _doughDragged;

  @override
  void initState() {
    _items = widget.children.map((e) => ReorderableItem(e)).toList();
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
  void didUpdateWidget(covariant _ReorderableFitView<T> oldWidget) {
    for (var r in List<ReorderableItem<T>>.from(_items, growable: false)) {
      if (!widget.children.contains(r.item)) {
        _items.remove(r);
        _positions.remove(r.hashCode);
      }
    }

    for (var r in widget.children) {
      if (!_items.any((e) => e.hashCode == r.hashCode)) {
        int? index = _positions[r.hashCode];
        if (index != null && index < _items.length) {
          _items.insert(index, ReorderableItem(r));
          _positions.remove(r.hashCode);
        } else {
          _items.add(ReorderableItem(r));
        }
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    // Creates a visual representation of the [ReorderableItem] with provided
    // [index].
    Widget _cell(int index) {
      var item = _items[index];
      return Stack(
        children: [
          if (widget.decoratorBuilder != null)
            widget.decoratorBuilder!.call(item.item),
          KeyedSubtree(
            key: item.key,
            child: item.entry != null
                ? Container()
                : ReorderableDraggableHandle(
                    item: item.item,
                    itemBuilder: widget.itemBuilder,
                    sharedKey: item.sharedKey,
                    enabled:
                        _items.map((e) => e.entry).whereNotNull().isEmpty &&
                            (widget.allowDraggingLast || _items.length != 1),
                    useLongPress: widget.useLongPress,
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
                    widget.onWillAccept?.call(b);
                    if (b != item.item) {
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
                    widget.onWillAccept?.call(b);
                    if (b != item.item) {
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

    // Creates a column of a row at [rowIndex] index.
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

    // Creates a row of a [_createColumn]s.
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

    return Stack(
      key: _fitKey,
      children: [
        Column(children: _createRows()),

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
            return AnimatedTransition(
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
  void _animateReturn(ReorderableItem<T> to, Offset d) {
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
          return AnimatedTransition(
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
      _audioPlayer = AudioPlayer(playerId: 'reorderableFitView');
      await AudioCache.instance.loadAll(['audio/pop.mp3']);
    } on MissingPluginException {
      _audioPlayer = null;
    }
  }
}
