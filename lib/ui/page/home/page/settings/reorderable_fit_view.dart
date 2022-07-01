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

/// Widget placing its [children] evenly on a screen.
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
    //this.onAnimationEnd,
    this.allowDraggingLast = true,
    this.hoverColor = const Color(0x00000000),
    this.onWillAccept,
    this.onLeave,
    this.onOffset,
    this.useLongDraggable = false,
  }) : super(key: key);

  /// Builder to create reorderable items.
  final Widget Function(T data) itemBuilder;

  /// Builder to create decoration.
  final Widget Function(T data)? decoratorBuilder;

  /// Builder to create overlay.
  final Widget Function(T data)? overlayBuilder;

  /// Indicator whether dragging starts on long press.
  final bool useLongDraggable;

  /// Children widgets needed to be placed evenly on a screen.
  final List<T> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  /// Size of a divider between [children].
  final double dividerSize;

  /// Indicator whether dragging allowed when only one item present.
  final bool allowDraggingLast;

  /// Callback called when some item change position.
  final Function(T, int)? onReorder;

  /// Callback called when new item is added.
  final Function(T, int)? onAdded;

  /// Callback called when dragging is started.
  final Function(T)? onDragStarted;

  /// Callback called when dough is break.
  final void Function(T)? onDoughBreak;

  /// Callback called when dragging is end.
  final Function(T)? onDragEnd;

  /// Callback called when dragging is completed.
  final Function(T)? onDragCompleted;

  /// Callback called when the draggable is dropped without being accepted by a
  /// [DragTarget].
  final Function(T)? onDraggableCanceled;

  /// Callback called before accept new item.
  final void Function(T?)? onWillAccept;

  /// Callback called when an item leave dropping area.
  final void Function(T?)? onLeave;

  /// Returns offset.
  final Offset Function()? onOffset;

  /// Color when this [ReorderableFitView] hovered by some item.
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
        builder: ((context, candidates, rejected) {
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
        useLongDraggable: useLongDraggable,
        allowDraggingLast: allowDraggingLast,
      );
    });
  }
}

/// Widget placing its [children] evenly on a screen.
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
    this.useLongDraggable = false,
    this.allowDraggingLast = true,
  }) : super(key: key);

  /// Builder to create reorderable items.
  final Widget Function(T data) itemBuilder;

  /// Builder to create decoration.
  final Widget Function(T data)? decoratorBuilder;

  /// Builder to create overlay.
  final Widget Function(T data)? overlayBuilder;

  /// Indicator whether dragging starts on long press.
  final bool useLongDraggable;

  /// Children widgets needed to be placed evenly on a screen.
  final List<T> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  /// Size of a divider between [children].
  final double dividerSize;

  /// Callback called when some item change position.
  final Function(T, int)? onReorder;

  /// Callback called when new item is added.
  final Function(T, int)? onAdded;

  /// Callback called when dragging is started.
  final Function(T)? onDragStarted;

  /// Callback called when dough is break.
  final void Function(T)? onDoughBreak;

  /// Callback called when dragging is end.
  final Function(T)? onDragEnd;

  /// Callback called when dragging is completed.
  final Function(T)? onDragCompleted;

  /// Callback called when the draggable is dropped without being accepted by a
  /// [DragTarget].
  final Function(T)? onDraggableCanceled;

  /// Callback called before accept new item.
  final void Function(T?)? onWillAccept;

  /// Callback called when an item leave dropping area.
  final void Function(T?)? onLeave;

  /// Returns offset.
  final Offset Function()? onOffset;

  /// Indicator whether dragging allowed when only one item present.
  final bool allowDraggingLast;

  /// Color when this [_ReorderableFitView] hovered by some item.
  final Color hoverColor;

  /// Max count of columns.
  final int mColumns;

  @override
  State<_ReorderableFitView<T>> createState() => ReorderableFitViewState<T>();
}

/// State of [_ReorderableFitWrap] used to add and reorder [_items].
class ReorderableFitViewState<T extends Object>
    extends State<_ReorderableFitView<T>> {
  /// Reorderable items of this [ReorderableFitViewState].
  List<ReorderableItem<T>> _items = [];

  /// Positions of [_items].
  final Map<int, int> _positions = {};

  /// [GlobalKey] of this [ReorderableFitViewState].
  final GlobalKey _fitKey = GlobalKey();

  /// [AudioPlayer] playing a pop sound.
  AudioPlayer? _audioPlayer;

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
  // ignore: library_private_types_in_public_api
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
    // Creates visual representation of the [ReorderableItem] with provided
    // [index].
    Widget _cell(int index) {
      return Stack(
        children: [
          if (widget.decoratorBuilder != null)
            widget.decoratorBuilder!.call(_items[index].item),
          KeyedSubtree(
            key: _items[index].key,
            child: _items[index].entry != null
                ? Container()
                : ReorderableDraggableHandle(
                    state: this,
                    index: index,
                    useLongDraggable: widget.useLongDraggable,
                    enabled: widget.allowDraggingLast || _items.length != 1,
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
                    if (b != _items[index].item) {
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
                    if (b != _items[index].item) {
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
            widget.overlayBuilder!.call(_items[index].item),
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

  /// Adds provided [object] to items.
  void _onAccept(T object, int i, int to) {
    _positions[object.hashCode] = to;
    widget.onAdded?.call(object, to);
  }

  /// Checks if [object] already in [_items] and if `false` adds it otherwise
  /// reorder [_items].
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
                from.entry = null;
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

  /// Plays return animation.
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
              to.entry = null;
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

/// Reorderable item data.
class ReorderableItem<T> {
  ReorderableItem(this.item);

  /// Reorderable item.
  final T item;

  /// [GlobalKey] of this [ReorderableItem].
  final GlobalKey key = GlobalKey();

  /// [UniqueKey] of this [ReorderableItem].
  final UniqueKey sharedKey = UniqueKey();

  /// Global key of [_AnimatedTransitionState].
  // ignore: library_private_types_in_public_api
  final GlobalKey<_AnimatedTransitionState> entryKey =
      GlobalKey<_AnimatedTransitionState>();

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
  State<AnimatedTransition> createState() => _AnimatedTransitionState();
}

/// State of [AnimatedTransition] used to change [rect] with animation.
class _AnimatedTransitionState extends State<AnimatedTransition>
    with SingleTickerProviderStateMixin {
  /// [Rect] of this [_AnimatedTransitionState] used to play animation.
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

/// Widget handles dragging.
class ReorderableDraggableHandle<T extends Object> extends StatelessWidget {
  const ReorderableDraggableHandle({
    Key? key,
    required this.state,
    required this.index,
    this.useLongDraggable = false,
    this.enabled = true,
  }) : super(key: key);

  /// State of [ReorderableFitView].
  final ReorderableFitViewState<T> state;

  /// Index of this [ReorderableDraggableHandle]
  final int index;

  /// Indicator whether dragging starts on long press.
  final bool useLongDraggable;

  /// Indicator whether dragging is enabled.
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
          var item = state.widget.itemBuilder(state._items[index].item);
          return DraggableDough<T>(
            data: state._items[index].item,
            longPress: useLongDraggable,
            maxSimultaneousDrags: !enabled ||
                    state._items.map((e) => e.entry).whereNotNull().isNotEmpty
                ? 0
                : 1,
            onDragEnd: (d) {
              // TODO: animation.
              state.widget.onDragEnd?.call(state._items[index].item);
              state._animateReturn(state._items[index], d.offset);
            },
            onDragStarted: () {
              state._items[index].dragStartedRect =
                  state._items[index].key.globalPaintBounds;
              state.widget.onDragStarted?.call(state._items[index].item);
            },
            onDragCompleted: () =>
                state.widget.onDragCompleted?.call(state._items[index].item),
            onDraggableCanceled: (_, d) {
              state.widget.onDraggableCanceled?.call(state._items[index].item);
              state._animateReturn(state._items[index], d);
            },
            onDoughBreak: () {
              state.widget.onDoughBreak?.call(state._items[index].item);
              state._audioPlayer?.play(
                AssetSource('audio/pop.mp3'),
                volume: 0.3,
                position: Duration.zero,
                mode: PlayerMode.lowLatency,
              );
            },
            feedback: SizedBox(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              child: KeyedSubtree(
                key: state._items[index].sharedKey,
                child: item,
              ),
            ),
            childWhenDragging: KeyedSubtree(
              key: state._items[index].sharedKey,
              child: Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.transparent,
              ),
            ),
            child: KeyedSubtree(
              key: state._items[index].sharedKey,
              child: item,
            ),
          );
        },
      ),
    );
  }
}
