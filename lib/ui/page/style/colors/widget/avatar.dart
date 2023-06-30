import 'package:flutter/material.dart';

import '/themes.dart';
import 'color.dart';

class AvatarColors extends StatelessWidget {
  const AvatarColors({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return Container(
      decoration: BoxDecoration(
        color: style.colors.onPrimary,
        borderRadius: BorderRadius.circular(12),
      ),
      width: MediaQuery.sizeOf(context).width,
      child: Column(
        children: [
          const SizedBox(height: 30),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 16,
            runSpacing: 16,
            children: List.generate(
              style.colors.userColors.length,
              (i) => CustomColor(
                title: '',
                false,
                style.colors.userColors[i],
              ),
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
