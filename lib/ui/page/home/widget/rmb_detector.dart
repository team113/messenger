import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:messenger/ui/widget/menu_interceptor/menu_interceptor.dart';

class RmbDetector extends StatefulWidget {
  const RmbDetector({
    super.key,
    required this.child,
    this.onSecondaryButton,
  });

  final Widget child;
  final void Function()? onSecondaryButton;

  @override
  State<RmbDetector> createState() => _RmbDetectorState();
}

class _RmbDetectorState extends State<RmbDetector> {
  int _buttons = 0;

  @override
  Widget build(BuildContext context) {
    return ContextMenuInterceptor(
      child: Listener(
        onPointerDown: (d) => _buttons = d.buttons,
        onPointerUp: (d) {
          if (_buttons & kSecondaryButton != 0) {
            widget.onSecondaryButton?.call();
          }
        },
        child: GestureDetector(
          onLongPress: widget.onSecondaryButton,
          child: widget.child,
        ),
      ),
    );
  }
}
