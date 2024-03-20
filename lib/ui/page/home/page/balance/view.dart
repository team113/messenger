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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/donate.dart';
import 'package:messenger/ui/page/home/page/chat/widget/embossed_text.dart';
import 'package:messenger/ui/page/home/page/user/widget/money_field.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'controller.dart';
import 'widget/paypal_button/paypal_button.dart';

class BalanceProviderView extends StatelessWidget {
  const BalanceProviderView(this.provider, {super.key});

  final BalanceProvider? provider;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: BalanceProviderController(Get.find(), Get.find()),
      builder: (BalanceProviderController c) {
        return Scaffold(
          appBar: context.isNarrow
              ? CustomAppBar(
                  title: Row(
                  children: [
                    const SizedBox(width: 4),
                    const StyledBackButton(),
                    Material(
                      elevation: 6,
                      type: MaterialType.circle,
                      shadowColor: style.colors.onBackgroundOpacity27,
                      color: style.colors.onPrimary,
                      child: Center(
                        child: Obx(() {
                          return AvatarWidget.fromMyUser(
                            c.myUser.value,
                            radius: AvatarRadius.medium,
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Obx(() {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.myUser.value?.name?.val ??
                                    c.myUser.value?.num.toString() ??
                                    'dot'.l10n * 3,
                                style: style.fonts.big.regular.onBackground,
                              ),
                              Text(
                                'Пополнить счёт'.l10n,
                                style: style.fonts.small.regular.secondary,
                              ),
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ))
              : const CustomAppBar(
                  title: Text('Пополнить счёт'),
                  leading: [StyledBackButton()],
                  actions: [SizedBox(width: 36)],
                ),
          body: Center(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
              children: [
                ...BalanceProvider.values
                    .where((e) =>
                        e != BalanceProvider.applePay &&
                        e != BalanceProvider.googlePay)
                    .mapIndexed((i, e) {
                  if (e == BalanceProvider.paypal) {
                    return Block(
                      title: e.name,
                      children: [
                        _bar(
                          context,
                          price: 99,
                          label: 'Buy for \$0.99',
                        ),
                        const SizedBox(height: 16),
                        _bar(
                          context,
                          price: 529,
                          label: 'Buy for \$4.99',
                        ),
                        const SizedBox(height: 16),
                        _bar(
                          context,
                          price: 1049,
                          label: 'Buy for \$9.99',
                        ),
                        const SizedBox(height: 4),
                        // MenuButton(
                        //   leading: const SvgIcon(SvgIcons.paypal),
                        //   title: 'G99',
                        //   subtitle: 'Buy for \$0.99',
                        //   onPressed: () {},
                        // ),
                        // const SizedBox(height: 3),
                        // MenuButton(
                        //   leading: const SvgIcon(SvgIcons.paypal),
                        //   title: 'G499',
                        //   subtitle: 'Buy for \$4.99',
                        //   onPressed: () {},
                        // ),
                        // const SizedBox(height: 8),
                        // const PayPalButton(),
                      ],
                    );
                  }

                  return Block(
                    title: e.name,
                    children: [
                      const SizedBox(height: 8),
                      MoneyField(
                        state: c.states[i],
                        label: 'Amount',
                        onChanged: (s) => c.prices[i].value = s,
                      ),
                      const SizedBox(height: 8),
                      Obx(() {
                        return Text(
                          'Total: \$${(c.prices[i].value / 100).withSpaces()}',
                          style: style.fonts.small.regular.secondary,
                          textAlign: TextAlign.left,
                        );
                      }),
                      const SizedBox(height: 8),
                      PrimaryButton(
                        title: 'Proceed',
                        onPressed: () {},
                      ),
                    ],
                  );
                }),
              ],
            ),
          ),
        );

        switch (provider) {
          case BalanceProvider.creditCard:
            return Scaffold(
              appBar: const CustomAppBar(
                title: Text('Пополнить счёт'),
                leading: [StyledBackButton()],
                actions: [SizedBox(width: 36)],
              ),
              body: Center(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  children: [
                    Block(
                      children: [
                        const SizedBox(height: 8),
                        MoneyField(state: TextFieldState(), label: 'Amount'),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        const Text('Total: \$12.42'),
                      ],
                    ),
                    Block(
                      title: 'Card',
                      children: [
                        ReactiveTextField(
                          state: TextFieldState(),
                          hint: 'Card number',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: ReactiveTextField(
                                state: TextFieldState(),
                                hint: 'Expiry date',
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ReactiveTextField(
                                state: TextFieldState(),
                                hint: 'CVV',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ReactiveTextField(
                          state: TextFieldState(),
                          hint: 'Card holder',
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          title: 'Proceed',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

          case BalanceProvider.paypal:
            return Scaffold(
              appBar: const CustomAppBar(
                title: Text('Пополнить счёт'),
                leading: [StyledBackButton()],
                actions: [SizedBox(width: 36)],
              ),
              body: Center(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                  children: [
                    Block(
                      children: [
                        const SizedBox(height: 8),
                        MoneyField(state: TextFieldState(), label: 'Amount'),
                        const SizedBox(height: 8),
                        Text(
                          'Total: \$12.42',
                          style: style.fonts.small.regular.secondary,
                          textAlign: TextAlign.left,
                        ),
                        const SizedBox(height: 8),
                        PrimaryButton(
                          title: 'Proceed',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );

          default:
            break;
        }

        return Obx(() {
          if (c.webController.value != null) {
            return Scaffold(
              appBar: CustomAppBar(
                title: Text(provider.toString()),
                leading: const [StyledBackButton()],
                actions: [
                  IconButton(
                    onPressed: () => c.add(
                      OutgoingTransaction(
                        amount: -100,
                        at: DateTime.now(),
                      ),
                    ),
                    icon: const Icon(Icons.remove),
                  ),
                  IconButton(
                    onPressed: () => c.add(
                      IncomingTransaction(
                        amount: 100,
                        at: DateTime.now(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              body: WebViewWidget(controller: c.webController.value!),
            );
          }

          return Scaffold(
            appBar: CustomAppBar(
              title: Text(provider.toString()),
              leading: const [StyledBackButton()],
              actions: [
                IconButton(
                  onPressed: () => c.add(
                    OutgoingTransaction(amount: -1000, at: DateTime.now()),
                  ),
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  onPressed: () => c.add(
                    IncomingTransaction(amount: 10000, at: DateTime.now()),
                  ),
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            body: Center(
              child: Text(provider.toString()),
            ),
          );
        });
      },
    );
  }

  Widget _bar(
    BuildContext context, {
    int price = 0,
    required String label,
  }) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: () {},
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 6),
            child: DonateWidget(
              donate: price,
              timestamp: const SizedBox(),
            ),
          ),
          Positioned.fill(
            child: Align(
              alignment: Alignment.bottomRight,
              child: Container(
                decoration: BoxDecoration(
                  color: style.colors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Text(
                  label,
                  style: style.fonts.small.regular.onPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

extension on num {
  String withSpaces() => NumberFormat('#,##0.00').format(this);
}
