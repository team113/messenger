// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/themes.dart';

import '/routes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/balance_provider.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/page/home/widget/transaction.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

class BalanceTabView extends StatelessWidget {
  const BalanceTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return GetBuilder(
      init: BalanceTabController(Get.find()),
      builder: (BalanceTabController c) {
        return Scaffold(
          // extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Text('Balance:  ¤${c.balance.value.toInt()}'),
            leading: [
              Obx(() {
                final Widget child;

                if (c.adding.value) {
                  child = SvgImage.asset(
                    'assets/icons/info.svg',
                    width: 20,
                    height: 20,
                  );
                } else {
                  child = SvgImage.asset(
                    key: const Key('Search'),
                    'assets/icons/search.svg',
                    width: 17.77,
                  );
                }

                return WidgetButton(
                  onPressed: c.hintDismissed.toggle,
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    height: double.infinity,
                    child: child,
                  ),
                );
              }),
            ],
            actions: [
              Obx(() {
                final Widget child;

                if (c.adding.value) {
                  child = Transform.translate(
                    offset: const Offset(0, -1),
                    child: SizedBox(
                      child: SvgImage.asset(
                        'assets/icons/transactions.svg',
                        width: 19,
                        height: 19.42,
                      ),
                    ),
                  );
                } else {
                  child = SvgImage.asset(
                    key: const Key('CloseSearch'),
                    'assets/icons/add_funds.svg',
                    height: 19.94,
                  );
                }

                return WidgetButton(
                  onPressed: c.adding.toggle,
                  child: Container(
                    padding: const EdgeInsets.only(left: 12, right: 20),
                    height: double.infinity,
                    child: SizedBox(width: 20.28, child: Center(child: child)),
                  ),
                );
              }),
            ],
          ),
          body: Obx(() {
            if (c.adding.value) {
              return SafeScrollbar(
                controller: c.scrollController,
                child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: [
                      Obx(() {
                        return AnimatedSizeAndFade.showHide(
                          show: !c.hintDismissed.value,
                          child: Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ModalPopupHeader(
                                    close: true,
                                    onClose: c.hintDismissed.toggle,
                                    header: Center(
                                      child: Text(
                                        'What is  ¤ (Gapopa coin)?',
                                        style: fonts.headlineMedium,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      32,
                                      12,
                                      32,
                                      18,
                                    ),
                                    child: Center(
                                      child: Text(
                                        ' ¤ (Gapopa coin) is an internal currency for purchasing services offered by Gapopa.\n\n ¤100 = €1.00',
                                        style: fonts.labelLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                      ...BalanceProvider.values.map((e) {
                        Widget button({
                          required String title,
                          required IconData icon,
                        }) {
                          return BalanceProviderWidget(
                            title: title,
                            leading: [Icon(icon)],
                            onTap: () => router.balance(e),
                          );
                        }

                        switch (e) {
                          case BalanceProvider.creditCard:
                            return button(
                              icon: Icons.credit_card,
                              title: 'Credit card',
                            );

                          case BalanceProvider.swift:
                            return button(
                              icon: Icons.account_balance,
                              title: 'SWIFT transfer',
                            );

                          case BalanceProvider.sepa:
                            return button(
                              icon: Icons.account_balance,
                              title: 'SEPA transfer',
                            );

                          case BalanceProvider.paypal:
                            return button(
                              icon: Icons.paypal,
                              title: 'PayPal',
                            );

                          default:
                            return const SizedBox();
                        }
                      }),
                    ]),
              );
            }

            return SafeScrollbar(
              controller: c.scrollController,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  ...c.transactions.map((e) {
                    return TransactionWidget(
                      e,
                      currency: TransactionCurrency.inter,
                    );
                  }),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
