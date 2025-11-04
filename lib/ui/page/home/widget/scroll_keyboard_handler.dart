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
import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/util/log.dart';

/// Widget that handles keyboard shortcuts to scroll the provided
/// [scrollController].
///
/// Handles "PageUp" (Option/Alt+Up) and "PageDown" (Option/Alt+Down) keys to
/// scroll the [scrollController] by a fraction of the [LayoutBuilder]'s height.
class ScrollKeyboardHandler extends StatefulWidget {
  const ScrollKeyboardHandler({
    required this.scrollController,
    required this.child,
    this.scrollUpEnabled,
    this.scrollDownEnabled,
    this.reversed = false,
    super.key,
  });

  /// Indicator whether "PageUp" (Option/Alt+Up) should be handled by this
  /// widget.
  final bool Function()? scrollUpEnabled;

  /// Indicator whether "PageDown" (Option/Alt+Down) should be handled by this
  /// widget.
  final bool Function()? scrollDownEnabled;

  /// [ScrollController] to scroll.
  final ScrollController scrollController;

  /// Indicator whether [scrollController] direction should be reversed.
  final bool reversed;

  /// Widget to build as a child.
  final Widget child;

  @override
  State<ScrollKeyboardHandler> createState() => _ScrollKeyboardHandlerState();
}

/// State of a [ScrollKeyboardHandler] handling the keys binding and scrolling.
class _ScrollKeyboardHandlerState extends State<ScrollKeyboardHandler> {
  /// [Duration] to scroll the [ScrollController] by a single up/down event.
  static const Duration _longAnimationDuration = Duration(milliseconds: 250);

  /// [Duration] to scroll the [ScrollController] by repeated events.
  static const Duration _quickAnimationDuration = Duration(milliseconds: 150);

  /// Factor determining how much of the visible area to scroll (0.95 = 95%).
  static const double _stepFactor = 0.95;

  /// [State]s of [ScrollKeyboardHandler]s stored in [ScrollKeyboardHandler]
  /// creation order.
  ///
  /// Used to determine keyboard key handle priority - the higher the state is
  /// in the list, the more prioritized the handling of [HardwareKeyboard]
  /// events is.
  static final RxList<State<ScrollKeyboardHandler>> _states = RxList();

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

    // Avoid race condition.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _states.add(this);
        HardwareKeyboard.instance.addHandler(_handleKeyEvent);
      }
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _states.remove(this);

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
    if (widget.scrollUpEnabled?.call() == false) {
      return Future.value();
    }

    return _animateTo(
      widget.scrollController.offset + (widget.reversed ? _step : -_step),
      quick ? _quickAnimationDuration : null,
    );
  }

  /// Scrolls the [ScrollController] down by [_step] amount.
  Future<void> _scrollPageDown({bool quick = false}) {
    if (widget.scrollDownEnabled?.call() == false) {
      return Future.value();
    }

    return _animateTo(
      widget.scrollController.offset + (widget.reversed ? -_step : _step),
      quick ? _quickAnimationDuration : null,
    );
  }

  /// Handles the provided [key] to [_scrollPageUp] or [_scrollPageDown].
  bool _handleKey(LogicalKeyboardKey key, {bool quick = false}) {
    // Ignore the event, if the top [State] in the list isn't the current one.
    if (_states.lastOrNull != this) {
      return false;
    }

    if (!widget.scrollController.hasClients) {
      Log.debug(
        '_handleKey() -> `ScrollController` not attached to any scroll views',
        '$runtimeType',
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
          return true;
        }
        break;

      case LogicalKeyboardKey.arrowDown:
        if (HardwareKeyboard.instance.isAltPressed) {
          _scrollPageDown(quick: quick);
          return true;
        }
        break;
    }

    return false;
  }

  /// Handles the provided [event] to invoke [_handleKey] or to fire up the
  /// [_repeater].
  bool _handleKeyEvent(KeyEvent event) {
    // Ignore the event, if the top [State] in the list isn't the current one.
    if (_states.lastOrNull != this) {
      return false;
    }

    if (!widget.scrollController.hasClients) {
      Log.debug(
        '_handleKeyEvent() -> `ScrollController` not attached to any scroll views',
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
