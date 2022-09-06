import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Listening for clicks on the [Widget] and pass the event to [isTapMessage].
class ListenerWidget extends StatelessWidget {
  const ListenerWidget({
    Key? key,
    required this.isTapMessage,
    required this.child,
  }) : super(key: key);

  /// Event clicking.
  final Rx<bool> isTapMessage;

  /// Widget listening.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) {
        if (!isTapMessage.value) {
          isTapMessage.value = true;
        }
      },
      onPointerUp: (_) {
        if (isTapMessage.value) {
          isTapMessage.value = false;
        }
      },
      onPointerCancel: (_) {
        if (isTapMessage.value) {
          isTapMessage.value = false;
        }
      },
      child: child,
    );
  }
}
