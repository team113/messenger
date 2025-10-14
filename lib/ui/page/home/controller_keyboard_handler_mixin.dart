import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

/// Factor to page scrolling step
const double scrollStepFactor = 0.9;

///Mixin what implement handleKeyEvent
mixin ControllerKeyboardHandlerMixin on GetxController {
  //get what must link to controller to scroll
  ScrollController get keyboardHandlerController;

  /// This is result of `LayoutBuilder(builder: (_, constraints) { constraintsMaxHeight= constraints.maxHeight`
  /// updated in [ScrollKeyboardHandler]. By default, if not changed, PageUp/Down do nothing
  double constraintsMaxHeight = 0;

  /// FocusNode to use in [KeyboardListener] inside [ScrollKeyboardHandler]
  FocusNode get focusNode;

  void _animateTo(double newOffset, [Duration? duration]) =>
      keyboardHandlerController.animateTo(
        newOffset.clamp(
          0.0,
          keyboardHandlerController.position.maxScrollExtent,
        ),
        duration: duration ?? const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );

  void _scrollPageUp() {
    final scrollStep = constraintsMaxHeight * scrollStepFactor;
    final newOffset = keyboardHandlerController.offset - scrollStep;
    _animateTo(newOffset);
  }

  void _scrollPageDown() {
    final scrollStep = constraintsMaxHeight * scrollStepFactor;
    final newOffset = keyboardHandlerController.offset + scrollStep;
    _animateTo(newOffset);
  }

  void controllerHandleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      final logicalKey = event.logicalKey;

      if (logicalKey == LogicalKeyboardKey.pageUp) {
        _scrollPageUp();
      } else if (logicalKey == LogicalKeyboardKey.pageDown) {
        _scrollPageDown();
      } else if (logicalKey == LogicalKeyboardKey.arrowUp) {
        _animateTo(
          keyboardHandlerController.offset - 50,
          const Duration(milliseconds: 200),
        );
      } else if (logicalKey == LogicalKeyboardKey.arrowDown) {
        _animateTo(
          keyboardHandlerController.offset + 50,
          const Duration(milliseconds: 200),
        );
      }
      //TODO add Ctrl + PageUp/Down logic
    }
  }
}
