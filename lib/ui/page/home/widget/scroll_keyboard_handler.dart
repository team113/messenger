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

import '/util/log.dart';

/// Widget that handles keyboard shortcuts for scrolling.
///
/// Handles PageUp (Option/Alt+Up) and PageDown (Option/Alt+Down) keys to scroll
/// the [scrollController] by (accessible_height_from_constraints * 0.9).
class ScrollKeyboardHandler extends StatefulWidget {
  const ScrollKeyboardHandler({
    required this.scrollController,
    required this.child,
    this.reverseList = false,
    super.key,
  });

  /// [ScrollController] to add scroll actions.
  final ScrollController scrollController;

  /// Widget with [Scrollable] connected with [scrollController].
  final Widget child;

  /// Whether to reverse the scroll direction.
  final bool reverseList;

  @override
  State<ScrollKeyboardHandler> createState() => _ScrollKeyboardHandlerState();
}

class _ScrollKeyboardHandlerState extends State<ScrollKeyboardHandler> {
  /// Default duration to scroll animation.
  static const _defaultLongScrollAnimationDuration = Duration(
    milliseconds: 300,
  );

  /// Duration for scroll animations when PageUp/Down is clamped at boundaries.
  static const _defaultQuickScrollAnimationDuration = Duration(
    milliseconds: 150,
  );

  /// Factor determining how much of the visible area to scroll (0.9 = 90%).
  static const _defaultScrollStepFactor = 0.9;

  /// Focus node for capturing keyboard focus.
  final FocusNode _focusNode = FocusNode();

  /// Repeater for long press of PageUp/Down buttons.
  final _KeyRepeatHandler _keyHandler = _KeyRepeatHandler();

  /// Current scroll step calculated based on container height.
  double _scrollStep = 0;

  /// Tracks whether the Option/Alt key is currently pressed.
  bool _isOptionPressed = false;

  @override
  void initState() {
    super.initState();

    /// Subscribing to key press events.
    _keyHandler.addListener(_handleRepeatedKey);
    _startListeningToKeyboard();
  }

  @override
  void dispose() {
    _stopListeningToKeyboard();
    _focusNode.dispose();
    _keyHandler.dispose();
    super.dispose();
  }

  /// Starts listening to global keyboard events.
  void _startListeningToKeyboard() {
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  /// Stops listening to global keyboard events.
  void _stopListeningToKeyboard() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
  }

  /// Animates the [widget.scrollController] to the specified offset and [Duration].
  void _animateTo(double newOffset, [Duration? duration]) =>
      widget.scrollController.animateTo(
        /// Safe clamp offset.
        newOffset.clamp(0, widget.scrollController.position.maxScrollExtent),
        duration: duration ?? _defaultLongScrollAnimationDuration,
        curve: Curves.linear,
      );

  /// Scrolls up by [_scrollStep] amount.
  void _scrollPageUp({bool quick = false}) {
    final newOffset =
        widget.scrollController.offset +
        (widget.reverseList ? _scrollStep : -_scrollStep);
    _animateTo(newOffset, quick ? _defaultQuickScrollAnimationDuration : null);
  }

  /// Scrolls down by [_scrollStep] amount.
  void _scrollPageDown({bool quick = false}) {
    final newOffset =
        widget.scrollController.offset +
        (widget.reverseList ? -_scrollStep : _scrollStep);
    _animateTo(newOffset, quick ? _defaultQuickScrollAnimationDuration : null);
  }

  /// Handles repeated key events from the key handler.
  void _handleRepeatedKey(LogicalKeyboardKey key) {
    if (!widget.scrollController.hasClients) {
      Log.debug(
        'ScrollKeyboardHandler: ScrollController not attached to any scroll views',
      );
      return;
    }

    if (key == LogicalKeyboardKey.pageUp ||
        (_isOptionPressed && key == LogicalKeyboardKey.arrowUp)) {
      _scrollPageUp(quick: true);
    } else if (key == LogicalKeyboardKey.pageDown ||
        (_isOptionPressed && key == LogicalKeyboardKey.arrowDown)) {
      _scrollPageDown(quick: true);
    }
  }

  /// Handles all keyboard events from HardwareKeyboard.
  bool _handleKeyEvent(KeyEvent event) {
    if (!widget.scrollController.hasClients) {
      Log.debug(
        'ScrollKeyboardHandler: ScrollController not attached to any scroll views',
      );
      return false;
    }

    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;

      // Track Option/Alt key state.
      if (logicalKey == LogicalKeyboardKey.altLeft ||
          logicalKey == LogicalKeyboardKey.altRight) {
        _isOptionPressed = true;
        return false;
      }

      /// Pass the event to the repeat click handler.
      _keyHandler.onKeyEvent(event);

      if (logicalKey == LogicalKeyboardKey.pageUp ||
          (_isOptionPressed && logicalKey == LogicalKeyboardKey.arrowUp)) {
        _scrollPageUp();
        return true; // Event handled
      } else if (logicalKey == LogicalKeyboardKey.pageDown ||
          (_isOptionPressed && logicalKey == LogicalKeyboardKey.arrowDown)) {
        _scrollPageDown();
        return true; // Event handled
      }
    } else if (event is KeyUpEvent) {
      final logicalKey = event.logicalKey;

      /// Option (Alt) keyUp.
      if (logicalKey == LogicalKeyboardKey.altLeft ||
          logicalKey == LogicalKeyboardKey.altRight) {
        _isOptionPressed = false;
      }
      _keyHandler.onKeyEvent(event);
    } else if (event is KeyRepeatEvent) {
      _keyHandler.onKeyEvent(event);
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Request focus when tapped to enable keyboard handling.
        if (mounted) {
          FocusScope.of(context).requestFocus(_focusNode);
        }
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate scroll step based on available height.
          _scrollStep = constraints.maxHeight * _defaultScrollStepFactor;

          return Focus(
            focusNode: _focusNode,
            autofocus: true,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// Handles repeated key events when keys are held down.
///
/// This class manages timers to generate repeated key events for keys that
/// are pressed and held, providing continuous scrolling behavior.
class _KeyRepeatHandler {
  /// Duration between repeated key events when a key is held down.
  static const _defaultRepeatPeriodDuration = Duration(milliseconds: 100);

  /// List of functions that subscribe to key press repeat events.
  final _listeners = <void Function(LogicalKeyboardKey)>[];

  /// Multiple currently pressed keys.
  final _pressedKeys = <LogicalKeyboardKey>{};

  /// Timer for generating repeating events.
  Timer? _timer;

  /// Adding subscriber to click-once events.
  void addListener(void Function(LogicalKeyboardKey) listener) {
    _listeners.add(listener);
  }

  /// Processes keyboard events and manages key state.
  void onKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _pressedKeys.add(event.logicalKey);
      _startTimer();
    } else if (event is KeyUpEvent) {
      _pressedKeys.remove(event.logicalKey);
      if (_pressedKeys.isEmpty) _stopTimer();
    } else if (event is KeyRepeatEvent) {
      _pressedKeys.add(event.logicalKey);
      _startTimer();
    }
  }

  /// Starts the timer for generating repeated key events.
  void _startTimer() {
    _timer ??= Timer.periodic(_defaultRepeatPeriodDuration, (_) {
      for (final key in _pressedKeys) {
        for (final listener in _listeners) {
          listener(key);
        }
      }
    });
  }

  /// Stops the repeat timer.
  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// Disposes this [_KeyRepeatHandler].
  void dispose() {
    _stopTimer();
    _listeners.clear();
    _pressedKeys.clear();
  }
}
