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

  @override
  void dispose() {
    focusNode.dispose();
    super.dispose();
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
          ///scroll step
          final scrollStep =
              constraints.maxHeight * (widget.scrollStepFactor ?? 0.9);

          ///holder to Option key pressed
          bool isOptionPressed = false;

          /// Animates [widget.scrollController] to [newOffset] with [duration]?? Duration(milliseconds: 300)
          void animateTo(double newOffset, [Duration? duration]) =>
              widget.scrollController.animateTo(
                ///safe clamp offset
                newOffset.clamp(
                  0,
                  widget.scrollController.position.maxScrollExtent,
                ),
                duration: duration ?? const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );

          /// [scrollController] scroll up to [scrollStep]
          void scrollPageUp() {
            final newOffset =
                widget.scrollController.offset +
                (widget.reverseList ? scrollStep : -scrollStep);
            animateTo(newOffset);
          }

          /// [scrollController] scroll down to [scrollStep]
          void scrollPageDown() {
            final newOffset =
                widget.scrollController.offset +
                (widget.reverseList ? -scrollStep : scrollStep);
            animateTo(newOffset);
          }

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

              if (isOptionPressed) {
                if (logicalKey == LogicalKeyboardKey.arrowUp) {
                  scrollPageUp();
                  return;
                } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                  scrollPageDown();
                  return;
                }
              }

              if (logicalKey == LogicalKeyboardKey.pageUp) {
                scrollPageUp();
              } else if (logicalKey == LogicalKeyboardKey.pageDown) {
                scrollPageDown();
              } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
                animateTo(
                  widget.scrollController.offset +
                      (widget.reverseList ? 50 : -50),
                  const Duration(milliseconds: 200),
                );
              } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
                animateTo(
                  widget.scrollController.offset +
                      (widget.reverseList ? -50 : 50),
                  const Duration(milliseconds: 200),
                );
              }
            } else if (event is KeyUpEvent) {
              final logicalKey = event.logicalKey;

              /// Option (Alt) keyUp
              if (logicalKey == LogicalKeyboardKey.altLeft ||
                  logicalKey == LogicalKeyboardKey.altRight) {
                isOptionPressed = false;
              }
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
