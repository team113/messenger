import 'package:flutter/material.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/widget_button.dart';

class PaidNotification extends StatelessWidget {
  const PaidNotification({
    super.key,
    this.border,
    this.onPressed,
    this.description,
    this.action,
    this.accepted = false,
    this.name,
    this.header,
  });

  final bool accepted;
  final Border? border;
  final void Function()? onPressed;

  final String? name;
  final String? header;
  final String? description;
  final String? action;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 0, left: 8, right: 8),
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        boxShadow: const [
          CustomBoxShadow(blurRadius: 8, color: Color(0x22000000)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WidgetButton(
            onPressed: onPressed,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.fromLTRB(
                18,
                18,
                18,
                18,
              ),
              decoration: BoxDecoration(
                border: border,
                borderRadius: style.cardRadius,
                color: Colors.white,
              ),
              child: Column(
                children: [
                  // if (header != null) ...[
                  //   Text(
                  //     header!,
                  //     style: style.fonts.normal.regular.onBackground,
                  //   ),
                  //   const SizedBox(height: 8),
                  // ],
                  Text(
                    description ??
                        'label_payment_price_for_messages_and_calls_to_user'
                            .l10nfmt({'name': name ?? ''}),

                    // 'Kirey установил ¤ 50 за отправку сообщения и ¤ 150/мин за совершение звонка.',
                    style: style.systemMessageStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    action ?? (accepted ? 'Закрыть' : 'Принять и продолжить'),
                    style: style.systemMessageStyle.copyWith(
                      color: style.colors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
