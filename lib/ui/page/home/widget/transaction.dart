import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';

class TransactionWidget extends StatelessWidget {
  const TransactionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox(
        height: 73,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: Colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: () {},
              hoverColor: style.cardHoveredColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    Icon(
                      Icons.add,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DefaultTextStyle(
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context).textTheme.headlineSmall!,
                            child: Text('\$1023.00'),
                          ),
                          const SizedBox(height: 6),
                          DefaultTextStyle.merge(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            child: Text('Зачисление'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
