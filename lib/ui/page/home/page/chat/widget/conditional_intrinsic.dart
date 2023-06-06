import 'package:flutter/material.dart';

class ConditionalIntrinsicWidth extends StatelessWidget {
  const ConditionalIntrinsicWidth({
    super.key,
    this.condition = true,
    required this.child,
  });

  final bool condition;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!condition) {
      return child;
    }

    return IntrinsicWidth(child: child);
  }
}
