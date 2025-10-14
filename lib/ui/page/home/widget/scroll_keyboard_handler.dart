import 'package:flutter/material.dart';

import '../controller_keyboard_handler_mixin.dart';

///Widget passes the current height to [ControllerKeyboardHandlerMixin] and creates a [KeyboardListener]
class ScrollKeyboardHandler extends StatelessWidget {
  const ScrollKeyboardHandler({
    required this.controller,
    required this.child,
    super.key,
  });

  final ControllerKeyboardHandlerMixin controller;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        controller.constraintsMaxHeight = constraints.maxHeight;
        return KeyboardListener(
          focusNode: controller.focusNode,
          autofocus: true,
          onKeyEvent: controller.controllerHandleKeyEvent,
          child: child,
        );
      },
    );
  }
}
