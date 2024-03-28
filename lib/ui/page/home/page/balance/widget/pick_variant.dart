import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/selected_dot.dart';

class PickVariantButton extends StatelessWidget {
  const PickVariantButton({
    super.key,
    required this.price,
    this.amount = 0,
    this.onPressed,
    this.selected = false,
    this.bonus = 0.05,
  });

  final String price;
  final num amount;
  final void Function()? onPressed;
  final bool selected;
  final double bonus;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: SizedBox(
        height: 73, //dense ? 54 : 73,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: style.colors.transparent,
          ),
          child: Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: selected ? style.colors.primary : style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: onPressed,
              hoverColor:
                  selected ? style.colors.primary : style.cardHoveredColor,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    const SizedBox(width: 6.5),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: '¤${amount.withSpaces()}',
                                  style: selected
                                      ? style.fonts.big.regular.onPrimary
                                      : style.fonts.big.regular.onBackground
                                          .copyWith(
                                          color: style.colors.acceptPrimary,
                                        ),
                                ),
                                TextSpan(
                                  text: ' for ',
                                  style: selected
                                      ? style.fonts.big.regular.onPrimary
                                      : style.fonts.big.regular.secondary,
                                ),
                                TextSpan(
                                  text: price,
                                  style: selected
                                      ? style.fonts.big.regular.onPrimary
                                      : style.fonts.big.regular.onBackground,
                                ),
                              ],
                            ),
                          ),
                          if (bonus != 0) ...[
                            const SizedBox(height: 3),
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Bonus: ',
                                    style: selected
                                        ? style.fonts.small.regular.onPrimary
                                        : style.fonts.small.regular.secondary,
                                  ),
                                  TextSpan(
                                    text:
                                        '¤${(amount * bonus).round().withSpaces()}',
                                    style: selected
                                        ? style.fonts.small.regular.onPrimary
                                        : style.fonts.small.regular.onBackground
                                            .copyWith(
                                            color: style.colors.acceptPrimary,
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    SelectedDot(size: 21, selected: selected),
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

extension on num {
  String withSpaces([bool zeros = false]) {
    if (!zeros) {
      return NumberFormat('#,##0').format(this);
    }

    return NumberFormat('#,##0.00').format(this);
  }
}
