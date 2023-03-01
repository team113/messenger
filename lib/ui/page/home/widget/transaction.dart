import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/hovered_ink.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/recent_chat.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

enum TransactionCurrency { dollar, inter }

class TransactionWidget extends StatelessWidget {
  const TransactionWidget(
    this.transaction, {
    super.key,
    this.currency = TransactionCurrency.dollar,
  });

  final TransactionCurrency currency;
  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final Widget status;

    if (transaction is IncomingTransaction) {
      status = SvgLoader.asset(
        'assets/icons/transaction_in.svg',
        width: 20,
        height: 20,
      );
    } else {
      status = SvgLoader.asset(
        'assets/icons/transaction_out.svg',
        width: 20,
        height: 20,
      );
    }

    return Obx(() {
      final bool selected =
          router.route == '${Routes.transaction}/${transaction.id}';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Container(
          constraints: const BoxConstraints(minHeight: 73),
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            border: style.cardBorder,
            color: Colors.transparent,
          ),
          child: InkWellWithHover(
            borderRadius: style.cardRadius,
            selectedColor: style.cardSelectedColor,
            unselectedColor: style.cardColor,
            onTap: () => router.transaction(transaction.id),
            selected: selected,
            hoveredBorder:
                selected ? style.primaryBorder : style.cardHoveredBorder,
            border: selected ? style.primaryBorder : style.cardBorder,
            unselectedHoverColor: style.cardHoveredColor,
            selectedHoverColor: style.cardSelectedColor,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const SizedBox(width: 6),
                  status,
                  const SizedBox(width: 12),
                  // const SizedBox(width: 12),
                  // Icon(
                  //   Icons.add,
                  //   color: Theme.of(context).colorScheme.secondary,
                  // ),
                  // const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            // SvgLoader.asset(
                            //   'assets/icons/inter.svg',
                            //   height: 13,
                            // ),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    if (currency == TransactionCurrency.dollar)
                                      const TextSpan(text: '\$')
                                    else if (currency ==
                                        TransactionCurrency.inter)
                                      TextSpan(
                                        text: '¤',
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall
                                            ?.copyWith(
                                              height: 0.8,
                                              fontFamily: 'InterRoboto',
                                              fontWeight: FontWeight.w300,
                                            ),
                                      ),
                                    const WidgetSpan(child: SizedBox(width: 2)),
                                    TextSpan(
                                      text: '${transaction.amount.abs()}',
                                    ),
                                  ],
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w300,
                                      ),
                                ),
                              ),
                            ),
                            Text(
                              transaction.at.toShort(),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Expanded(child: Text('SWIFT transfer')),
                            Text(
                              '${transaction.status.name.capitalizeFirst}',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    color: transaction.status ==
                                            TransactionStatus.failed
                                        ? Colors.red
                                        : null,
                                    fontSize: 13,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }
}
