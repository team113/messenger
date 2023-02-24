import 'package:flutter/material.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/service/partner.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/tab/chats/widget/recent_chat.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

class TransactionWidget extends StatelessWidget {
  const TransactionWidget(this.transaction, {super.key});

  final Transaction transaction;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    final Widget status;

    switch (transaction.status) {
      case TransactionStatus.failed:
        status = SvgLoader.asset(
          'assets/icons/transaction_error.svg',
          width: 20,
          height: 20,
        );
        break;

      case TransactionStatus.pending:
        status = const Icon(
          Icons.circle_outlined,
          size: 28,
          color: Color(0xFF888888),
        );
        break;

      case TransactionStatus.success:
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
        break;
    }

    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Container(
        constraints: const BoxConstraints(minHeight: 73),
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
            onTap: () => router.transaction(transaction.id),
            hoverColor: style.cardHoveredColor,
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
                              child: DefaultTextStyle(
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style:
                                    Theme.of(context).textTheme.headlineSmall!,
                                child: Text('\$${transaction.amount.abs()}'),
                              ),
                            ),
                            Text(
                              transaction.at.toShort(),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text('SWIFT transfer'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
