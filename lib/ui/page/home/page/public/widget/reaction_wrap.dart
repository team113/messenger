import 'dart:math';

import 'package:flutter/material.dart';

class ReactionWrap extends StatelessWidget {
  const ReactionWrap({
    Key? key,
    required this.width,
    required this.children,
  }) : super(key: key);

  final double width;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double totalWidth = children.length * width;
        final int columns = totalWidth ~/ constraints.maxWidth + 1;
        final int maxItems = (totalWidth / constraints.maxWidth).floor();

        final List<Widget> rows = [];

        for (int i = 0; i < columns; ++i) {
          final int from = i * maxItems;
          final int to = from + min(maxItems, children.length);

          rows.add(
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: children.sublist(from, to),
            ),
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}
