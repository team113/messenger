import 'package:flutter/material.dart';

import '/ui/page/home/widget/avatar.dart';

/// Animated [CircleAvatar] representing selection circle.
class SelectedDot extends StatelessWidget {
  const SelectedDot({
    super.key,
    this.selected = false,
    this.size = 24,
    this.darken = 0,
  });

  final bool selected;

  final double size;

  final double darken;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: selected
            ? CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                radius: size / 2,
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 14,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD7D7D7).darken(darken),
                    width: 1,
                  ),
                ),
                width: size,
                height: size,
              ),
      ),
    );
  }
}
