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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/widget/animated_button.dart';

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
  const BalanceTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: BalanceTabController(Get.find(), Get.find()),
      builder: (BalanceTabController c) {
        return Scaffold(
          // extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Text('Balance:  ¤${c.balance.value.toInt()}'),
            leading: [
              Obx(() {
                final Widget child;

                if (c.adding.value) {
                  if (c.hintDismissed.value) {
                    child = const SvgIcon(SvgIcons.rate);
                  } else {
                    child = const SvgIcon(SvgIcons.rateDisabled);
                  }

                  return AnimatedButton(
                    onPressed: () {
                      c.hintDismissed.toggle();
                      c.setDisplayRates(!c.hintDismissed.value);
                    },
                    decorator: (child) => Container(
                      padding: const EdgeInsets.only(left: 20, right: 12),
                      height: double.infinity,
                      child: child,
                    ),
                    child: child,
                  );
                } else {
                  child = const SvgIcon(key: Key('Search'), SvgIcons.search);
                  return AnimatedButton(
                    onPressed: () {},
                    decorator: (child) => Container(
                      padding: const EdgeInsets.only(left: 20, right: 12),
                      height: double.infinity,
                      child: child,
                    ),
                    child: child,
                  );
                }
              }),
            ],
            actions: [
              Obx(() {
                final Widget child;

                if (c.adding.value) {
                  child = Transform.translate(
                    offset: const Offset(0, -1),
                    child: const SizedBox(
                      child: SvgIcon(SvgIcons.transactions),
                    ),
                  );
                } else {
                  child = const SvgImage.asset(
                    key: Key('CloseSearch'),
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

          extendBodyBehindAppBar: true,

          body: Obx(() {
            if (c.adding.value) {
              return SafeScrollbar(
                controller: c.scrollController,
                child: ListView(
                  controller: c.scrollController,
                  children: [
                    Obx(() {
                      return AnimatedSizeAndFade.showHide(
                        show: !c.hintDismissed.value,
                        child: Center(
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: style.cardBorder,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ModalPopupHeader(
                                  close: true,
                                  onClose: () {
                                    c.hintDismissed.toggle();
                                    c.setDisplayRates(!c.hintDismissed.value);
                                  },
                                  text: '¤100 = €1.00',
                                ),
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    32,
                                    0,
                                    32,
                                    0,
                                  ),
                                  child: Center(
                                    child: Text(
                                      'Rate for ${DateTime.now().yMd}.',
                                      style:
                                          style.fonts.small.regular.secondary,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    // Padding(
                    //   padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                    //   child: Center(
                    //       child: Text('Add funds',
                    //           style: style.fonts.big.regular.onBackground)),
                    // ),
                    // Center(
                    //   child: Container(
                    //     // width: double.infinity,
                    //     margin: const EdgeInsets.fromLTRB(8, 12, 8, 12),
                    //     padding: const EdgeInsets.symmetric(
                    //       horizontal: 12,
                    //       vertical: 8,
                    //     ),
                    //     decoration: BoxDecoration(
                    //       borderRadius: BorderRadius.circular(15),
                    //       border: style.systemMessageBorder,
                    //       color: style.systemMessageColor,
                    //     ),
                    //     child: Text(
                    //       'Add funds',
                    //       style: style.systemMessageStyle,
                    //     ),
                    //   ),
                    // ),
                    ...BalanceProvider.values.map((e) {
                      Widget button({
                        required String title,
                        required SvgData asset,
                        // required IconData icon,
                        double? bonus,
                      }) {
                        final bool selected = router.route
                            .startsWith('${Routes.balance}/${e.name}');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1.5),
                          child: BalanceProviderWidget(
                            title: title,
                            leading: [
                              SvgIcon(asset),
                              // Icon(
                              //   icon,
                              //   size: 42,
                              //   color: selected
                              //       ? style.colors.onPrimary
                              //       : style.colors.primary,
                              // )
                            ],
                            selected: selected,
                            bonus: bonus,
                            onPressed: () => router.balance(e),
                          ),
                        );
                      }

                      switch (e) {
                        case BalanceProvider.creditCard:
                          return button(
                            asset: SvgIcons.menuPayment,
                            title: 'Credit card',
                            bonus: 5,
                          );

                        case BalanceProvider.swift:
                          return button(
                            asset: SvgIcons.menuCalls,
                            title: 'SWIFT transfer',
                            bonus: 2,
                          );

                        case BalanceProvider.sepa:
                          return button(
                            asset: SvgIcons.menuLink,
                            title: 'SEPA transfer',
                            bonus: 2,
                          );

                        case BalanceProvider.paypal:
                          return button(
                            asset: SvgIcons.menuBackground,
                            title: 'PayPal',
                            bonus: -5,
                          );

                        default:
                          return const SizedBox();
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
                      currency: TransactionCurrency.inter,
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
