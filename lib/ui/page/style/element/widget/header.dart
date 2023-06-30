import 'package:flutter/material.dart';

import '/themes.dart';

class Header extends StatelessWidget {
  const Header({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (_, fonts) = Theme.of(context).styles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          label,
          style: fonts.displayLarge!.copyWith(color: const Color(0xFF1F3C5D)),
        ),
      ],
    );
  }
}

class SmallHeader extends StatelessWidget {
  const SmallHeader({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final (_, fonts) = Theme.of(context).styles;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 70),
        Text(
          label,
          style: fonts.headlineLarge!.copyWith(color: const Color(0xFF1F3C5D)),
        ),
      ],
    );
  }
}
