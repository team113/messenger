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

import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:get/get.dart';

import '../animated_transition.dart';
import '../fit_view.dart';
import '/themes.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// TODO:
/// 1. Primary view and floating secondary panel
/// 2. Primary/secondary should be reported back (via callbacks?), or use RxLists directly to manipulate them here?
/// 3. Clicking on secondary changes places with primary WITH ANIMATION
// class FloatingFit<T> extends StatefulWidget {
//   const FloatingFit({
//     super.key,
//     required this.primary,
//     required this.secondary,
//   });
//
//   final RxList<T> primary;
//   final RxList<T> secondary;
//
//   @override
//   State<FloatingFit> createState() => _FloatingFitState();
// }
//
// class _FloatingFitState extends State<FloatingFit> {
//   @override
//   Widget build(BuildContext context) {
//     return Stack(
//       children: [],
//     );
//   }
// }

/// Widget placing its [items] in a stage with the provided [panel]ed item
/// allowing to swap [items] back and forth.
class FloatingFit<T> extends StatefulWidget {
  const FloatingFit({
    super.key,
    required this.itemBuilder,
    this.items = const [],
    required this.panel,
    this.showPanel = true,
    this.relocateRect,
  });

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Items of this [FloatingFit].
  final List<T> items;

  /// Item to put in secondary panel.
  final T panel;

  /// Indicator whether secondary view should be showed.
  final bool showPanel;

  final Rx<Rect?>? relocateRect;

  @override
  State<FloatingFit> createState() => _FloatingFitState<T>();
}

/// State of a [FloatingFit] maintaining and animating the [_items].
class _FloatingFitState<T> extends State<FloatingFit<T>> {
  /// [_FloatingItem]s of this [FloatingFit].
  late final List<_FloatingItem<T>> _items;

  /// Item to put in secondary panel.
  late _FloatingItem<T> _panelled;

  /// Count of the [_items] being animated.
  ///
  /// Used to block interaction with [_items] when is not zero.
  int _locked = 0;

  @override
  void initState() {
    _items = widget.items.map((e) => _FloatingItem(e)).toList();
    _panelled = _FloatingItem(widget.panel);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant FloatingFit<T> oldWidget) {
    for (T e in widget.items) {
      if (_items.none((p) => p.item == e)) {
        _items.add(_FloatingItem(e));
      }
    }

    _items.removeWhere((e) => widget.items.none((p) => p == e.item));

    Future.delayed(Duration.zero, () {
      if (_panelled.item != widget.panel) {
        _swap();
      }
    });

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: FloatingFitController(relocateRect: widget.relocateRect),
      builder: (FloatingFitController c) {

        return IgnorePointer(
          ignoring: _locked != 0,
          child: LayoutBuilder(builder: (context, constraints) {
            c.size = constraints.biggest;

            return Stack(
              children: [
                FitView(
                  children: [
                    ..._items.map(
                      (e) => e.entry == null
                          ? KeyedSubtree(
                              key: e.itemKey,
                              child: widget.itemBuilder(e.item),
                            )
                          : Container(),
                    ),
                    if (!widget.showPanel)
                      KeyedSubtree(
                        key: _panelled.itemKey,
                        child: widget.itemBuilder(_panelled.item),
                      ),
                  ],
                ),
                if (widget.showPanel) _secondaryPanel(c, context, constraints),
              ],
            );
          }),
        );
      },
    );
  }

  /// [FitWrap] of the [CallController.secondary] widgets.
  Widget _secondaryPanel(
    FloatingFitController c,
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Obx(() {
      double? left = c.secondaryLeft.value;
      double? top = c.secondaryTop.value;
      double? right = c.secondaryRight.value;
      double? bottom = c.secondaryBottom.value;
      double width = c.secondaryWidth.value;
      double height = c.secondaryHeight.value;

      return Stack(
        fit: StackFit.expand,
        children: [
          // Display a shadow below the view.
          Positioned(
            key: c.secondaryKey,
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: IgnorePointer(
              child: Container(
                width: width,
                height: height,
                decoration: const BoxDecoration(
                  boxShadow: [
                    CustomBoxShadow(
                      color: Color(0x44000000),
                      blurRadius: 9,
                      blurStyle: BlurStyle.outer,
                    )
                  ],
                ),
              ),
            ),
          ),

          // Display the background.
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: SizedBox(
              width: width,
              height: height,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  children: [
                    SvgLoader.asset(
                      'assets/images/background_dark.svg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(color: const Color(0x11FFFFFF)),
                  ],
                ),
              ),
            ),
          ),

          // Secondary panel itself.
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: SizedBox(
              width: width,
              height: height,
              child: ClipRRect(
                key: const Key('SecondaryView'),
                borderRadius: BorderRadius.circular(10),
                child: _panelled.entry == null ? KeyedSubtree(
                  key: _panelled.itemKey,
                  child: widget.itemBuilder(_panelled.item),
                ) : null,
              ),
            ),
          ),

          // [Listener] manipulating secondary view.
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: Listener(
              onPointerDown: (_) => c.secondaryManipulated.value = true,
              onPointerUp: (_) => c.secondaryManipulated.value = false,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  // final Participant participant = c.secondary.first;
                  // c.unfocusAll();
                  // c.focus(participant);
                  // c.keepUi(false);
                  _swap();
                },
                onScaleStart: (d) {
                  c.secondaryBottomShifted = null;

                  c.secondaryLeft.value ??= c.size.width -
                      c.secondaryWidth.value -
                      (c.secondaryRight.value ?? 0);
                  c.secondaryTop.value ??= c.size.height -
                      c.secondaryHeight.value -
                      (c.secondaryBottom.value ?? 0);

                  c.secondaryRight.value = null;
                  c.secondaryBottom.value = null;

                  if (d.pointerCount == 1) {
                    c.secondaryDragged.value = true;
                    c.calculateSecondaryPanning(d.focalPoint);
                    c.applySecondaryConstraints();
                  } else if (d.pointerCount == 2) {
                    c.secondaryUnscaledSize =
                        max(c.secondaryWidth.value, c.secondaryHeight.value);
                    c.secondaryScaled.value = true;
                    c.calculateSecondaryPanning(d.focalPoint);
                  }
                },
                onScaleUpdate: (d) {
                  c.updateSecondaryOffset(d.focalPoint);
                  if (d.pointerCount == 2) {
                    c.scaleSecondary(d.scale);
                  }

                  c.applySecondaryConstraints();
                },
                onScaleEnd: (d) {
                  c.secondaryDragged.value = false;
                  c.secondaryScaled.value = false;
                  c.secondaryUnscaledSize = null;

                  c.updateSecondaryAttach();
                },
                child: Container(
                  width: width,
                  height: height,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  /// Swaps the two provided items.
  void _swap() {
    final _FloatingItem<T> panelled = _panelled;
    final _FloatingItem<T> item = _items.first;

    ++_locked;
    panelled.entry = OverlayEntry(builder: (context) {
      return AnimatedTransition(
        beginRect: panelled.itemKey.globalPaintBounds ?? Rect.zero,
        endRect: item.itemKey.globalPaintBounds ?? Rect.largest,
        curve: Curves.ease,
        onEnd: () {
          panelled.entry?.remove();
          panelled.entry = null;
          --_locked;
          setState(() {});
        },
        child: widget.itemBuilder(panelled.item),
      );
    });

    ++_locked;
    item.entry = OverlayEntry(builder: (context) {
      return AnimatedTransition(
        beginRect: item.itemKey.globalPaintBounds ?? Rect.zero,
        endRect: panelled.itemKey.globalPaintBounds ?? Rect.largest,
        curve: Curves.ease,
        onEnd: () {
          item.entry?.remove();
          item.entry = null;
          --_locked;
          setState(() {});
        },
        child: widget.itemBuilder(item.item),
      );
    });

    _panelled = item;
    _items.removeAt(0);
    _items.insert(0, panelled);

    Overlay.of(context)?.insertAll([panelled.entry, item.entry].whereNotNull());

    setState(() {});
  }
}

/// Data of an [Object] used in a [FloatingFit].
class _FloatingItem<T> {
  _FloatingItem(this.item);

  /// Swappable [Object] itself.
  final T item;

  /// [GlobalKey] of an [item] this [_FloatingItem] builds.
  final GlobalKey itemKey = GlobalKey();

  /// [OverlayEntry] of this [_FloatingItem].
  OverlayEntry? entry;
}
