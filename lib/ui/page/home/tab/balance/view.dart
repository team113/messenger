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
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/balance_provider.dart';
import 'package:messenger/ui/page/home/widget/transaction.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import 'controller.dart';

class BalanceTabView extends StatelessWidget {
  const BalanceTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: BalanceTabController(),
      builder: (BalanceTabController c) {
        return Scaffold(
          appBar: CustomAppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Balance: '),
                SvgLoader.asset(
                  'assets/icons/inter.svg',
                  height: 13,
                ),
                const SizedBox(width: 1),
                const Text('1000'),
              ],
            ),
            leading: [
              WidgetButton(
                onPressed: c.hintDismissed.toggle,
                child: Container(
                  padding: const EdgeInsets.only(left: 20, right: 12),
                  height: double.infinity,
                  child: SvgLoader.asset(
                    'assets/icons/info.svg',
                    width: 20,
                    height: 20,
                  ),
                ),
              ),
            ],
            actions: [
              Obx(() {
                final Widget child;

                if (c.adding.value) {
                  child = Transform.translate(
                    offset: const Offset(0, -1),
                    child: SizedBox(
                      child: SvgLoader.asset(
                        'assets/icons/transactions.svg',
                        width: 19,
                        height: 19.42,
                      ),
                    ),
                  );
                } else {
                  child = SvgLoader.asset(
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
              return ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  children: [
                    const SizedBox(height: 5),
                    Obx(() {
                      final textStyle = Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.black);

                      return AnimatedSizeAndFade.showHide(
                        show: !c.hintDismissed.value,
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ModalPopupHeader(
                                  alwaysClose: true,
                                  onClose: c.hintDismissed.toggle,
                                  header: Center(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(text: 'What is '),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, -3.6),
                                              child: SvgLoader.asset(
                                                'assets/icons/inter.svg',
                                                width: 6.25 * 0.99,
                                                height: 13.25 * 0.99,
                                              ),
                                            ),
                                          ),
                                          TextSpan(text: ' (Inter)?'),
                                        ],
                                        style:
                                            textStyle?.copyWith(fontSize: 18),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(32, 12, 32, 18),
                                  child: Center(
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, 0),
                                              child: SvgLoader.asset(
                                                'assets/icons/inter.svg',
                                                width: 6.25 * 0.88,
                                                height: 13.25 * 0.88,
                                              ),
                                            ),
                                          ),
                                          const TextSpan(
                                            text:
                                                ' (Inter) is an internal currency for purchasing services offered by Gapopa.\n\n',
                                          ),
                                          WidgetSpan(
                                            child: Transform.translate(
                                              offset: const Offset(0, 0),
                                              child: SvgLoader.asset(
                                                'assets/icons/inter.svg',
                                                width: 6.25 * 0.88,
                                                height: 13.25 * 0.88,
                                              ),
                                            ),
                                          ),
                                          const TextSpan(text: '100 = €1.00'),
                                        ],
                                        style:
                                            textStyle?.copyWith(fontSize: 15),
                                      ),
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
                    const SizedBox(height: 5),
                  ]);
            }

            return ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: const [
                SizedBox(height: 5),
                TransactionWidget(),
                TransactionWidget(),
                TransactionWidget(),
                TransactionWidget(),
                SizedBox(height: 5),
              ],
            );
          }),
        );
      },
    );
  }
}
