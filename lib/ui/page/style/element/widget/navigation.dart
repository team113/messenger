import 'package:flutter/material.dart';

import '/themes.dart';

class NavigationWidget extends StatelessWidget {
  const NavigationWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: style.colors.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}
