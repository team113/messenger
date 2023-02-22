import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';

class MoneyProviderWidget extends StatelessWidget {
  const MoneyProviderWidget({
    super.key,
    required this.title,
    this.selected = false,
    this.onTap,
    this.leading = const [],
  });

  final String title;
  final bool selected;
  final void Function()? onTap;

  final List<Widget> leading;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return SizedBox(
      height: 94,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: InkWellWithHover(
          selectedColor: style.cardSelectedColor,
          unselectedColor: style.cardColor,
          selected: selected,
          hoveredBorder:
              selected ? style.primaryBorder : style.cardHoveredBorder,
          border: selected ? style.primaryBorder : style.cardBorder,
          borderRadius: style.cardRadius,
          onTap: onTap,
          unselectedHoverColor: style.cardHoveredColor,
          selectedHoverColor: style.cardSelectedColor,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
            child: Row(
              children: [
                const SizedBox(width: 12),
                ...leading.map(
                  (e) => IconTheme(
                    data: IconThemeData(
                      size: 48,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    child: e,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                          ),
                          // ...status,
                        ],
                      ),
                      // ...subtitle,
                    ],
                  ),
                ),
                // ...trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
