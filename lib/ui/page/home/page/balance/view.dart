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
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/menu_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'controller.dart';
import 'widget/paypal_button/paypal_button.dart';

class BalanceProviderView extends StatelessWidget {
  const BalanceProviderView({super.key});

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
          body: ScrollablePositionedList.builder(
            initialScrollIndex: c.listInitIndex,
            scrollController: c.scrollController,
            itemScrollController: c.itemScrollController,
            itemPositionsListener: c.positionsListener,
            itemCount: BalanceProvider.values.length,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (context, i) {
              return Obx(() {
                final e = BalanceProvider.values[i];

                switch (e) {
                  case BalanceProvider.paypal:
                    return Block(
                      margin: EdgeInsets.fromLTRB(
                        8,
                        4,
                        8,
                        i == BalanceProvider.values.length - 1 ? 4 : 32,
                      ),
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                      highlight: c.highlightIndex.value == i,
                      children: [
                        const SizedBox(height: 8),
                        _card(
                          width: 96,
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          child: const SvgImage.asset(
                            'assets/images/paypal.svg',
                            width: 64,
                            height: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _cell(
                          context,
                          amount: 99,
                          button: _paypal(context, 0.99),
                        ),
                        const SizedBox(height: 32),
                        _cell(
                          context,
                          amount: 549,
                          button: _paypal(context, 4.99),
                        ),
                        const SizedBox(height: 32),
                        _cell(
                          context,
                          amount: 1109,
                          button: _paypal(context, 9.99),
                        ),
                      ],
                    );

                  case BalanceProvider.card:
                    return Block(
                      margin: EdgeInsets.fromLTRB(
                        8,
                        4,
                        8,
                        i == BalanceProvider.values.length ? 4 : 32,
                      ),
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                      highlight: c.highlightIndex.value == i,
                      children: [
                        const SizedBox(height: 8),
                        Text(
                          'Платёжные карты',
                          style: style.fonts.big.regular.onBackground,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _card(
                                padding:
                                    const EdgeInsets.fromLTRB(0, 10, 0, 10),
                                child: const SvgImage.asset(
                                  'assets/images/visa.svg',
                                  height: 32,
                                ),
                              ),
                              const SizedBox(width: 4),
                              _card(
                                child: const SvgImage.asset(
                                  'assets/images/mastercard.svg',
                                  height: 36,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        _cell(
                          context,
                          amount: 99,
                          button: _paymentCard(context, 0.99),
                        ),
                        const SizedBox(height: 32),
                        _cell(
                          context,
                          amount: 549,
                          button: _paymentCard(context, 4.99),
                        ),
                        const SizedBox(height: 32),
                        _cell(
                          context,
                          amount: 1109,
                          button: _paymentCard(context, 9.99),
                        ),
                      ],
                    );

                  case BalanceProvider.sepa:
                  case BalanceProvider.swift:
                  case BalanceProvider.bitcoin:
                    return Block(
                      margin: EdgeInsets.fromLTRB(
                        8,
                        4,
                        8,
                        i == BalanceProvider.values.length ? 4 : 32,
                      ),
                      title: e.name,
                      highlight: c.highlightIndex.value == i,
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
                }
              });
            },
          ),
          // body: Center(
          //   child: ListView(
          //     shrinkWrap: true,
          //     padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          //     children: [
          //       ...BalanceProvider.values.mapIndexed((i, e) {

          //       }),
          //     ],
          //   ),
          // ),
          bottomNavigationBar: context.isNarrow
              ? Container(
                  margin: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  decoration: BoxDecoration(
                    boxShadow: [
                      CustomBoxShadow(
                        blurRadius: 8,
                        color: style.colors.onBackgroundOpacity13,
                        blurStyle: BlurStyle.outer.workaround,
                      ),
                    ],
                    borderRadius: style.cardRadius,
                    border: style.cardBorder,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: style.cardColor,
                      borderRadius: style.cardRadius,
                    ),
                    height: 56,
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ...BalanceProvider.values.mapIndexed(
                            (i, e) {
                              return Obx(() {
                                final bool selected =
                                    router.balanceSection.value == e;

                                return AnimatedButton(
                                  onPressed: () =>
                                      router.balanceSection.value = e,
                                  decorator: (child) => AnimatedOpacity(
                                    duration: const Duration(milliseconds: 150),
                                    opacity: selected ? 1 : 0.7,
                                    child: AnimatedScale(
                                      duration:
                                          const Duration(milliseconds: 150),
                                      scale: selected ? 1.1 : 1,
                                      child: Padding(
                                        padding: EdgeInsets.fromLTRB(
                                          i == 0 ? 8 : 12,
                                          6,
                                          12 + 4,
                                          4,
                                        ),
                                        child: child,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SvgIcon(
                                        switch (e) {
                                          BalanceProvider.paypal =>
                                            SvgIcons.paypalLogo,
                                          BalanceProvider.card =>
                                            SvgIcons.paymentCard,
                                          BalanceProvider.sepa =>
                                            SvgIcons.sepaLogo,
                                          BalanceProvider.swift =>
                                            SvgIcons.swiftLogo,
                                          BalanceProvider.bitcoin =>
                                            SvgIcons.bitcoinLogo,
                                        },
                                        height: 23,
                                      ),
                                      const SizedBox(height: 1),
                                      Text(
                                        switch (e) {
                                          BalanceProvider.paypal => 'PayPal',
                                          BalanceProvider.card =>
                                            'Payment card',
                                          BalanceProvider.sepa => 'SEPA',
                                          BalanceProvider.swift => 'SWIFT',
                                          BalanceProvider.bitcoin => 'Bitcoin',
                                        },
                                        style: style.fonts.smallest.regular
                                            .onBackground,
                                      ),
                                    ],
                                  ),
                                );
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _card({
    double width = 64,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.fromLTRB(0, 1, 0, 1),
  }) {
    return Container(
      width: width,
      // constraints: BoxConstraints(minWidth: 64),
      height: 36,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
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

  Widget _cell(
    BuildContext context, {
    int amount = 0,
    required Widget button,
  }) {
    final style = Theme.of(context).style;

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 85.6 / 53.98,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: style.colors.acceptPrimary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFF0F0F0),
                    ),
                    child: const Center(
                      child: SvgIcon(
                        SvgIcons.logo,
                        width: 48,
                        height: 48,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '¤$amount',
                  style: style.fonts.largest.regular.onBackground.copyWith(
                    color: style.colors.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        button,
      ],
    );
  }

  Widget _paypal(BuildContext context, double price) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: () {},
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFAC335),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Buy with ',
                style: style.fonts.small.regular.onBackground,
              ),
              TextSpan(
                text: 'Pay',
                style: style.fonts.medium.regular.onBackground.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF164EA1),
                ),
              ),
              TextSpan(
                text: 'Pal',
                style: style.fonts.medium.regular.onBackground.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF5A9CFF),
                ),
              ),
              TextSpan(
                text: ' for \$$price',
                style: style.fonts.small.regular.onBackground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _paymentCard(BuildContext context, double price) {
    final style = Theme.of(context).style;

    return WidgetButton(
      onPressed: () {},
      child: Container(
        decoration: BoxDecoration(
          // color: const Color(0xFFFAC335),
          color: style.colors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Buy with payment card',
                style: style.fonts.small.regular.onPrimary,
              ),
              TextSpan(
                text: ' for \$$price',
                style: style.fonts.small.regular.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension on num {
  String withSpaces() => NumberFormat('#,##0.00').format(this);
}
