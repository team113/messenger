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

import 'package:flutter/material.dart';

import '/themes.dart';

/// Animated minimizable draggable [Widget] controlled by a [GestureDetector].
class MinimizableView extends StatefulWidget {
  const MinimizableView({
    Key? key,
    this.onInit,
    this.onDispose,
    this.onSizeChanged,
    this.minimizationEnabled = true,
    this.minimizationDelta = 50,
    required this.child,
  }) : super(key: key);

  /// Callback, called when the [AnimationController] of this [MinimizableView]
  /// is initialized.
  final void Function(AnimationController)? onInit;

  /// Callback, called when the state of this [MinimizableView] is disposed.
  final void Function()? onDispose;

  /// Callback, called when the [Size] of this [MinimizableView] is changed.
  final void Function(Size)? onSizeChanged;

  /// Indicator whether the minimizing gesture is enabled.
  final bool minimizationEnabled;

  /// Distance to travel in order for the panning to be recognized as a
  /// minimization gesture.
  final double minimizationDelta;

  /// [Widget] to minimize.
  final Widget child;

  @override
  State<MinimizableView> createState() => _MinimizableViewState();
}

/// State of a [MinimizableView] used to animate its child.
class _MinimizableViewState extends State<MinimizableView>
    with SingleTickerProviderStateMixin {
  /// [Size] of this [MinimizableView] in its minimized state.
  static const Size _size = Size(150, 150);

  /// [AnimationController] of this view.
  late final AnimationController _controller;

  /// [BorderRadius] of a [ClipRRect].
  BorderRadius _borderRadius = BorderRadius.zero;

  /// [GlobalKey] of the child used for [_applyConstraints].
  final GlobalKey _key = GlobalKey();

  /// Initial drag [Offset] of [GestureDetector.onVerticalDragStart].
  Offset? _drag;

  /// Initial [_controller]'s value of [GestureDetector.onVerticalDragStart].
  double? _value;

  /// Bottom offset of this view.
  double _bottom = 10;

  /// Right offset of this view.
  double _right = 10;

  /// [Size] of a screen used in [LayoutBuilder] to call [_applyConstraints] on
  /// layout changes.
  Size? _lastBiggest;

  /// View padding of the screen.
  EdgeInsets _padding = EdgeInsets.zero;

  /// Current panning distance.
  double _panningDistance = 0;

  /// [DecorationTween] of this view.
  final DecorationTween _decorationTween = DecorationTween(
    begin: const BoxDecoration(borderRadius: BorderRadius.zero),
    end: BoxDecoration(
      borderRadius: BorderRadius.circular(10.0),
      boxShadow: const <BoxShadow>[
        CustomBoxShadow(
          color: Color(0x66666666),
          blurRadius: 10.0,
          offset: Offset(0, 0),
        )
      ],
    ),
  );

  @override
  void initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _controller.addListener(_animationListener);
    _controller.addStatusListener(_animationStatusListener);

    widget.onInit?.call(_controller);
    super.initState();
  }

  @override
  void dispose() {
    widget.onDispose?.call();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final Size biggest = constraints.biggest;

        if (_lastBiggest != biggest) {
          _applyConstraints(biggest);
          _lastBiggest = biggest;
        }

        _padding = MediaQuery.of(context).padding;

        return Stack(
          children: [
            PositionedTransition(
              rect: RelativeRectTween(
                begin: RelativeRect.fill,
                end: RelativeRect.fromSize(
                  Rect.fromLTWH(
                    biggest.width - _size.width - _right,
                    biggest.height - _size.height - _bottom - _padding.bottom,
                    _size.width,
                    _size.height,
                  ),
                  biggest,
                ),
              ).animate(_controller),
              child: GestureDetector(
                behavior: HitTestBehavior.deferToChild,
                onTap: _controller.value == 1
                    ? () {
                        _controller.reverse(from: _controller.value);
                        FocusManager.instance.primaryFocus?.unfocus();
                      }
                    : null,
                onPanStart: _controller.value == 0 && widget.minimizationEnabled
                    ? (d) {
                        _controller.stop();
                        _drag = d.localPosition;
                        _value = _controller.value;
                        setState(() {});
                      }
                    : null,
                onPanUpdate:
                    widget.minimizationEnabled || _controller.value == 1
                        ? (d) {
                            _panningDistance = _panningDistance + d.delta.dy;

                            if (_panningDistance < widget.minimizationDelta &&
                                _controller.value == 0) {
                              return;
                            }

                            if (_drag != null && _value != null) {
                              _controller.value = _value! +
                                  (d.localPosition.dy -
                                          _drag!.dy -
                                          widget.minimizationDelta) *
                                      (1 / constraints.maxHeight);
                            } else {
                              setState(() {
                                _right = _right - d.delta.dx;
                                _bottom = _bottom - d.delta.dy;
                                _applyConstraints(biggest);
                              });
                            }
                          }
                        : null,
                onPanEnd: widget.minimizationEnabled
                    ? (d) {
                        if (_drag != null && _value != null) {
                          _onVerticalDragEnd(d);
                        }
                        _panningDistance = 0;
                      }
                    : null,
                child: DecoratedBoxTransition(
                  key: _key,
                  decoration: _decorationTween.animate(_controller),
                  child: ClipRRect(
                    borderRadius: _borderRadius,
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// [Tween]s the [_borderRadius] based on the [_controller] value.
  void _animationListener() {
    _borderRadius = Tween<BorderRadius>(
      begin: BorderRadius.zero,
      end: BorderRadius.circular(10),
    ).evaluate(_controller);

    widget.onSizeChanged?.call(
        SizeTween(begin: _lastBiggest, end: _size).evaluate(_controller)!);

    setState(() {});
  }

  /// Resets the [_bottom] and [_right] on [AnimationStatus.dismissed] status.
  void _animationStatusListener(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _bottom = 10;
      _right = 10;
    }
  }

  /// Handles a [GestureDetector.onVerticalDragEnd] callback.
  void _onVerticalDragEnd(DragEndDetails d) {
    bool forward;

    if (_value! < _controller.value) {
      forward = _controller.value > 0.1;
    } else {
      forward = _controller.value > 0.9;
    }

    if (forward) {
      _controller.forward(from: _controller.value);
    } else {
      _controller.reverse(from: _controller.value);
    }

    _drag = null;
    _value = null;
  }

  /// Applies constraints to the [_right] and [_bottom].
  void _applyConstraints(Size biggest) {
    final keyContext = _key.currentContext;
    if (keyContext != null && _controller.value == 1) {
      final box = keyContext.findRenderObject() as RenderBox;

      if (_right < 0) {
        _right = 0;
      } else if (_right > biggest.width - box.size.width) {
        _right = biggest.width - box.size.width;
      }

      if (_bottom < 0) {
        _bottom = 0;
      } else if (_bottom >
          biggest.height - box.size.height - _padding.bottom - _padding.top) {
        _bottom =
            biggest.height - box.size.height - _padding.bottom - _padding.top;
      }
    }
  }
}
