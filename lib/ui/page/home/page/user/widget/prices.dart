import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/widget_button.dart';

class Prices extends StatelessWidget {
  const Prices({
    this.messages = 0,
    this.calls = 0,
    this.onMessagesPressed,
    this.onCallsPressed,
    super.key,
  });

  final int messages;
  final int calls;

  final void Function()? onMessagesPressed;
  final void Function()? onCallsPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final TextStyle acceptStyle =
        style.fonts.medium.regular.onBackground.copyWith(
      color: style.colors.acceptPrimary,
    );

    return Table(
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      columnWidths: const {0: FlexColumnWidth(), 1: IntrinsicColumnWidth()},
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Входящее сообщение:',
                style: style.fonts.medium.regular.onBackground,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: messages == 0
                  ? WidgetButton(
                      onPressed: onMessagesPressed,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¤',
                            style: onMessagesPressed == null
                                ? acceptStyle
                                : style.fonts.medium.regular.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '0',
                            style: onMessagesPressed == null
                                ? acceptStyle
                                : style.fonts.medium.regular.primary,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('¤', style: acceptStyle),
                        const SizedBox(width: 2),
                        Text(messages.withSpaces(), style: acceptStyle),
                      ],
                    ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'за 1 сообщение',
                style: style.fonts.small.regular.secondary,
              ),
            ),
            const SizedBox(),
          ],
        ),
        const TableRow(
          children: [SizedBox(height: 8), SizedBox(height: 8)],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'Входящий звонок:',
                style: style.fonts.medium.regular.onBackground,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: calls == 0
                  ? WidgetButton(
                      onPressed: onCallsPressed,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '¤',
                            style: onCallsPressed == null
                                ? acceptStyle
                                : style.fonts.medium.regular.primary,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            '0',
                            style: onCallsPressed == null
                                ? acceptStyle
                                : style.fonts.medium.regular.primary,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('¤', style: acceptStyle),
                        const SizedBox(width: 2),
                        Text(calls.withSpaces(), style: acceptStyle),
                      ],
                    ),
            ),
          ],
        ),
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                'за 1 минуту',
                style: style.fonts.small.regular.secondary,
              ),
            ),
            const SizedBox(),
          ],
        ),
      ],
    );
  }
}

extension on int {
  String withSpaces() {
    // final parsed = int.tryParse(this);
    // if (parsed != null) {
    return NumberFormat('#,##0').format(this);
    // }

    // return replaceAllMapped(RegExp(r'.{3}'), (match) => '${match.group(0)} ');
  }
}
