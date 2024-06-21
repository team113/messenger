import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';

import '../../../../../../util/platform_utils.dart';
import '../../../../../widget/animated_button.dart';
import '../../my_profile/widget/line_divider.dart';
import '/ui/page/home/widget/copy_or_share.dart';
import '../../../../../../l10n/l10n.dart';
import '../../../../../widget/svg/svg.dart';
import '/themes.dart';
import '/domain/service/balance.dart';

class TransactionWidget extends StatelessWidget {
  const TransactionWidget(
    this.transaction, {
    super.key,
    this.expanded = true,
    this.id,
  });

  final String? id;
  final Transaction transaction;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool positive = transaction.amount >= 0;
    final bool hold = transaction.status == TransactionStatus.hold;
    final bool canceled = transaction.status == TransactionStatus.canceled;

    TableRow row(String label, Widget child) {
      return TableRow(
        children: [
          Text(
            label,
            style: style.fonts.normal.regular.secondary,
            textAlign: TextAlign.right,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle(
                style: style.fonts.normal.regular.secondary.copyWith(
                  color: style.colors.secondaryBackgroundLight,
                ),
                child: child,
              ),
            ),
          ),
        ],
      );
    }

    final List<Widget> more = [
      const SizedBox(height: 8),
      const LineDivider('Детали'),
      const SizedBox(height: 16),
      Table(
        columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
        children: [
          row(
            'Статус',
            Text(
              switch (transaction.status) {
                TransactionStatus.hold => 'Ожидает зачисления: 31 дней',
                TransactionStatus.canceled => 'Отменено',
                TransactionStatus.done => 'Зачислено: ${transaction.at.yMd}',
              },
            ),
          ),
          row(
            'Transaction ID',
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(id ?? transaction.id),
                const SizedBox(width: 8),
                CopyOnlyButton(id ?? transaction.id),
              ],
            ),
          ),
          if (transaction.by != null) row('Благодаря', Text(transaction.by!)),
          if (transaction.description != null)
            row('Подробнее', Text(transaction.description!)),
          if (transaction.reason != null)
            row('Причина', Text(transaction.reason!)),
        ],
      ),
      Align(
        alignment: Alignment.centerRight,
        child: AnimatedButton(
          onPressed: () {},
          child: Text(
            'Report',
            style: style.fonts.smaller.regular.secondary
                .copyWith(color: style.colors.primary),
          ),
        ),
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        color: canceled
            ? const Color.fromARGB(255, 239, 239, 239)
            : positive
                ? hold
                    ? style.unreadMessageColor
                    : style.readMessageColor
                : const Color.fromARGB(255, 255, 255, 255),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text:
                              '${positive ? '+' : '-'} \$${transaction.amount.abs().toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    style: style.fonts.big.regular.onBackground.copyWith(
                      fontWeight: FontWeight.bold,
                      color: canceled
                          ? style.colors.danger
                          : positive
                              ? const Color.fromARGB(255, 22, 113, 45)
                              : style.colors.secondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AnimatedOpacity(
                opacity: expanded ? 1 : 0,
                duration: const Duration(milliseconds: 250),
                child: Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    transaction.at.yMd,
                    style: style.fonts.small.regular.secondary,
                  ),
                ),
              ),
              Text(
                transaction.at.hms,
                style: style.fonts.small.regular.secondary,
              ),
              const SizedBox(width: 8),
              Transform.translate(
                offset: Offset(0, PlatformUtils.isWeb ? -1 : 0),
                child: SvgIcon(
                  switch (transaction.status) {
                    TransactionStatus.hold => SvgIcons.sending,
                    TransactionStatus.canceled => SvgIcons.error,
                    TransactionStatus.done => SvgIcons.read,
                  },
                ),
              )
            ],
          ),
          Stack(
            children: [
              AnimatedSizeAndFade.showHide(
                show: expanded,
                fadeDuration: const Duration(milliseconds: 250),
                sizeDuration: const Duration(milliseconds: 250),
                child: Column(children: more),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
