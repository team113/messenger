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

/// Internal repeater for long button presses
class _KeyRepeatHandler {
  /// List of functions that subscribe to key press repeat events
  final _listeners = <void Function(LogicalKeyboardKey)>[];

  /// Multiple currently pressed keys
  final _pressedKeys = <LogicalKeyboardKey>{};

  /// Timer for generating repeating events
  Timer? _timer;

  /// Adding subscriber to click-once events
  void addListener(void Function(LogicalKeyboardKey) listener) {
    _listeners.add(listener);
  }

  /// Handling keyboard events. Handles reactions to pressing, holding, and releasing keys, use [_pressedKeys] to hold keys
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

  /// Starting timer to generate repeating events
  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      for (final key in _pressedKeys) {
        for (final listener in _listeners) {
          listener(key);
        }
      }
    });
  }

  /// Stopping  timer
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

/// [Widget] keyboard handler to PageUp(Option/Alt+Up), PageDown(Option/Alt+Down).
/// Scroll [scrollController] to (accessible_height_from_constraints * ([scrollStepFactor] ?? 0.9)) in PageUp and PageDown
class ScrollKeyboardHandler extends StatefulWidget {
  const ScrollKeyboardHandler({
    required this.scrollController,
    required this.child,
    this.scrollStepFactor = 0.9,
    this.reverseList = false,
    super.key,
  });

  /// [ScrollController] to add scroll actions
  final ScrollController scrollController;

  /// Factor to [constraints.maxHeight] from [LayoutBuilder]
  ///
  /// If `null`, then = 0.9.
  final double? scrollStepFactor;

  /// Widget with [Scrollable] connected with [scrollController]
  final Widget child;

  /// Reverse direction of scroll
  final bool reverseList;

  @override
  State<ScrollKeyboardHandler> createState() => _ScrollKeyboardHandlerState();
}

class _ScrollKeyboardHandlerState extends State<ScrollKeyboardHandler> {
  ///Focus node for capturing keyboard focus
  final focusNode = FocusNode();

  ///Repeater for long press of PageUp/Down buttons
  final _keyHandler = _KeyRepeatHandler();

  ///The current scroll step (calculated based on the container's height)
  double scrollStep = 0;

  ///holder to Option(Alt) key pressed
  bool isOptionPressed = false;

  @override
  void initState() {
    super.initState();

    ///Subscribing to key press events
    _keyHandler.addListener(_handleRepeatedKey);
  }

  /// Disposes this [ScrollKeyboardHandler].
  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
  }

  /// Animates [widget.scrollController] to [newOffset] with [duration]?? Duration(milliseconds: 300)
  void animateTo(double newOffset, [Duration? duration]) =>
      widget.scrollController.animateTo(
        ///safe clamp offset
        newOffset.clamp(0, widget.scrollController.position.maxScrollExtent),
        duration: duration ?? const Duration(milliseconds: 300),
        curve: Curves.linear,
      );

  /// [scrollController] scroll up to [scrollStep]
  void scrollPageUp({bool quick = false}) {
    final newOffset =
        widget.scrollController.offset +
        (widget.reverseList ? scrollStep : -scrollStep);
    animateTo(newOffset, quick ? const Duration(milliseconds: 150) : null);
  }

  /// [scrollController] scroll down to [scrollStep]
  void scrollPageDown({bool quick = false}) {
    final newOffset =
        widget.scrollController.offset +
        (widget.reverseList ? -scrollStep : scrollStep);
    animateTo(newOffset, quick ? const Duration(milliseconds: 150) : null);
  }

  /// Repeated keystroke handler
  void _handleRepeatedKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.pageUp ||
        (isOptionPressed && key == LogicalKeyboardKey.arrowUp)) {
      scrollPageUp(quick: true);
    } else if (key == LogicalKeyboardKey.pageDown ||
        (isOptionPressed && key == LogicalKeyboardKey.arrowDown)) {
      scrollPageDown(quick: true);
    }
  }

  /// Keystroke interception function for [KeyboardListener]
  void handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;

      /// Option (Alt) keyDown
      if (logicalKey == LogicalKeyboardKey.altLeft ||
          logicalKey == LogicalKeyboardKey.altRight) {
        isOptionPressed = true;
        return;
      }

      /// Pass the event to the repeat click handler
      _keyHandler.onKeyEvent(event);

      if (logicalKey == LogicalKeyboardKey.pageUp ||
          (isOptionPressed && logicalKey == LogicalKeyboardKey.arrowUp)) {
        scrollPageUp();
      } else if (logicalKey == LogicalKeyboardKey.pageDown ||
          (isOptionPressed && logicalKey == LogicalKeyboardKey.arrowDown)) {
        scrollPageDown();
      }
    } else if (event is KeyUpEvent) {
      final logicalKey = event.logicalKey;

      /// Option (Alt) keyUp
      if (logicalKey == LogicalKeyboardKey.altLeft ||
          logicalKey == LogicalKeyboardKey.altRight) {
        isOptionPressed = false;
      }
      _keyHandler.onKeyEvent(event);
    } else if (event is KeyRepeatEvent) {
      _keyHandler.onKeyEvent(event);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // On tap, request focus for this widget
        FocusScope.of(context).requestFocus(focusNode);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(focusNode);
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          /// Update curent scroll step by constraints info
          scrollStep = constraints.maxHeight * (widget.scrollStepFactor ?? 0.9);

          return KeyboardListener(
            focusNode: focusNode,
            autofocus: true,
            onKeyEvent: handleKeyEvent,
            child: widget.child,
          );
        },
      ),
    );
  }
}
