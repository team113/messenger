// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/routes.dart';
import '/util/log.dart';

/// Widget that handles keyboard shortcuts for scrolling.
///
/// Handles PageUp (Option/Alt+Up) and PageDown (Option/Alt+Down) keys to scroll
/// the [scrollController] by a fraction of the [LayoutBuilder]'s height.
class ScrollKeyboardHandler extends StatefulWidget {
  const ScrollKeyboardHandler({
    required this.scrollController,
    required this.child,
    this.reversed = false,
    super.key,
  });

  /// [ScrollController] to add scroll actions.
  final ScrollController scrollController;

  /// Widget with [Scrollable] connected with [scrollController].
  final Widget child;

  /// Whether to reverse the scroll direction.
  final bool reversed;

  @override
  State<ScrollKeyboardHandler> createState() => _ScrollKeyboardHandlerState();
}

class _ScrollKeyboardHandlerState extends State<ScrollKeyboardHandler> {
  /// Default duration to scroll animation.
  static const Duration _longAnimationDuration = Duration(milliseconds: 250);

  /// Duration for scroll animations when PageUp/Down is clamped at boundaries.
  static const Duration _quickAnimationDuration = Duration(milliseconds: 150);

  /// Factor determining how much of the visible area to scroll (0.95 = 95%).
  static const double _stepFactor = 0.95;

  /// Current Route from [RouteState].
  final String _route = router.route;

  /// [Timer] repeating [_handleKey] invokes with the [_repeatedKey].
  Timer? _repeater;

  /// [Timer] canceling [_repeater] when a threshold is exceeded.
  Timer? _keepRepeater;

  /// [LogicalKeyboardKey] to repeat on [_repeater] ticks.
  LogicalKeyboardKey? _repeatedKey;

  /// Current scroll step calculated based on [LayoutBuilder]'s height.
  double _step = 0;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);

    _keepRepeater?.cancel();
    _repeater?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (_, constraints) {
        // Calculate scroll step based on the available height.
        _step = constraints.maxHeight * _stepFactor;

        return widget.child;
      },
    );
  }

  /// Animates the [ScrollController] to the specified offset and [Duration].
  Future<void> _animateTo(double newOffset, [Duration? duration]) {
    return widget.scrollController.animateTo(
      newOffset.clamp(0, widget.scrollController.position.maxScrollExtent),
      duration: duration ?? _longAnimationDuration,
      curve: Curves.ease,
    );
  }

  /// Scrolls the [ScrollController] up by [_step] amount.
  Future<void> _scrollPageUp({bool quick = false}) {
    return _animateTo(
      widget.scrollController.offset + (widget.reversed ? _step : -_step),
      quick ? _quickAnimationDuration : null,
    );
  }

  /// Scrolls the [ScrollController] down by [_step] amount.
  Future<void> _scrollPageDown({bool quick = false}) {
    return _animateTo(
      widget.scrollController.offset + (widget.reversed ? -_step : _step),
      quick ? _quickAnimationDuration : null,
    );
  }

  /// Handles repeated key events from the key handler.
  bool _handleKey(LogicalKeyboardKey key, {bool quick = false}) {
    if (!widget.scrollController.hasClients) {
      Log.debug(
        'ScrollKeyboardHandler: ScrollController not attached to any scroll views',
      );

      return false;
    }

    switch (key) {
      case LogicalKeyboardKey.pageUp:
        _scrollPageUp(quick: quick);
        return true;

      case LogicalKeyboardKey.pageDown:
        _scrollPageDown(quick: quick);
        return true;

      case LogicalKeyboardKey.arrowUp:
        if (HardwareKeyboard.instance.isAltPressed) {
          _scrollPageUp(quick: quick);
        }
        return true;

      case LogicalKeyboardKey.arrowDown:
        if (HardwareKeyboard.instance.isAltPressed) {
          _scrollPageDown(quick: quick);
        }
        return true;
    }

    return false;
  }

  /// Handles all keyboard events from HardwareKeyboard.
  bool _handleKeyEvent(KeyEvent event) {
    /// Ignore KeyEvent when Widget unmounted or not on top of route.
    if (_route != router.route || !mounted) return false;
    if (!widget.scrollController.hasClients) {
      Log.debug(
        'ScrollController not attached to any scroll views, ignoring',
        '$runtimeType',
      );

      return false;
    }

    if (event is KeyDownEvent) {
      return _handleKey(event.logicalKey);
    } else if (event is KeyUpEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.pageUp ||
            LogicalKeyboardKey.pageDown ||
            LogicalKeyboardKey.arrowUp ||
            LogicalKeyboardKey.arrowDown ||
            LogicalKeyboardKey.altLeft ||
            LogicalKeyboardKey.altRight:
          _keepRepeater?.cancel();
          _repeater?.cancel();
          _repeater = null;
          break;
      }
    } else if (event is KeyRepeatEvent) {
      switch (event.logicalKey) {
        case LogicalKeyboardKey.pageUp ||
            LogicalKeyboardKey.pageDown ||
            LogicalKeyboardKey.arrowUp ||
            LogicalKeyboardKey.arrowDown:
          _keepRepeater?.cancel();
          _keepRepeater = Timer(const Duration(milliseconds: 300), () {
            _repeater?.cancel();
            _repeater = null;
          });

          if (_repeatedKey != event.logicalKey) {
            _repeatedKey = event.logicalKey;
            _repeater?.cancel();
            _repeater = null;
          }

          _repeater ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
            _handleKey(event.logicalKey, quick: true);
          });

          return true;
      }
    }

    return false;
  }
}
