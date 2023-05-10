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

/// Widget placing its [panel]ed item in a floating panel allowing to swap
/// [primary] and [panel]ed items.
class FloatingFit<T> extends StatefulWidget {
  const FloatingFit({
    super.key,
    required this.itemBuilder,
    required this.overlayBuilder,
    required this.primary,
    required this.panel,
    this.fit = false,
    this.intersection,
    this.onManipulated,
    this.onSwapped,
  });

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Builder building the provided item's overlay.
  final Widget Function(T data) overlayBuilder;

  /// Item to put in a center stage.
  final T primary;

  /// Item to put in a floating panel.
  final T panel;

  /// Indicator whether the [panel]ed item should be displayed in a [FitView].
  ///
  /// Intended to be used to temporary disable the swappable behaviour.
  final bool fit;

  /// Optional reactive [Rect] relocating the floating panel on its
  /// intersections.
  final Rx<Rect?>? intersection;

  /// Callback, called when floating panel is being manipulated in some way.
  final void Function(bool)? onManipulated;

  /// Callback, called when [primary] and [panel]ed items are swapped.
  final void Function(T, T)? onSwapped;

  @override
  State<FloatingFit> createState() => _FloatingFitState<T>();
}

/// State of a [FloatingFit] maintaining and animating the [_primary] and
/// [_paneled] items.
class _FloatingFitState<T> extends State<FloatingFit<T>> {
  /// Primary [_FloatingItem] of this [FloatingFit].
  late _FloatingItem<T> _primary;

  /// [_FloatingItem] to put in a floating panel of this [FloatingFit].
  late _FloatingItem<T> _paneled;

  /// Count of the items being animated.
  ///
  /// Used to block interaction when non-zero.
  int _locked = 0;

  @override
  void initState() {
    _primary = _FloatingItem(widget.primary);
    _paneled = _FloatingItem(widget.panel);

    super.initState();
  }

  @override
  void didUpdateWidget(covariant FloatingFit<T> oldWidget) {
    if (widget.fit == oldWidget.fit) {
      if (_primary.item != widget.primary) {
        _primary = _FloatingItem(widget.primary);
      }

      if (_paneled.item != widget.panel) {
        _paneled = _FloatingItem(widget.panel);
      }
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: FloatingFitController(intersection: widget.intersection),
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
                                  child: widget.overlayBuilder(_primary.item),
                                ),
                              ],
                            ),
                          )
                        : Container(),
                    if (widget.fit)
                      KeyedSubtree(
                        key: _paneled.itemKey,
                        child: Stack(
                          children: [
                            widget.itemBuilder(_paneled.item),
                            widget.overlayBuilder(_paneled.item),
                          ],
                        ),
                      ),
                  ],
                ),
                if (!widget.fit)
                  Obx(() {
                    return _FloatingPanel<T>(
                      c.left.value,
                      c.top.value,
                      c.right.value,
                      c.bottom.value,
                      floatingKey: c.floatingKey,
                      width: c.width.value,
                      height: c.height.value,
                      paneled: _paneled,
                      itemBuilder: widget.itemBuilder,
                      overlayBuilder: widget.overlayBuilder,
                      onManipulated: widget.onManipulated,
                      onTap: _swap,
                      onScaleStart: (d) {
                        c.bottomShifted = null;

                        c.left.value ??=
                            c.size.width - c.width.value - (c.right.value ?? 0);
                        c.top.value ??= c.size.height -
                            c.height.value -
                            (c.bottom.value ?? 0);

                        c.right.value = null;
                        c.bottom.value = null;

                        if (d.pointerCount == 1) {
                          c.dragged.value = true;
                          c.calculatePanning(d.focalPoint);
                          c.applyConstraints();
                        } else if (d.pointerCount == 2) {
                          c.unscaledSize = max(c.width.value, c.height.value);
                          c.scaled.value = true;
                          c.calculatePanning(d.focalPoint);
                        }
                      },
                      onScaleUpdate: (d) {
                        c.updateOffset(d.focalPoint);
                        if (d.pointerCount == 2) {
                          c.scaleFloating(d.scale);
                        }

                        c.applyConstraints();
                      },
                      onScaleEnd: (d) {
                        c.dragged.value = false;
                        c.scaled.value = false;
                        c.unscaledSize = null;

                        c.updateAttach();
                      },
                    );
                  }),
              ],
            );
          }),
        );
      },
    );
  }

  /// Returns the visual representation of a floating panel.

  /// Swaps the [_paneled] and the [_primary] items with an animation.
  void _swap() {
    final _FloatingItem<T> paneled = _paneled;
    final _FloatingItem<T> primary = _primary;

    ++_locked;
    paneled.entry = OverlayEntry(builder: (context) {
      return AnimatedTransition(
        beginRect: paneled.itemKey.globalPaintBounds ?? Rect.zero,
        endRect: primary.itemKey.globalPaintBounds ?? Rect.largest,
        duration: const Duration(milliseconds: 400),
        curve: Curves.ease,
        onEnd: () {
          paneled.entry?.remove();
          paneled.entry = null;
          --_locked;
          setState(() {});
        },
        child: widget.itemBuilder(paneled.item),
      );
    });

    ++_locked;
    primary.entry = OverlayEntry(builder: (context) {
      return AnimatedTransition(
        beginRect: primary.itemKey.globalPaintBounds ?? Rect.zero,
        endRect: paneled.itemKey.globalPaintBounds ?? Rect.largest,
        duration: const Duration(milliseconds: 400),
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
        .insertAll([paneled.entry, primary.entry].whereNotNull());

    _paneled = primary;
    _primary = paneled;

    widget.onSwapped?.call(_primary.item, _paneled.item);

    setState(() {});
  }
}

/// Visual representation of a floating panel.
class _FloatingPanel<T> extends StatelessWidget {
  const _FloatingPanel(
    this.left,
    this.top,
    this.right,
    this.bottom, {
    super.key,
    required this.paneled,
    required this.itemBuilder,
    required this.overlayBuilder,
    required this.width,
    required this.height,
    this.floatingKey,
    this.onManipulated,
    this.onTap,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  /// Left position of this [_FloatingPanel].
  final double? left;

  /// Top position of this [_FloatingPanel].
  final double? top;

  /// Right position of this [_FloatingPanel].
  final double? right;

  /// Bottom position of this [_FloatingPanel].
  final double? bottom;

  /// Width of this [_FloatingPanel].
  final double width;

  /// Height of this [_FloatingPanel].
  final double height;

  /// [GlobalKey] of this [_FloatingPanel].
  final GlobalKey<State<StatefulWidget>>? floatingKey;

  /// Callback, called when a scale operation starts.
  final void Function(ScaleStartDetails)? onScaleStart;

  /// Callback, called when a scale operation updates.
  final void Function(ScaleUpdateDetails)? onScaleUpdate;

  /// Callback, called when a scale operation ends.
  final void Function(ScaleEndDetails)? onScaleEnd;

  /// [_FloatingItem] to put in this [_FloatingPanel].
  final _FloatingItem<T> paneled;

  /// Builder building the provided item.
  final Widget Function(T data) itemBuilder;

  /// Builder building the provided item's overlay.
  final Widget Function(T data) overlayBuilder;

  /// Callback, called when this [_FloatingPanel] is being manipulated in some
  /// way.
  final void Function(bool)? onManipulated;

  /// Callback, called when this [_FloatingPanel] is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildShadow(),
          _buildBackground(),
          _buildPanel(),
          _buildGestureDetector(),
        ],
      ),
    );
  }

  /// Shadow that is displayed around this [_FloatingPanel].
  Widget _buildShadow() {
    return Positioned(
      key: floatingKey,
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          boxShadow: const [
            CustomBoxShadow(
              color: Color(0x44000000),
              blurRadius: 9,
              blurStyle: BlurStyle.outer,
            )
          ],
        ),
      ),
    );
  }

  /// Background of this [_FloatingPanel].
  Widget _buildBackground() {
    return Positioned(
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
              Container(color: const Color(0xFF0A1724)),
              SvgImage.asset(
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
    );
  }

  /// Content of this [_FloatingPanel].
  Widget _buildPanel() {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: SizedBox(
        key: const Key('SecondaryView'),
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: paneled.entry == null
              ? KeyedSubtree(
                  key: paneled.itemKey,
                  child: Stack(
                    children: [
                      itemBuilder(paneled.item),
                      AnimatedDelayedSwitcher(
                        duration: 100.milliseconds,
                        child: overlayBuilder(paneled.item),
                      ),
                    ],
                  ),
                )
              : null,
        ),
      ),
    );
  }

  /// Gestures that can be used to control this [_FloatingPanel].
  Widget _buildGestureDetector() {
    return Positioned(
      left: left,
      right: right,
      top: top,
      bottom: bottom,
      child: Listener(
        onPointerDown: (_) => onManipulated?.call(true),
        onPointerUp: (_) => onManipulated?.call(false),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          onScaleStart: onScaleStart,
          onScaleUpdate: onScaleUpdate,
          onScaleEnd: onScaleEnd,
          child: Container(
            width: width,
            height: height,
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

/// Data of an [Object] used in a [FloatingFit].
class _FloatingItem<T> {
  _FloatingItem(this.item);

  /// Item itself.
  final T item;

  /// [GlobalKey] of an [item].
  final GlobalKey itemKey = GlobalKey();

  /// [OverlayEntry] of this [_FloatingItem].
  OverlayEntry? entry;
}
