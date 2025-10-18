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

/// [Widget] keyboard handler to PageUp(Option/Alt+Up), PageDown(Option/Alt+Down), Up, Down keys.
/// Scroll [scrollController] to (accessible_height_from_constraints * ([scrollStepFactor] ?? 0.9)) in PageUp and PageDown
/// Or +/- 50 to offset in Up and Down
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

  ///reverse direction of scroll
  final bool reverseList;

  @override
  State<ScrollKeyboardHandler> createState() => _ScrollKeyboardHandlerState();
}

class _ScrollKeyboardHandlerState extends State<ScrollKeyboardHandler> {
  final focusNode = FocusNode();
  final _keyHandler = _KeyRepeatHandler();
  double scrollStep = 0;

  ///holder to Option key pressed
  bool isOptionPressed = false;

  @override
  void initState() {
    super.initState();
    _keyHandler.addListener(_handleRepeatedKey);
  }

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

  ///
  ///commented out due to focus interception by input fields on the MyProfile page
  ///
  // void scrollUp({bool quick = false}) {
  //   animateTo(
  //     widget.scrollController.offset + (widget.reverseList ? 50 : -50),
  //     quick
  //         ? const Duration(milliseconds: 50)
  //         : const Duration(milliseconds: 200),
  //   );
  // }

  // void scrollDown({bool quick = false}) {
  //   animateTo(
  //     widget.scrollController.offset + (widget.reverseList ? -50 : 50),
  //     quick
  //         ? const Duration(milliseconds: 50)
  //         : const Duration(milliseconds: 200),
  //   );
  // }

  void _handleRepeatedKey(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.pageUp ||
        (isOptionPressed && key == LogicalKeyboardKey.arrowUp)) {
      scrollPageUp(quick: true);
    } else if (key == LogicalKeyboardKey.pageDown ||
        (isOptionPressed && key == LogicalKeyboardKey.arrowDown)) {
      scrollPageDown(quick: true);
    }
    // else if (!isOptionPressed && key == LogicalKeyboardKey.arrowUp) {
    //   scrollUp(quick: true);
    // } else if (!isOptionPressed && key == LogicalKeyboardKey.arrowDown) {
    //   scrollDown(quick: true);
    // }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).requestFocus(focusNode);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          FocusScope.of(context).requestFocus(focusNode);
        });
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          ///update curent scroll step
          scrollStep = constraints.maxHeight * (widget.scrollStepFactor ?? 0.9);

          /// keystroke interception function for [KeyboardListener]
          void handleKeyEvent(KeyEvent event) {
            if (event is KeyDownEvent) {
              final logicalKey = event.logicalKey;

              /// Option (Alt) keyDown
              if (logicalKey == LogicalKeyboardKey.altLeft ||
                  logicalKey == LogicalKeyboardKey.altRight) {
                isOptionPressed = true;
                return;
              }

              _keyHandler.onKeyEvent(event);

              if (logicalKey == LogicalKeyboardKey.pageUp ||
                  (isOptionPressed &&
                      logicalKey == LogicalKeyboardKey.arrowUp)) {
                scrollPageUp();
              } else if (logicalKey == LogicalKeyboardKey.pageDown ||
                  (isOptionPressed &&
                      logicalKey == LogicalKeyboardKey.arrowDown)) {
                scrollPageDown();
              }
              // else if (logicalKey == LogicalKeyboardKey.arrowUp) {
              //   scrollUp();
              // } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
              //   scrollDown();
              // }
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

class _KeyRepeatHandler {
  final _listeners = <void Function(LogicalKeyboardKey)>[];
  final _pressedKeys = <LogicalKeyboardKey>{};
  Timer? _timer;

  void addListener(void Function(LogicalKeyboardKey) listener) {
    _listeners.add(listener);
  }

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

  void _startTimer() {
    _timer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      for (final key in _pressedKeys) {
        for (final listener in _listeners) {
          listener(key);
        }
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    _stopTimer();
    _listeners.clear();
    _pressedKeys.clear();
  }
}
