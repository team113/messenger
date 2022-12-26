import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/widget/gallery_popup.dart';

import 'animated_transition.dart';
import 'fit_view.dart';

class SwappableFit<T> extends StatefulWidget {
  const SwappableFit({
    super.key,
    required this.itemBuilder,
    this.children = const [],
    this.center,
    this.onReorder,
    this.onCenter,
  });

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Children widgets needed to be placed in a [Wrap].
  final List<T> children;

  final T? center;

  final void Function(List<T>)? onReorder;
  final void Function(T?)? onCenter;

  @override
  State<SwappableFit> createState() => _SwappableFitState<T>();
}

class _SwappableFitState<T> extends State<SwappableFit<T>> {
  late final List<_SwappableItem<T>> _items;

  T? center;

  BoxConstraints? constraints;

  int _locked = 0;

  @override
  void initState() {
    _items = widget.children.map((e) => _SwappableItem(e)).toList();
    center = widget.center;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant SwappableFit<T> oldWidget) {
    for (T e in widget.children) {
      if (_items.none((p) => p.item == e)) {
        _items.add(_SwappableItem(e));
      }
    }

    _items.removeWhere((e) => widget.children.none((p) => p == e.item));

    Future.delayed(Duration.zero, () {
      if (center != widget.center) {
        if (center == null && widget.center != null) {
          _center(widget.center as T);
        } else if (center != null && widget.center != null) {
          _swap(center as T, widget.center as T);
        } else if (center != null && widget.center == null) {
          _uncenter();
        }
      }
    });

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
        final double size = constraints.maxHeight / 6;

        return Column(
          children: [
            if (center != null)
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
                        onTap: () => _swap(center as T, e.item),
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
                  if (center != null) {
                    return e.item == center;
                  }

                  return true;
                }).map((e) {
                  return GestureDetector(
                    onTap: () {
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

  void _center(T e) {
    final layout = constraints?.biggest ?? MediaQuery.of(router.context!).size;
    final index = _items.indexWhere((m) => m.item == e);

    for (int j = 0; j < _items.length; ++j) {
      _SwappableItem<T> i = _items[j];
      ++_locked;

      if (i.item == e) {
        i.entry = OverlayEntry(builder: (context) {
          return AnimatedTransition(
            beginRect: i.itemKey.globalPaintBounds ?? Rect.zero,
            endRect: Rect.fromLTWH(
              0,
              layout.height / 6,
              layout.width,
              layout.height * 5 / 6,
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
              (j > index ? (j - 1) : j) * (layout.height / 6),
              0,
              layout.height / 6,
              layout.height / 6,
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

    center = e;
    widget.onCenter?.call(center);

    setState(() {});
  }

  void _uncenter() {
    final layout = constraints?.biggest ?? MediaQuery.of(router.context!).size;

    for (int j = 0; j < _items.length; ++j) {
      _SwappableItem<T> i = _items[j];
      ++_locked;

      i.entry = OverlayEntry(builder: (context) {
        return AnimatedTransition(
          beginRect: i.itemKey.globalPaintBounds ?? Rect.zero,
          endRect: FitView.sizeOf(
            i: j,
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
    widget.onCenter?.call(center);

    setState(() {});
  }

  void _swap(T e, T m) {
    _SwappableItem<T>? a = _items.firstWhereOrNull((i) => i.item == e);
    _SwappableItem<T>? b = _items.firstWhereOrNull((i) => i.item == m);

    if (a != null) {
      ++_locked;
      a.entry = OverlayEntry(builder: (context) {
        return AnimatedTransition(
          beginRect: a.itemKey.globalPaintBounds ?? Rect.zero,
          endRect: b?.itemKey.globalPaintBounds ?? Rect.largest,
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
    }

    if (b != null) {
      ++_locked;
      b.entry = OverlayEntry(builder: (context) {
        return AnimatedTransition(
          beginRect: b.itemKey.globalPaintBounds ?? Rect.zero,
          endRect: a?.itemKey.globalPaintBounds ?? Rect.largest,
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
    }

    Overlay.of(context)?.insertAll([a?.entry, b?.entry].whereNotNull());

    int i = _items.indexWhere((i) => i.item == e);
    int j = _items.indexWhere((j) => j.item == m);
    _SwappableItem<T>? t = _items[i];
    _items[i] = _items[j];
    _items[j] = t;

    center = m;

    widget.onReorder?.call(_items.map((e) => e.item).toList());
    widget.onCenter?.call(center);

    setState(() {});
  }
}

class _SwappableItem<T> {
  _SwappableItem(this.item);

  /// Reorderable [Object] itself.
  final T item;

  /// [GlobalKey] of an [item] this [_ReorderableItem] builds.
  final GlobalKey itemKey = GlobalKey();

  OverlayEntry? entry;
}
