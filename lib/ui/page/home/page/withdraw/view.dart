import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/balance/widget/currency_field.dart';
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
          appBar: CustomAppBar(
            padding: const EdgeInsets.only(left: 4, right: 20),
            leading: const [StyledBackButton()],
            title: Row(
              children: [
                const SizedBox(width: 8),
                // const Expanded(child: Text('Вывести деньги')),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, snapshot) {
                      final double occupies = 'Вывести деньги'.l10n.length * 12;

                      if (occupies >= snapshot.maxWidth) {
                        return Text(
                          'Вывести\nденьги'.l10n,
                          textAlign: TextAlign.left,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: style.fonts.medium.regular.onBackground
                              .copyWith(height: 1),
                        );
                      }

                      return Text(
                        'Вывести деньги'.l10n,
                        textAlign: TextAlign.left,
                        style: style.fonts.large.regular.onBackground,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                ),
                Obx(() {
                  return Text(
                    '¤ ${c.balance.value.toInt().withSpaces()}',
                    style: style.fonts.big.regular.onBackground.copyWith(
                      color: style.colors.acceptPrimary,
                    ),
                  );
                }),
              ],
            ),
          ),
          body: ListView(
            shrinkWrap: true,
            children: [
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
                ],
              ),
              Block(
                title: 'Реквизиты',
                children: [
                  const SizedBox(height: 8),
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
                children: [
                  const SizedBox(height: 8),
                  MoneyField(
                    state: c.coins,
                    onChanged: (e) {
                      c.amount.value = e;
                      c.recalculateAmount();
                    },
                    label: 'Сумма',
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    return CurrencyField(
                      currency: switch (c.method.value) {
                        WithdrawMethod.card ||
                        WithdrawMethod.paypal ||
                        WithdrawMethod.swift =>
                          CurrencyKind.usd,
                        WithdrawMethod.sepa => CurrencyKind.eur,
                        WithdrawMethod.usdt => CurrencyKind.usdt,
                        WithdrawMethod.bitcoin => CurrencyKind.btc,
                      },
                      value: c.total.value,
                      onChanged: (e) {
                        c.total.value = e.toDouble();
                        c.recalculateTotal();
                      },
                    );
                  }),
                  const SizedBox(height: 16),
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

extension on int {
  String withSpaces() {
    return NumberFormat('#,##0').format(this);
  }
}
