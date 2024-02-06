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
                  if (c.hintDismissed.value) {
                    child = const SvgIcon(SvgIcons.infoThick);
                  } else {
                    child = const SvgIcon(SvgIcons.infoThickDisabled);
                  }

                  return AnimatedButton(
                    onPressed: c.hintDismissed.toggle,
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
                                      'Текущий курс на ${DateTime.now().yMd}.',
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
                    ...BalanceProvider.values.map((e) {
                      Widget button({
                        required String title,
                        required IconData icon,
                      }) {
                        final bool selected = router.route
                            .startsWith('${Routes.balance}/${e.name}');

                        return BalanceProviderWidget(
                          title: title,
                          leading: [Icon(icon)],
                          selected: selected,
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
                  ],
                ),
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
