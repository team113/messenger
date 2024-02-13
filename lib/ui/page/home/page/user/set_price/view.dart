import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

class SetPriceView2 extends StatelessWidget {
  const SetPriceView2({
    super.key,
    this.initialCalls,
    this.initialMessages,
  });

  final String? initialCalls;
  final String? initialMessages;

  /// Displays a [SetPriceView2] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    String? initialCalls,
    String? initialMessages,
  }) {
    return ModalPopup.show(
      context: context,
      child: SetPriceView2(
        initialCalls: initialCalls,
        initialMessages: initialMessages,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: SetPriceController(
        initialCalls: initialCalls,
        initialMessages: initialMessages,
      ),
      builder: (SetPriceController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalPopupHeader(text: 'Установить цену'),
            const SizedBox(height: 21),
            Padding(
              padding: ModalPopup.padding(context),
              child: ReactiveTextField(
                state: c.messages,
                style: style.fonts.medium.regular.onBackground,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '0',
                prefix: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
                  child: Transform.translate(
                    offset: PlatformUtils.isWeb
                        ? const Offset(0, -0)
                        : const Offset(0, -0.5),
                    child: Text(
                      '¤',
                      style: style.fonts.medium.regular.onBackground,
                    ),
                  ),
                ),
                label: 'Входящие сообщения, за 1 сообщение',
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: ModalPopup.padding(context),
              child: ReactiveTextField(
                state: c.calls,
                style: style.fonts.medium.regular.onBackground,
                floatingLabelBehavior: FloatingLabelBehavior.always,
                formatters: [FilteringTextInputFormatter.digitsOnly],
                hint: '0',
                prefix: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 0, 1, 0),
                  child: Transform.translate(
                    offset: PlatformUtils.isWeb
                        ? const Offset(0, -0)
                        : const Offset(0, -0.5),
                    child: Text(
                      '¤',
                      style: style.fonts.medium.regular.onBackground,
                    ),
                  ),
                ),
                label: 'Входящие звонки, за 1 минуту',
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: ModalPopup.padding(context),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      title: 'Отменить',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: PrimaryButton(
                      onPressed: () => Navigator.of(context).pop(
                        MapEntry(
                          c.calls.text,
                          c.messages.text,
                        ),
                      ),
                      title: 'Сохранить',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}
