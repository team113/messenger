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

import '/routes.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import 'animated_transition.dart';
import 'fit_view.dart';

/// Placing [items] evenly on a screen with an ability to center one of them.
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

  /// Item being centered.
  final T? center;

  /// Indicator whether all [items] should be displayed in a [FitView].
  final bool fit;

  @override
  State<SwappableFit> createState() => _SwappableFitState<T>();
}

/// State of a [SwappableFit] used to animate [_items].
class _SwappableFitState<T> extends State<SwappableFit<T>> {
  /// [_SwappableItem]s of this [SwappableFit].
  late final List<_SwappableItem<T>> _items;

  /// Item being centered.
  T? center;

  /// [BoxConstraints] of this [SwappableFit].
  BoxConstraints? constraints;

  /// Count of the [_items] being animated.
  ///
  /// Used to block interaction with [_items] when is not zero.
  int _locked = 0;

  @override
  void initState() {
    _items = widget.items.map((e) => _SwappableItem(e)).toList();
    center = widget.center;
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
        if (center != widget.center) {
          if (!widget.fit) {
            if (widget.center != null) {
              _center(widget.center as T);
            } else {
              _uncenter();
            }
          } else {
            center = widget.center;
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
        this.constraints = constraints;
        final double size = constraints.maxHeight / 8;

        return Column(
          children: [
            if (center != null && !widget.fit)
              SizedBox(
                height: size,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _items.map((e) {
                    if (e.item == center) {
                      return const SizedBox();
                    }

                    return SizedBox(
                      width: size,
                      height: size,
                      child: GestureDetector(
                        onLongPress: () => _center(e.item),
                        child: e.entry == null
                            ? KeyedSubtree(
                                key: e.itemKey,
                                child: widget.itemBuilder(e.item),
                              )
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: FitView(
                children: _items.where((e) {
                  if (center != null && !widget.fit) {
                    return e.item == center;
                  }

                  return true;
                }).map((e) {
                  return GestureDetector(
                    onLongPress: () {
                      if (center == e.item) {
                        _uncenter();
                      } else {
                        _center(e.item);
                      }
                    },
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
          ],
        );
      }),
    );
  }

  /// Centers the provided [item].
  void _center(T item) {
    if (center == item) {
      return;
    }

    final layout = constraints?.biggest ?? MediaQuery.of(router.context!).size;
    final index = _items.indexWhere((m) => m.item == item);

    if (center == null) {
      for (int j = 0; j < _items.length; ++j) {
        _SwappableItem<T> i = _items[j];
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

        Overlay.of(context)?.insert(i.entry!);
      }
    } else {
      _swap(center as T, item);
    }

    center = item;

    setState(() {});
  }

  /// Uncenters the [center] item.
  void _uncenter() {
    if (center == null) {
      return;
    }

    final layout = constraints?.biggest ?? MediaQuery.of(router.context!).size;

    for (int j = 0; j < _items.length; ++j) {
      _SwappableItem<T> i = _items[j];
      ++_locked;

      i.entry = OverlayEntry(builder: (context) {
        return AnimatedTransition(
          beginRect: i.itemKey.globalPaintBounds ?? Rect.zero,
          endRect: FitView.sizeOf(
            index: j,
            length: _items.length,
            constraints: constraints ?? BoxConstraints.tight(layout),
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

      Overlay.of(context)?.insert(i.entry!);
    }

    center = null;

    setState(() {});
  }

  /// Swaps two provided items.
  void _swap(T e, T m) {
    _SwappableItem<T>? a = _items.firstWhereOrNull((i) => i.item == e);
    _SwappableItem<T>? b = _items.firstWhereOrNull((i) => i.item == m);

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

      Overlay.of(context)?.insertAll([a.entry, b.entry].whereNotNull());
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
