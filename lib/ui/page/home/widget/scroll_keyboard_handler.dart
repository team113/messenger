import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Keyboard Handler to PageUp, PageDown, Up, Down keys.
/// Scroll [scrollController] to (accessible_height_from_constraints * ([scrollStepFactor] ?? 0.9)) in PageUp and PageDown
/// Or +/- 50 to offset in Up and Down
class ScrollKeyboardHandler extends StatefulWidget {
  const ScrollKeyboardHandler({
    required this.scrollController,
    required this.child,
    this.scrollStepFactor = 0.9,
    super.key,
  });
  final ScrollController scrollController;
  final double? scrollStepFactor;
  final Widget child;

  @override
  State<ScrollKeyboardHandler> createState() => _ScrollKeyboardHandlerState();
}

class _ScrollKeyboardHandlerState extends State<ScrollKeyboardHandler> {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scrollStep =
            constraints.maxHeight * (widget.scrollStepFactor ?? 0.9);

        void animateTo(double newOffset, [Duration? duration]) =>
            widget.scrollController.animateTo(
              newOffset.clamp(
                0.0,
                widget.scrollController.position.maxScrollExtent,
              ),
              duration: duration ?? const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
        void scrollPageUp() {
          final newOffset = widget.scrollController.offset - scrollStep;
          animateTo(newOffset);
        }

        void scrollPageDown() {
          final newOffset = widget.scrollController.offset + scrollStep;
          animateTo(newOffset);
        }

        void handleKeyEvent(KeyEvent event) {
          if (event is KeyDownEvent) {
            final logicalKey = event.logicalKey;

            if (logicalKey == LogicalKeyboardKey.pageUp) {
              scrollPageUp();
            } else if (logicalKey == LogicalKeyboardKey.pageDown) {
              scrollPageDown();
            } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
              animateTo(
                widget.scrollController.offset - 50,
                const Duration(milliseconds: 200),
              );
            } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
              animateTo(
                widget.scrollController.offset + 50,
                const Duration(milliseconds: 200),
              );
            }
          }
        }

        return KeyboardListener(
          focusNode: FocusNode(),
          autofocus: true,
          onKeyEvent: handleKeyEvent,
          child: widget.child,
        );
      },
    );
  }
}
