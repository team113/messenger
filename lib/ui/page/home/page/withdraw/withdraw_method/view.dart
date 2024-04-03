import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/page/home/widget/rectangle_button.dart';
import 'package:messenger/ui/widget/modal_popup.dart';

import 'controller.dart';

class WithdrawMethodView extends StatelessWidget {
  const WithdrawMethodView({
    super.key,
    this.initial = WithdrawMethod.usdt,
    this.onChanged,
  });

  final WithdrawMethod initial;
  final void Function(WithdrawMethod)? onChanged;

  /// Displays a [ConfirmLogoutView] wrapped in a [ModalPopup].
  static Future<WithdrawMethod?> show<T>(
    BuildContext context, {
    WithdrawMethod initial = WithdrawMethod.usdt,
    void Function(WithdrawMethod)? onChanged,
  }) {
    return ModalPopup.show(
      context: context,
      child: WithdrawMethodView(initial: initial, onChanged: onChanged),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: WithdrawMethodController(initial: initial),
      builder: (WithdrawMethodController c) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ModalPopupHeader(text: 'Способ выплаты'),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: ModalPopup.padding(context),
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: WithdrawMethod.values.length,
                itemBuilder: (_, i) {
                  return Obx(() {
                    final WithdrawMethod e = WithdrawMethod.values[i];

                    final bool selected = c.method.value == e;

                    return RectangleButton(
                      selected: selected,
                      onPressed: selected
                          ? null
                          : () {
                              c.method.value = e;
                              onChanged?.call(e);
                            },
                      label: e.l10n,
                    );
                  });
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
