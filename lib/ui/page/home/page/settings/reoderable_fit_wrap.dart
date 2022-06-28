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
import 'package:messenger/ui/page/call/widget/fit_wrap.dart';

import '/ui/page/home/widget/gallery_popup.dart';

class ReorderableFitWrap<T extends Object> extends StatelessWidget {
  const ReorderableFitWrap({
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
    this.hoverColor = const Color(0x00000000),
    this.insertHandles = true,
    this.wrapAxis,
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
  }) : super(key: key);

  final Widget Function(T data) itemBuilder;
  final Widget Function(T data)? decoratorBuilder;
  final Widget Function(T data)? overlayBuilder;

  final bool useLongPress;

  /// Children widgets needed to be placed evenly on a screen.
  final List<T> children;

  final bool insertHandles;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  final double dividerSize;

  final Function(T, int)? onReorder;
  final Function(T, int)? onAdded;
  final Function(T)? onDragStarted;
  final void Function(T)? onDoughBreak;
  final Function(T)? onDragEnd;
  final Function(T)? onDragCompleted;
  final Function(T)? onDraggableCanceled;

  final void Function(T?)? onWillAccept;
  final void Function(T?)? onLeave;

  final Offset Function()? onOffset;

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double? width;
  final double? height;

  final Color hoverColor;

  /// [Axis] of a [Wrap].
  final Axis? wrapAxis;

  /// Returns calculated size of a [FitWrap] with [maxSize], [constraints],
  /// [axis] and children [length].
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

  static bool useFitView({
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
      return (size * length >= constraints.height);
    } else {
      return (size * length >= constraints.width);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Container();
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
        maxHeight: MediaQuery.of(context).size.height,
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        double rWidth = width ?? constraints.maxWidth;
        double rHeight = height ?? constraints.maxHeight;

        double wrapMaxSize = wrapAxis == Axis.horizontal ? rWidth : rHeight;
        bool fitView = wrapAxis == null
            ? true
            : useFitView(
                maxSize: wrapMaxSize,
                constraints: Size(rWidth, rHeight),
                length: children.length,
                axis: wrapAxis!,
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
            // Tweak of a standart arrangment.
            else if (children.length == 4) {
              mColumns = rWidth / rHeight < 0.56 ? 1 : mColumns;
            }

            if (diagonal < min) {
              mColumns = columns;
              min = diagonal;
            }
          }
        }

        if (wrapAxis != null) {
          wrapSize = calculateSize(
            maxSize: wrapMaxSize,
            constraints: Size(rWidth, rHeight),
            length: children.length,
            axis: wrapAxis!,
          );
        }

        return _ReorderableFitWrap<T>(
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
          insertHandles: insertHandles,
          useWrap: !fitView,
          wrapAxis: wrapAxis,
          constraints: constraints,
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
        );
      }),
    );
  }
}

/// Widget placing its [children] evenly on a screen.
class _ReorderableFitWrap<T extends Object> extends StatefulWidget {
  const _ReorderableFitWrap({
    Key? key,
    required this.children,
    required this.itemBuilder,
    required this.constraints,
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
    this.insertHandles = true,
    this.wrapSize,
    this.wrapAxis = Axis.horizontal,
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
  }) : super(key: key);

  final Widget Function(T data) itemBuilder;
  final Widget Function(T data)? decoratorBuilder;
  final Widget Function(T data)? overlayBuilder;

  final bool useLongPress;

  final BoxConstraints constraints;

  /// Children widgets needed to be placed evenly on a screen.
  final List<T> children;

  /// Color of a divider between [children].
  ///
  /// If `null`, then there will be no divider at all.
  final Color? dividerColor;

  final double dividerSize;

  final Function(T, int)? onReorder;
  final Function(T, int)? onAdded;
  final Function(T)? onDragStarted;
  final void Function(T)? onDoughBreak;
  final Function(T)? onDragEnd;
  final Function(T)? onDragCompleted;
  final Function(T)? onDraggableCanceled;

  final void Function(T?)? onWillAccept;
  final void Function(T?)? onLeave;

  final Offset Function()? onOffset;

  final Color hoverColor;

  final double? left;
  final double? right;
  final double? top;
  final double? bottom;
  final double? width;
  final double? height;

  final int mColumns;
  final double? wrapSize;
  final Axis? wrapAxis;
  final bool useWrap;

  final bool insertHandles;

  @override
  State<_ReorderableFitWrap<T>> createState() => _ReorderableFitWrapState<T>();
}

class _ReorderableFitWrapState<T extends Object>
    extends State<_ReorderableFitWrap<T>> {
  List<_ReorderableItem<T>> _items = [];

  final Map<int, int> _positions = {};

  final GlobalKey _fitKey = GlobalKey();

  /// [AudioPlayer] playing a pop sound.
  AudioPlayer? _audioPlayer;

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
  void didUpdateWidget(covariant _ReorderableFitWrap<T> oldWidget) {
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

  bool _building = false;

  @override
  Widget build(BuildContext context) {
    _building = true;

    Widget _cell(int index) {
      return Stack(
        children: [
          if (widget.decoratorBuilder != null)
            widget.decoratorBuilder!.call(_items[index].item),
          KeyedSubtree(
            key: _items[index].key,
            child: _items[index].entry != null
                ? SizedBox(
                    width: widget.wrapSize,
                    height: widget.wrapSize,
                  )
                : _ReorderableDraggableHandle(
                    state: this,
                    index: index,
                    useLongPress: widget.useLongPress,
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

    _building = false;
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
                onWillAccept: (o) {
                  widget.onWillAccept?.call(o);
                  return !_items.contains(o);
                },
                builder: (context, candidates, rejected) {
                  return IgnorePointer(
                    ignoring: candidates.isNotEmpty && rejected.isEmpty,
                    child: SizedBox(
                      width: widget.wrapAxis == Axis.horizontal
                          ? widget.wrapSize
                          : MediaQuery.of(context).size.width,
                      height: widget.wrapAxis == Axis.horizontal
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
                      direction: widget.wrapAxis ?? Axis.horizontal,
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

  void _onAccept(T object, int i, int to) {
    _positions[object.hashCode] = to;
    widget.onAdded?.call(object, to);
  }

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

        // beginRect =
        //     beginRect.translate(-(fitRect?.left ?? 0), -(fitRect?.top ?? 0));
        // endRect =
        //     endRect.translate(-(fitRect?.left ?? 0), -(fitRect?.top ?? 0));

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
                if (!_building) setState(() => from.entry = null);
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

    if (!_building) setState(() {});
  }

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

      // beginRect =
      //     beginRect.translate(-(fitRect?.left ?? 0), -(fitRect?.top ?? 0));
      // endRect = endRect.translate(-(fitRect?.left ?? 0), -(fitRect?.top ?? 0));

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
              if (!_building) {
                setState(() => to.entry = null);
              }
            },
            child: widget.itemBuilder(to.item),
          );
        });
      }

      if (!_building) setState(() {});
    }
  }

  Future<void> _initAudio() async {
    try {
      _audioPlayer = AudioPlayer(playerId: 'reorderableFitView');
      await AudioCache.instance.loadAll(['audio/pop.mp3']);
    } on MissingPluginException {
      _audioPlayer = null;
    }
  }
}

class _ReorderableItem<T> {
  _ReorderableItem(this.item);

  final T item;
  final GlobalKey key = GlobalKey();
  final UniqueKey sharedKey = UniqueKey();

  final GlobalKey<_AnimatedTransitionState> entryKey =
      GlobalKey<_AnimatedTransitionState>();
  OverlayEntry? entry;

  Rect? dragStartedRect;

  @override
  int get hashCode => item.hashCode;

  @override
  bool operator ==(Object other) =>
      other is _ReorderableItem<T> && other.item == item;
}

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

  final Rect beginRect;
  final Rect endRect;
  final Duration duration;
  final VoidCallback? onEnd;
  final Widget child;
  final VoidCallback? onDispose;
  final Curve? curve;

  @override
  State<AnimatedTransition> createState() => _AnimatedTransitionState();
}

class _AnimatedTransitionState extends State<AnimatedTransition>
    with SingleTickerProviderStateMixin {
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

class _ReorderableDraggableHandle<T extends Object> extends StatelessWidget {
  const _ReorderableDraggableHandle({
    Key? key,
    required this.state,
    required this.index,
    this.useLongPress = false,
  }) : super(key: key);

  final _ReorderableFitWrapState<T> state;

  final int index;

  final bool useLongPress;

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
            longPress: useLongPress,
            maxSimultaneousDrags:
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
            onDraggableCanceled: (v, d) {
              state.widget.onDraggableCanceled?.call(state._items[index].item);
              state._animateReturn(state._items[index], d);
            },
            onDoughBreak: () {
              state.widget.onDoughBreak?.call(state._items[index].item);
              state._audioPlayer?.play(
                AssetSource('audio/pop.mp3'),
                volume: 0.5,
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
