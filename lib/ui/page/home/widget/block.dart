import 'package:flutter/material.dart';

import '/themes.dart';
import '/util/platform_utils.dart';

/// Stylized grouped section of the provided [children].
class Block extends StatelessWidget {
  const Block({
    super.key,
    this.children = const [],
    required this.title,
  });

  /// Header of this [Block].
  final String title;

  /// [Widget]s to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          border: style.primaryBorder,
          color: style.messageColor,
          borderRadius: BorderRadius.circular(15),
        ),
        constraints:
            context.isNarrow ? null : const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
                child: Center(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      title,
                      style: style.systemMessageStyle
                          .copyWith(color: Colors.black, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ...children,
          ],
        ),
      ),
    );
  }
}
