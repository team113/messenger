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
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// Widget placing its [panel]ed item in floating panel allowing to swap
/// [primary] and [panel]ed items.
class FloatingFit<T> extends StatefulWidget {
  const FloatingFit({
    super.key,
    required this.itemBuilder,
    required this.itemDecorationBuilder,
    required this.primary,
    required this.panel,
    this.showPanel = true,
    this.relocateRect,
    this.onManipulating,
  });

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  final Widget Function(T data) itemDecorationBuilder;

  /// Items of this [FloatingFit].
  final T primary;

  /// Item to put in floating panel.
  final T panel;

  /// Indicator whether floating panel should be showed.
  final bool showPanel;

  /// [Rect] used to relocate floating panel if intersected.
  final Rx<Rect?>? relocateRect;

  /// Callback called when manipulating with floating panel starts or ends.
  final void Function(bool)? onManipulating;

  @override
  State<FloatingFit> createState() => _FloatingFitState<T>();
}

/// State of a [FloatingFit] maintaining and animating the [_primary].
class _FloatingFitState<T> extends State<FloatingFit<T>> {
  /// Primary [_FloatingItem] of this [FloatingFit].
  late _FloatingItem<T> _primary;

  /// Item to put in floating panel.
  late _FloatingItem<T> _panelled;

  /// Count of the items being animated.
  ///
  /// Used to block interaction when is not zero.
  int _locked = 0;

  @override
  void initState() {
    _primary = _FloatingItem(widget.primary);
    _panelled = _FloatingItem(widget.panel);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant FloatingFit<T> oldWidget) {
    if (widget.showPanel == oldWidget.showPanel) {
      if (_primary.item != widget.primary) {
        _primary = _FloatingItem(widget.primary);
      }

      if (_panelled.item != widget.panel) {
        _panelled = _FloatingItem(widget.panel);
      }
    }

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
                    _primary.entry == null
                        ? KeyedSubtree(
                            key: _primary.itemKey,
                            child: Stack(
                              children: [
                                widget.itemBuilder(_primary.item),
                                AnimatedDelayedSwitcher(
                                  duration: 100.milliseconds,
                                  child: widget
                                      .itemDecorationBuilder(_primary.item),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    if (!widget.showPanel)
                      KeyedSubtree(
                        key: _panelled.itemKey,
                        child: Stack(
                          children: [
                            widget.itemBuilder(_panelled.item),
                            widget.itemDecorationBuilder(_panelled.item),
                          ],
                        ),
                      ),
                  ],
                ),
                if (widget.showPanel) _floatingPanel(c, context, constraints),
              ],
            );
          }),
        );
      },
    );
  }

  /// Returns visual representation of a floating panel.
  Widget _floatingPanel(
    FloatingFitController c,
    BuildContext context,
    BoxConstraints constraints,
  ) {
    return Obx(() {
      double? left = c.floatingLeft.value;
      double? top = c.floatingTop.value;
      double? right = c.floatingRight.value;
      double? bottom = c.floatingBottom.value;
      double width = c.floatingWidth.value;
      double height = c.floatingHeight.value;

      return Stack(
        fit: StackFit.expand,
        children: [
          // Display a shadow below the view.
          Positioned(
            key: c.floatingKey,
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

          // Floating panel itself.
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
                child: _panelled.entry == null
                    ? KeyedSubtree(
                        key: _panelled.itemKey,
                        child: Stack(
                          children: [
                            widget.itemBuilder(_panelled.item),
                            AnimatedDelayedSwitcher(
                              duration: 100.milliseconds,
                              child:
                                  widget.itemDecorationBuilder(_panelled.item),
                            ),
                          ],
                        ),
                      )
                    : null,
              ),
            ),
          ),

          // [Listener] manipulating this panel.
          Positioned(
            left: left,
            right: right,
            top: top,
            bottom: bottom,
            child: Listener(
              onPointerDown: (_) => widget.onManipulating?.call(true),
              onPointerUp: (_) => widget.onManipulating?.call(false),
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
                  c.floatingBottomShifted = null;

                  c.floatingLeft.value ??= c.size.width -
                      c.floatingWidth.value -
                      (c.floatingRight.value ?? 0);
                  c.floatingTop.value ??= c.size.height -
                      c.floatingHeight.value -
                      (c.floatingBottom.value ?? 0);

                  c.floatingRight.value = null;
                  c.floatingBottom.value = null;

                  if (d.pointerCount == 1) {
                    c.floatingDragged.value = true;
                    c.calculateFloatingPanning(d.focalPoint);
                    c.applyFloatingConstraints();
                  } else if (d.pointerCount == 2) {
                    c.floatingUnscaledSize =
                        max(c.floatingWidth.value, c.floatingHeight.value);
                    c.floatingScaled.value = true;
                    c.calculateFloatingPanning(d.focalPoint);
                  }
                },
                onScaleUpdate: (d) {
                  c.updateFloatingOffset(d.focalPoint);
                  if (d.pointerCount == 2) {
                    c.scaleFloating(d.scale);
                  }

                  c.applyFloatingConstraints();
                },
                onScaleEnd: (d) {
                  c.floatingDragged.value = false;
                  c.floatingScaled.value = false;
                  c.floatingUnscaledSize = null;

                  c.updateFloatingAttach();
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

  /// Swaps the [_panelled] and [_primary] items.
  void _swap() {
    final _FloatingItem<T> panelled = _panelled;
    final _FloatingItem<T> primary = _primary;

    ++_locked;
    panelled.entry = OverlayEntry(builder: (context) {
      return AnimatedTransition(
        beginRect: panelled.itemKey.globalPaintBounds ?? Rect.zero,
        endRect: primary.itemKey.globalPaintBounds ?? Rect.largest,
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
    primary.entry = OverlayEntry(builder: (context) {
      return AnimatedTransition(
        beginRect: primary.itemKey.globalPaintBounds ?? Rect.zero,
        endRect: panelled.itemKey.globalPaintBounds ?? Rect.largest,
        curve: Curves.ease,
        onEnd: () {
          primary.entry?.remove();
          primary.entry = null;
          --_locked;
          setState(() {});
        },
        child: widget.itemBuilder(primary.item),
      );
    });

    Overlay.of(context)
        ?.insertAll([panelled.entry, primary.entry].whereNotNull());

    _panelled = primary;
    _primary = panelled;

    setState(() {});
  }
}

/// Data of an [Object] used in a [FloatingFit].
class _FloatingItem<T> {
  _FloatingItem(this.item);

  /// Item itself.
  final T item;

  /// [GlobalKey] of an [item] this [_FloatingItem] builds.
  final GlobalKey itemKey = GlobalKey();

  /// [OverlayEntry] of this [_FloatingItem].
  OverlayEntry? entry;
}
