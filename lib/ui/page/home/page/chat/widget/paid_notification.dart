import 'package:flutter/material.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/widget_button.dart';

class PaidNotification extends StatelessWidget {
  const PaidNotification({
    super.key,
    this.border,
    this.onPressed,
  });

  final Border? border;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

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
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'Kirey установил '),
                        TextSpan(
                          text: '¤',
                          style: style.systemMessageStyle.copyWith(
                            fontFamily: 'Gapopa',
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 1)),
                        const TextSpan(text: '50'),
                        const TextSpan(text: ' за отправку сообщения и '),
                        TextSpan(
                          text: '¤',
                          style: style.systemMessageStyle.copyWith(
                            fontFamily: 'Gapopa',
                            fontWeight: FontWeight.w300,
                            fontSize: 13,
                          ),
                        ),
                        const WidgetSpan(child: SizedBox(width: 1)),
                        const TextSpan(text: '150'),
                        const TextSpan(text: '/мин за за совершение звонка.'),
                      ],
                    ),
                    style: style.systemMessageStyle,
                  ),
                  // Text(
                  //   'Kirey установил \$5 за отправку сообщения и \$5/мин за совершение звонка.',
                  //   style: style.systemMessageStyle,
                  // ),
                  const SizedBox(height: 8),
                  Text(
                    'Принять и продолжить',
                    style: style.systemMessageStyle.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
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
