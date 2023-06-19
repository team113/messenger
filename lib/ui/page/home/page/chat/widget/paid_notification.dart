import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/widget_button.dart';

class PaidNotification extends StatelessWidget {
  const PaidNotification({
    super.key,
    this.border,
    this.onPressed,
    this.accepted = false,
  });

  final bool accepted;
  final Border? border;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      margin: const EdgeInsets.only(top: 0, bottom: 6, left: 8, right: 8),
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
                // color: style.systemMessageColor,
              ),
              child: Column(
                children: [
                  Text(
                    'Kirey установил 50 ¤ за отправку сообщения и 150 ¤/мин за совершение звонка.',
                    style: style.systemMessageStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    accepted ? 'Закрыть' : 'Принять и продолжить',
                    style: style.systemMessageStyle.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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
