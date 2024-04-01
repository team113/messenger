import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/user/widget/money_field.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/text_field.dart';

import 'controller.dart';
import 'withdraw_method/view.dart';

class WithdrawView extends StatelessWidget {
  const WithdrawView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: WithdrawController(Get.find()),
      builder: (WithdrawController c) {
        return Scaffold(
          appBar: const CustomAppBar(
            padding: EdgeInsets.only(left: 4, right: 20),
            leading: [StyledBackButton()],
            title: Text('Заказ выплаты'),
          ),
          body: ListView(
            shrinkWrap: true,
            children: [
              Block(
                title: 'Получатель средств',
                children: [
                  const SizedBox(height: 8),
                  MoneyField(
                    state: c.money,
                    onChanged: (e) => c.amount.value = e,
                    label: 'Сумма',
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    label: 'Имя или название',
                    state: TextFieldState(),
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    label: 'Адрес',
                    state: TextFieldState(),
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    label: 'E-mail',
                    state: TextFieldState(),
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    label: 'Телефон',
                    state: TextFieldState(),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
              Block(
                title: 'Способ выплаты',
                children: [
                  Obx(() {
                    return FieldButton(
                      text: c.method.value.name,
                      headline: Text('Способ'.l10n),
                      onPressed: () async {
                        await WithdrawMethodView.show(
                          context,
                          initial: c.method.value,
                          onChanged: (e) => c.method.value = e,
                        );
                      },
                      style: style.fonts.normal.regular.primary,
                    );
                  }),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Obx(() {
                        final amount = switch (c.method.value) {
                          WithdrawMethod.card ||
                          WithdrawMethod.paypal ||
                          WithdrawMethod.swift =>
                            '\$${(c.amount.value / 100).toStringAsFixed(2)}',
                          WithdrawMethod.sepa =>
                            '€${(c.amount.value / 110).toStringAsFixed(2)}',
                          WithdrawMethod.usdt =>
                            '${(c.amount.value / 100).toStringAsFixed(2)} USDT',
                          WithdrawMethod.bitcoin =>
                            '${c.amount.value / 100000000} BTC',
                        };

                        return Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'К отправке: ',
                                style: style.fonts.normal.regular.secondary,
                              ),
                              TextSpan(
                                text: amount,
                                style: style.fonts.medium.regular.onBackground,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.start,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 8),
                  PrimaryButton(
                    title: 'btn_proceed'.l10n,
                    onPressed: () {},
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
