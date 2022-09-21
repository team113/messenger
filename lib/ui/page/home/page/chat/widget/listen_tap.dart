import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ListenTap extends StatelessWidget {
  const ListenTap({
    super.key,
    this.isTap,
    required this.child,
  });

  /// Indicator whether tap on [child].
  final Rx<bool>? isTap;

  /// [Widget] for taps.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => isTap?.value = true,
      onPointerUp: (_) => isTap?.value = false,
      onPointerCancel: (_) => isTap?.value = false,
      child: child,
    );
  }
}
