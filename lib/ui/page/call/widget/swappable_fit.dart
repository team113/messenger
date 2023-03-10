// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/material.dart';

import '/routes.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import 'animated_transition.dart';
import 'fit_view.dart';

/// Widget placing its [items] in a stage with the provided [center]ed item
/// allowing to swap [items] back and forth.
class SwappableFit<T> extends StatefulWidget {
  const SwappableFit({
    super.key,
    required this.itemBuilder,
    this.items = const [],
    this.center,
    this.fit = false,
  });

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Items of this [SwappableFit].
  final List<T> items;

  /// Item to put in center.
  final T? center;

  /// Indicator whether the [center]ed item should be ignored.
  ///
  /// Intended to be used to temporary disable the swappable behaviour.
  final bool fit;

  @override
  State<SwappableFit> createState() => _SwappableFitState<T>();
}

/// State of a [SwappableFit] maintaining and animating the [_items].
class _SwappableFitState<T> extends State<SwappableFit<T>> {
  /// [_SwappableItem]s of this [SwappableFit].
  late final List<_SwappableItem<T>> _items;

  /// Item to put in center.
  T? _centered;

  /// [BoxConstraints] of this [SwappableFit].
  BoxConstraints? _constraints;

  /// Count of the [_items] being animated.
  ///
  /// Used to block interaction with [_items] when is not zero.
  int _locked = 0;

  @override
  void initState() {
    _items = widget.items.map((e) => _SwappableItem(e)).toList();
    _centered = widget.center;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SwappableFit<T> oldWidget) {
    for (T e in widget.items) {
      if (_items.none((p) => p.item == e)) {
        _items.add(_SwappableItem(e));
      }
    }

    _items.removeWhere((e) => widget.items.none((p) => p == e.item));

    if (widget.fit == oldWidget.fit) {
      Future.delayed(Duration.zero, () {
        if (_centered != widget.center) {
          if (!widget.fit) {
            if (widget.center != null) {
              _center(widget.center as T);
            } else {
              _uncenter();
            }
          } else {
            _centered = widget.center;
          }
        }
      });
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const SizedBox();
    }

    if (_items.length == 1) {
      return widget.itemBuilder(_items.first.item);
    }

    return IgnorePointer(
      ignoring: _locked != 0,
      child: LayoutBuilder(builder: (context, constraints) {
        _constraints = constraints;
        final double size = constraints.maxHeight / 8;

        return Column(
          children: [
            if (_centered != null && !widget.fit)
              SizedBox(
                height: size,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _items.map((e) {
                    if (e.item == _centered) {
                      return const SizedBox();
                    }

                    return SizedBox(
                      width: size,
                      height: size,
                      child: e.entry == null
                          ? KeyedSubtree(
                              key: e.itemKey,
                              child: widget.itemBuilder(e.item),
                            )
                          : null,
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: FitView(
                children: _items.where((e) {
                  if (_centered != null && !widget.fit) {
                    return e.item == _centered;
                  }

                  return true;
                }).map((e) {
                  if (e.entry == null) {
                    return KeyedSubtree(
                      key: e.itemKey,
                      child: widget.itemBuilder(e.item),
                    );
                  }
                  return const SizedBox.shrink();
                }).toList(),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Centers the provided [item].
  void _center(T item) {
    if (_centered == item) {
      return;
    }

    final layout = _constraints?.biggest ?? MediaQuery.of(router.context!).size;
    final index = _items.indexWhere((m) => m.item == item);

    if (_centered == null) {
      for (int j = 0; j < _items.length; ++j) {
        final _SwappableItem<T> i = _items[j];
        ++_locked;

        if (i.item == item) {
          i.entry = OverlayEntry(builder: (context) {
            return AnimatedTransition(
              beginRect: i.itemKey.globalPaintBounds ?? Rect.zero,
              endRect: Rect.fromLTWH(
                0,
                layout.height / 8,
                layout.width,
                layout.height * 7 / 8,
              ),
              curve: Curves.ease,
              onEnd: () {
                i.entry?.remove();
                i.entry = null;
                --_locked;
                setState(() {});
              },
              child: widget.itemBuilder(i.item),
            );
          });
        } else {
          i.entry = OverlayEntry(builder: (context) {
            return AnimatedTransition(
              beginRect: i.itemKey.globalPaintBounds ?? Rect.zero,
              endRect: Rect.fromLTWH(
                (j > index ? (j - 1) : j) * (layout.height / 8),
                0,
                layout.height / 8,
                layout.height / 8,
              ),
              curve: Curves.ease,
              onEnd: () {
                i.entry?.remove();
                i.entry = null;
                --_locked;
                setState(() {});
              },
              child: widget.itemBuilder(i.item),
            );
          });
        }

        Overlay.of(context).insert(i.entry!);
      }
    } else {
      _swap(_centered as T, item);
    }

    _centered = item;

    setState(() {});
  }

  /// Un-centers the [_centered] item.
  void _uncenter() {
    if (_centered == null) {
      return;
    }

    final layout = _constraints?.biggest ?? MediaQuery.of(router.context!).size;

    for (int j = 0; j < _items.length; ++j) {
      _SwappableItem<T> i = _items[j];
      ++_locked;

      i.entry = OverlayEntry(builder: (context) {
        return AnimatedTransition(
          beginRect: i.itemKey.globalPaintBounds ?? Rect.zero,
          endRect: FitView.sizeOf(
            index: j,
            length: _items.length,
            constraints: _constraints ?? BoxConstraints.tight(layout),
          ),
          curve: Curves.ease,
          onEnd: () {
            i.entry?.remove();
            i.entry = null;
            --_locked;
            setState(() {});
          },
          child: widget.itemBuilder(i.item),
        );
      });

      Overlay.of(context).insert(i.entry!);
    }

    _centered = null;

    setState(() {});
  }

  /// Swaps the two provided items.
  void _swap(T e, T m) {
    final _SwappableItem<T>? a = _items.firstWhereOrNull((i) => i.item == e);
    final _SwappableItem<T>? b = _items.firstWhereOrNull((i) => i.item == m);

    if (a != null && b != null) {
      ++_locked;
      a.entry = OverlayEntry(builder: (context) {
        return AnimatedTransition(
          beginRect: a.itemKey.globalPaintBounds ?? Rect.zero,
          endRect: b.itemKey.globalPaintBounds ?? Rect.largest,
          curve: Curves.ease,
          onEnd: () {
            a.entry?.remove();
            a.entry = null;
            --_locked;
            setState(() {});
          },
          child: widget.itemBuilder(a.item),
        );
      });

      ++_locked;
      b.entry = OverlayEntry(builder: (context) {
        return AnimatedTransition(
          beginRect: b.itemKey.globalPaintBounds ?? Rect.zero,
          endRect: a.itemKey.globalPaintBounds ?? Rect.largest,
          curve: Curves.ease,
          onEnd: () {
            b.entry?.remove();
            b.entry = null;
            --_locked;
            setState(() {});
          },
          child: widget.itemBuilder(b.item),
        );
      });

      Overlay.of(context).insertAll([a.entry, b.entry].whereNotNull());
    }

    setState(() {});
  }
}

/// Data of an [Object] used in a [SwappableFit].
class _SwappableItem<T> {
  _SwappableItem(this.item);

  /// Swappable [Object] itself.
  final T item;

  /// [GlobalKey] of an [item] this [_SwappableItem] builds.
  final GlobalKey itemKey = GlobalKey();

  /// [OverlayEntry] of this [_SwappableItem].
  OverlayEntry? entry;
}
