import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

class LineDivider extends StatelessWidget {
  const LineDivider(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Row(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            height: 0.5,
            color: Colors.black26,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: style.fonts.small.regular.secondary,
          textAlign: TextAlign.center,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            width: double.infinity,
            height: 0.5,
            color: Colors.black26,
          ),
        ),
      ],
    );
  }
}
