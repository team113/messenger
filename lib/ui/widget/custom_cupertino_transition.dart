// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Width of the gesture response area.
const double _kBackGestureWidth = 20.0;

/// Screen widths per second.
const double _kMinFlingVelocity = 1.0;

/// Animated [Offset] for center-to-left animation.
final Animatable<Offset> _kMiddleLeftTween = Tween<Offset>(
  begin: Offset.zero,
  end: const Offset(-1.0, 0.0),
);

/// Animated [Offset] for right-to-center animation.
final Animatable<Offset> _kRightMiddleTween = Tween<Offset>(
  begin: const Offset(1.0, 0.0),
  end: Offset.zero,
);

/// Animated [Offset] for bottom-up animation.
final Animatable<Offset> _kBottomUpTween = Tween<Offset>(
  begin: const Offset(0.0, 1.0),
  end: Offset.zero,
);

/// Custom [CupertinoPageTransitionsBuilder] to define a horizontal
/// [MaterialPageRoute] page transition animation.
class CustomCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const CustomCupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return CustomCupertinoRouteTransitionsMixin.buildPageTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Mixin that replaces the entire screen with a custom iOS transition for a
/// [PageRoute].
mixin CustomCupertinoRouteTransitionsMixin<T> on PageRoute<T> {
  /// Indicates whether the pop gesture in progress.
  static bool isPopGestureInProgress(PageRoute<dynamic> route) {
    return route.navigator!.userGestureInProgress;
  }

  /// Indicates whether the pop gesture is available.
  static bool _isPopGestureEnabled<T>(PageRoute<T> route) {
    if (route.isFirst) {
      return false;
    }
    if (route.willHandlePopInternally) {
      return false;
    }
    if (route.popDisposition == RoutePopDisposition.doNotPop) {
      return false;
    }
    if (route.fullscreenDialog) {
      return false;
    }
    if (route.animation!.status != AnimationStatus.completed) {
      return false;
    }
    if (route.secondaryAnimation!.status != AnimationStatus.dismissed) {
      return false;
    }
    if (isPopGestureInProgress(route)) {
      return false;
    }

    return true;
  }

  /// Returns [_CupertinoBackGestureController] if [_isPopGestureEnabled] is
  /// true.
  static _CupertinoBackGestureController<T> _startPopGesture<T>(
      PageRoute<T> route) {
    assert(_isPopGestureEnabled(route));

    return _CupertinoBackGestureController<T>(
      navigator: route.navigator!,
      controller: route.controller!,
    );
  }

  /// Returns custom cupertino page transition.
  ///
  /// If [route.fullscreenDialog] is true, returns
  /// [CustomCupertinoFullscreenDialogTransition], otherwise
  /// [CustomCupertinoPageTransition].
  static Widget buildPageTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final bool linearTransition = isPopGestureInProgress(route);
    if (route.fullscreenDialog) {
      return CustomCupertinoFullscreenDialogTransition(
        primaryAnimation: animation,
        secondaryAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: child,
      );
    } else {
      return CustomCupertinoPageTransition(
        primaryAnimation: animation,
        secondaryAnimation: secondaryAnimation,
        linearTransition: linearTransition,
        child: _CupertinoBackGestureDetector<T>(
          enabledCallback: () => _isPopGestureEnabled<T>(route),
          onStartPopGesture: () => _startPopGesture<T>(route),
          child: child,
        ),
      );
    }
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return buildPageTransitions<T>(
      this,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Custom iOS-style page transition.
class CustomCupertinoPageTransition extends StatelessWidget {
  CustomCupertinoPageTransition({
    super.key,
    required Animation<double> primaryAnimation,
    required Animation<double> secondaryAnimation,
    required this.child,
    required bool linearTransition,
  })  : _primaryAnimation = (linearTransition
                ? primaryAnimation
                : CurvedAnimation(
                    parent: primaryAnimation,
                    curve: Curves.linearToEaseOut,
                    reverseCurve: Curves.linearToEaseOut.flipped,
                  ))
            .drive(_kRightMiddleTween),
        _secondaryAnimation = (linearTransition
                ? secondaryAnimation
                : CurvedAnimation(
                    parent: secondaryAnimation,
                    curve: Curves.linearToEaseOut,
                    reverseCurve: Curves.easeInToLinear,
                  ))
            .drive(_kMiddleLeftTween);

  /// [Widget] to display.
  final Widget child;

  /// Animation for next page.
  final Animation<Offset> _primaryAnimation;

  /// Animation for previous page.
  final Animation<Offset> _secondaryAnimation;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _secondaryAnimation,
      child: SlideTransition(
        position: _primaryAnimation,
        child: child,
      ),
    );
  }
}

/// Custom fullscreen iOS-style page transition.
class CustomCupertinoFullscreenDialogTransition extends StatelessWidget {
  CustomCupertinoFullscreenDialogTransition({
    super.key,
    required Animation<double> primaryAnimation,
    required Animation<double> secondaryAnimation,
    required this.child,
    required bool linearTransition,
  })  : _primaryAnimation = CurvedAnimation(
          parent: primaryAnimation,
          curve: Curves.linearToEaseOut,
          reverseCurve: Curves.linearToEaseOut.flipped,
        ).drive(_kBottomUpTween),
        _secondaryAnimation = (linearTransition
                ? secondaryAnimation
                : CurvedAnimation(
                    parent: secondaryAnimation,
                    curve: Curves.linearToEaseOut,
                    reverseCurve: Curves.easeInToLinear,
                  ))
            .drive(_kMiddleLeftTween);

  /// [Widget] to display.
  final Widget child;

  /// Animation for next page.
  final Animation<Offset> _primaryAnimation;

  /// Animation for previous page.
  final Animation<Offset> _secondaryAnimation;

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _secondaryAnimation,
      child: SlideTransition(
        position: _primaryAnimation,
        child: child,
      ),
    );
  }
}

/// Widget side of [_CupertinoBackGestureController].
class _CupertinoBackGestureDetector<T> extends StatefulWidget {
  const _CupertinoBackGestureDetector({
    super.key,
    required this.enabledCallback,
    required this.onStartPopGesture,
    required this.child,
  });

  /// [Widget] to display.
  final Widget child;

  /// Callback, called when adding a pointer to [DragGestureRecognizer].
  final bool Function() enabledCallback;

  /// Callback, called when the gesture is launched.
  final _CupertinoBackGestureController<T> Function() onStartPopGesture;

  @override
  _CupertinoBackGestureDetectorState<T> createState() =>
      _CupertinoBackGestureDetectorState<T>();
}

/// State of [_CupertinoBackGestureDetector].
class _CupertinoBackGestureDetectorState<T>
    extends State<_CupertinoBackGestureDetector<T>> {
  /// Gesture controller.
  _CupertinoBackGestureController<T>? _backGestureController;

  /// Horizontal [DragGestureRecognizer] for gesture control.
  late HorizontalDragGestureRecognizer _recognizer;

  @override
  void initState() {
    _recognizer = HorizontalDragGestureRecognizer(debugOwner: this)
      ..onStart = _handleDragStart
      ..onUpdate = _handleDragUpdate
      ..onEnd = _handleDragEnd
      ..onCancel = _handleDragCancel;

    super.initState();
  }

  @override
  void dispose() {
    _recognizer.dispose();
    super.dispose();
  }

  /// Initializes [_backGestureController], if it is not initialized.
  ///
  /// Used in [_recognizer].
  void _handleDragStart(DragStartDetails details) {
    assert(mounted);
    assert(_backGestureController == null);
    _backGestureController = widget.onStartPopGesture();
  }

  /// Updates drag in [_backGestureController].
  ///
  /// Used in [_recognizer].
  void _handleDragUpdate(DragUpdateDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragUpdate(
        _convertToLogical(details.primaryDelta! / context.size!.width));
  }

  /// Ends drag in [_backGestureController].
  ///
  /// Used in [_recognizer].
  void _handleDragEnd(DragEndDetails details) {
    assert(mounted);
    assert(_backGestureController != null);
    _backGestureController!.dragEnd(_convertToLogical(
      details.velocity.pixelsPerSecond.dx / context.size!.width,
    ));
    _backGestureController = null;
  }

  /// Cancels drag in [_backGestureController].
  ///
  /// Used in [_recognizer].
  void _handleDragCancel() {
    assert(mounted);
    _backGestureController?.dragEnd(0.0);
    _backGestureController = null;
  }

  /// Adds pointer for [_recognizer] if [widget.enabledCallback] is true.
  void _handlePointerDown(PointerDownEvent event) {
    if (widget.enabledCallback()) {
      _recognizer.addPointer(event);
    }
  }

  /// Returns [value] depending on the text direction.
  double _convertToLogical(double value) {
    switch (Directionality.of(context)) {
      case TextDirection.rtl:
        return -value;
      case TextDirection.ltr:
        return value;
    }
  }

  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasDirectionality(context));
    double dragAreaWidth = Directionality.of(context) == TextDirection.ltr
        ? MediaQuery.paddingOf(context).left
        : MediaQuery.paddingOf(context).right;
    dragAreaWidth = max(dragAreaWidth, _kBackGestureWidth);

    return Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        widget.child,
        PositionedDirectional(
          start: 0.0,
          width: dragAreaWidth,
          top: 0.0,
          bottom: 0.0,
          child: Listener(
            onPointerDown: _handlePointerDown,
            behavior: HitTestBehavior.translucent,
          ),
        ),
      ],
    );
  }
}

/// Controller for an iOS-style bask gesture.
class _CupertinoBackGestureController<T> {
  _CupertinoBackGestureController({
    required this.navigator,
    required this.controller,
  }) {
    navigator.didStartUserGesture();
  }

  /// Maximum animation time for page rewinding when scrolling forward.
  static const int maxForwardAnimationTime = 800;

  /// Maximum page back animation time.
  static const int maxBackAnimationTime = 300;

  /// [AnimationController] for back gesture.
  final AnimationController controller;

  /// [NavigatorState] for back gesture.
  final NavigatorState navigator;

  /// The drag gesture has changed by [fractionalDelta]. The total range of the
  /// drag should be 0.0 to 1.0.
  void dragUpdate(double delta) {
    controller.value -= delta;
  }

  /// The drag gesture has ended with a horizontal motion of
  /// [fractionalVelocity] as a fraction of screen width per second.
  void dragEnd(double velocity) {
    const Curve animationCurve = Curves.fastLinearToSlowEaseIn;
    final bool animateForward;

    if (velocity.abs() >= _kMinFlingVelocity) {
      animateForward = velocity <= 0;
    } else {
      animateForward = controller.value > 0.5;
    }

    if (animateForward) {
      final int droppedPageForwardAnimationTime = min(
        lerpDouble(
          maxForwardAnimationTime,
          0,
          controller.value,
        )!
            .floor(),
        maxBackAnimationTime,
      );
      controller.animateTo(1.0,
          duration: Duration(milliseconds: droppedPageForwardAnimationTime),
          curve: animationCurve);
    } else {
      navigator.pop();

      if (controller.isAnimating) {
        final int droppedPageBackAnimationTime =
            lerpDouble(0, maxForwardAnimationTime, controller.value)!.floor();
        controller.animateBack(0.0,
            duration: Duration(milliseconds: droppedPageBackAnimationTime),
            curve: animationCurve);
      }
    }

    if (controller.isAnimating) {
      late AnimationStatusListener animationStatusCallback;
      animationStatusCallback = (AnimationStatus status) {
        navigator.didStopUserGesture();
        controller.removeStatusListener(animationStatusCallback);
      };
      controller.addStatusListener(animationStatusCallback);
    } else {
      navigator.didStopUserGesture();
    }
  }
}
