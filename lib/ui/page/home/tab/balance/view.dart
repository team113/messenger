// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/routes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/balance_provider.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/page/home/widget/transaction.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

class BalanceTabView extends StatelessWidget {
  const BalanceTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: BalanceTabController(Get.find(), Get.find()),
      builder: (BalanceTabController c) {
        return Scaffold(
          appBar: CustomAppBar(
            leading: const [SizedBox(width: 21)],
            title: Row(
              children: [
                // const WalletWidget(balance: 0, visible: false),
                // const SizedBox(width: 16),
                Text(
                  'Кошелёк'.l10n,
                  textAlign: TextAlign.center,
                  style: style.fonts.large.regular.onBackground,
                ),
              ],
            ),
            actions: [
              Obx(() {
                return WidgetButton(
                  onPressed: () {},
                  child: Text(
                    '¤ ${c.balance.value.toInt().withSpaces()}',
                    style: style.fonts.big.regular.onBackground
                        .copyWith(color: style.colors.primary),
                  ),
                );
              }),
              const SizedBox(width: 16),
              // AnimatedButton(
              //   onPressed: () {},
              //   decorator: (child) => Padding(
              //     padding: const EdgeInsets.fromLTRB(8, 8, 24, 8),
              //     child: child,
              //   ),
              //   child: const SvgIcon(SvgIcons.transactions),
              // ),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Obx(() {
            if (c.adding.value) {
              return SafeScrollbar(
                controller: c.scrollController,
                child: ListView(
                  controller: c.scrollController,
                  children: [
                    ...BalanceProvider.values.filtered.map((e) {
                      Widget button({
                        required String title,
                        required SvgData asset,
                        double? bonus,
                      }) {
                        final bool selected = router.route == Routes.topUp &&
                            router.balanceSection.value == e;

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: BalanceProviderWidget(
                            title: title,
                            leading: [SvgIcon(asset)],
                            selected: selected,
                            bonus: bonus,
                            onPressed: () => router.topUp(e),
                          ),
                        );
                      }

                      switch (e) {
                        case BalanceProvider.card:
                          return button(
                            asset: SvgIcons.creditCard,
                            title: 'Payment card',
                            bonus: 0,
                          );

                        case BalanceProvider.swift:
                          return button(
                            asset: SvgIcons.swift,
                            title: 'SWIFT transfer',
                            bonus: 0,
                          );

                        case BalanceProvider.sepa:
                          return button(
                            asset: SvgIcons.sepa,
                            title: 'SEPA transfer',
                            bonus: 0,
                          );

                        case BalanceProvider.paypal:
                          return button(
                            asset: SvgIcons.paypal,
                            title: 'PayPal',
                            bonus: 0,
                          );

                        case BalanceProvider.bitcoin:
                          return button(
                            asset: SvgIcons.bitcoin,
                            title: 'Bitcoin',
                            bonus: 5,
                          );

                        case BalanceProvider.usdt:
                          return button(
                            asset: SvgIcons.usdt,
                            title: 'USDT - TRC20',
                            bonus: 5,
                          );

                        // case BalanceProvider.applePay:
                        //   return button(
                        //     asset: SvgIcons.menuNav,
                        //     title: 'Apple Pay',
                        //     bonus: -30,
                        //   );

                        // case BalanceProvider.googlePay:
                        //   return button(
                        //     asset: SvgIcons.menuDevices,
                        //     title: 'Google Pay',
                        //     bonus: -30,
                        //   );

                        // default:
                        //   return const SizedBox();
                      }
                    }),
                  ],
                ),
              );
            }

            return SafeScrollbar(
              controller: c.scrollController,
              child: ListView.builder(
                controller: c.scrollController,
                itemCount: c.transactions.length,
                itemBuilder: (_, i) {
                  final e = c.transactions[i];

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: TransactionWidget(
                      e,
                      // currency: TransactionCurrency.inter,
                    ),
                  );
                },
              ),
            );
          }),
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

extension on Iterable<BalanceProvider> {
  Iterable<BalanceProvider> get filtered {
    return this;
    // return where(
    //   (e) => e != BalanceProvider.googlePay && e != BalanceProvider.applePay,
    // );

    // if (PlatformUtils.isAndroid) {
    //   return where((e) => e == BalanceProvider.googlePay);
    // } else if (PlatformUtils.isIOS) {
    //   return where((e) => e == BalanceProvider.applePay);
    // }

    // return where(
    //   (e) => e != BalanceProvider.googlePay && e != BalanceProvider.applePay,
    // );
  }
}
