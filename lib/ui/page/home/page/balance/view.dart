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

import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/chat/widget/donate.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'controller.dart';
import 'widget/buy_button.dart';
import 'widget/currency_field.dart';
import 'widget/nominal_card.dart';
import 'widget/pick_variant.dart';

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
                    final nominals = [500, 1000, 5000, 10000];

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
                        Container(
                          width: 96,
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          child: const SvgImage.asset(
                            'assets/images/paypal.svg',
                            width: 64,
                            height: 32,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...nominals.mapIndexed((i, n) {
                          return Obx(() {
                            final bool selected = c.nominal[e]!.value == i;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1.5),
                              child: PickVariantButton(
                                amount: n,
                                price: '\$${(n / 100).round().withSpaces}',
                                bonus: 0,
                                onPressed: () => c.nominal[e]!.value = i,
                                selected: selected,
                              ),
                            );
                          });
                        }),
                        const SizedBox(height: 16),
                        Obx(() {
                          return _nominal(
                            context,
                            c,
                            price:
                                nominals.elementAtOrNull(c.nominal[e]!.value) ??
                                    nominals.first,
                          );
                        }),
                        const SizedBox(height: 16),
                        BuyButton(onPressed: () {}),
                      ],
                    );

                  case BalanceProvider.card:
                    final nominals = [500, 1000, 5000, 10000];

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
                        const Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgImage.asset(
                                'assets/images/visa.svg',
                                height: 21,
                              ),
                              SizedBox(width: 16),
                              SvgImage.asset(
                                'assets/images/mastercard.svg',
                                height: 38,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...nominals.mapIndexed((i, n) {
                          return Obx(() {
                            final bool selected = c.nominal[e]!.value == i;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1.5),
                              child: PickVariantButton(
                                amount: n,
                                price: '\$${(n / 100).round().withSpaces}',
                                bonus: 0,
                                onPressed: () => c.nominal[e]!.value = i,
                                selected: selected,
                              ),
                            );
                          });
                        }),
                        const SizedBox(height: 16),
                        Obx(() {
                          return _nominal(
                            context,
                            c,
                            price:
                                nominals.elementAtOrNull(c.nominal[e]!.value) ??
                                    nominals.first,
                          );
                        }),
                        const SizedBox(height: 16),
                        BuyButton(onPressed: () {}),
                      ],
                    );

                  case BalanceProvider.sepa:
                    return Block(
                      margin: EdgeInsets.fromLTRB(
                        8,
                        4,
                        8,
                        i == BalanceProvider.values.length ? 4 : 32,
                      ),
                      // title: e.name.toUpperCase(),
                      highlight: c.highlightIndex.value == i,
                      children: [
                        // const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 96,
                            padding: const EdgeInsets.fromLTRB(0, 9, 0, 9),
                            child: const SvgImage.asset(
                              'assets/images/sepa.svg',
                              height: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'label_sepa_transfer_description'.l10n,
                          style: style.fonts.small.regular.secondary,
                        ),
                        const SizedBox(height: 21),
                        ReactiveTextField(
                          state: TextFieldState(),
                          label: 'Имя или название',
                        ),
                        const SizedBox(height: 16),
                        ReactiveTextField(
                          state: TextFieldState(),
                          label: 'Адрес',
                        ),
                        const SizedBox(height: 16),
                        ReactiveTextField(
                          state: TextFieldState(),
                          label: 'E-mail',
                        ),
                        const SizedBox(height: 16),
                        CurrencyField(
                          currency: CurrencyKind.eur,
                          onChanged: (s) => c.sepaPrice.value = s.round(),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Минимум: ${CurrencyKind.eur.toSymbol()}5.00',
                          style: style.fonts.small.regular.secondary,
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        Obx(() {
                          final price = c.sepaPrice.value;

                          return _nominal(
                            context,
                            c,
                            price: max(
                              0,
                              CurrencyKind.eur.toCoins(price) -
                                  CurrencyKind.eur.toCoins(5),
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        Obx(() {
                          final bool enabled = c.sepaPrice >= 5;

                          return BuyButton(onPressed: enabled ? () {} : null);
                        }),
                      ],
                    );

                  case BalanceProvider.swift:
                    return Block(
                      margin: EdgeInsets.fromLTRB(
                        8,
                        4,
                        8,
                        i == BalanceProvider.values.length ? 4 : 32,
                      ),
                      // title: e.name.toUpperCase(),
                      highlight: c.highlightIndex.value == i,
                      children: [
                        // const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 96,
                            // height: 64,
                            padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                            child: const SvgImage.asset(
                              'assets/images/swift.svg',
                              height: 36,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'label_swift_transfer_description'.l10n,
                          style: style.fonts.small.regular.secondary,
                        ),
                        const SizedBox(height: 21),
                        ReactiveTextField(
                          state: TextFieldState(),
                          label: 'Имя или название',
                        ),
                        const SizedBox(height: 16),
                        ReactiveTextField(
                          state: TextFieldState(),
                          label: 'Адрес',
                        ),
                        const SizedBox(height: 16),
                        ReactiveTextField(
                          state: TextFieldState(),
                          label: 'E-mail',
                        ),
                        const SizedBox(height: 16),
                        if (e == BalanceProvider.swift)
                          Obx(() {
                            return CurrencyField(
                              currency: c.swiftCurrency.value,
                              allowed: const [
                                CurrencyKind.usd,
                                CurrencyKind.eur
                              ],
                              onCurrency: (s) => c.swiftCurrency.value = s,
                              onChanged: (s) => c.swiftPrice.value = s.round(),
                            );
                          }),
                        const SizedBox(height: 8),
                        Obx(() {
                          final currency = c.swiftCurrency.value;
                          final price =
                              currency.fromCoins(10000).toStringAsFixed(2);

                          return Text(
                            'Минимум: ${currency.toSymbol()}$price',
                            style: style.fonts.small.regular.secondary,
                          );
                        }),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                        Obx(() {
                          final currency = c.swiftCurrency.value;
                          final price = c.swiftPrice.value;

                          return _nominal(
                            context,
                            c,
                            price: max(0, currency.toCoins(price) - 10000),
                          );
                        }),
                        const SizedBox(height: 8),
                        Obx(() {
                          final bool enabled = c.swiftPrice.value >=
                              c.swiftCurrency.value.fromCoins(10000);

                          return BuyButton(onPressed: enabled ? () {} : null);
                        }),
                      ],
                    );

                  case BalanceProvider.bitcoin:
                    final nominals = [100, 500, 1000, 5000, 10000];

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
                        // Text(
                        //   'Bitcoin',
                        //   style: style.fonts.big.regular.onBackground,
                        // ),
                        // const SizedBox(height: 8),
                        Center(
                          child: Container(
                            width: 96,
                            padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
                            child: const SvgImage.asset(
                              'assets/images/bitcoin.svg',
                              height: 21,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...nominals.mapIndexed((i, n) {
                          return Obx(() {
                            final bool selected = c.nominal[e]!.value == i;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1.5),
                              child: PickVariantButton(
                                amount: n,
                                price: '${n / 100 * 0.000014} BTC',
                                onPressed: () => c.nominal[e]!.value = i,
                                selected: selected,
                              ),
                            );
                          });
                        }),
                        const SizedBox(height: 16),
                        Obx(() {
                          return _nominal(
                            context,
                            c,
                            price:
                                nominals.elementAtOrNull(c.nominal[e]!.value) ??
                                    nominals.first,
                          );
                        }),
                        const SizedBox(height: 16),
                        BuyButton(onPressed: () {}),
                      ],
                    );

                  case BalanceProvider.usdt:
                    final nominals = [100, 500, 1000, 5000, 10000];

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
                          'USDT - TRC20',
                          style: style.fonts.big.regular.onBackground,
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 96,
                                padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
                                child: const SvgImage.asset(
                                  'assets/images/tether.svg',
                                  height: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Container(
                                width: 84,
                                padding: const EdgeInsets.fromLTRB(0, 6, 0, 6),
                                child: const SvgImage.asset(
                                  'assets/images/tron.svg',
                                  height: 28,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...nominals.mapIndexed((i, n) {
                          return Obx(() {
                            final bool selected = c.nominal[e]!.value == i;

                            return Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 1.5),
                              child: PickVariantButton(
                                amount: n,
                                price: '${(n / 100).round()} USDT',
                                onPressed: () => c.nominal[e]!.value = i,
                                selected: selected,
                              ),
                            );
                          });
                        }),
                        const SizedBox(height: 16),
                        Obx(() {
                          return _nominal(
                            context,
                            c,
                            price:
                                nominals.elementAtOrNull(c.nominal[e]!.value) ??
                                    nominals.first,
                          );
                        }),
                        const SizedBox(height: 16),
                        BuyButton(onPressed: () {}),
                      ],
                    );
                }
              });
            },
          ),
          bottomNavigationBar: context.isNarrow
              ? SafeArea(
                  child: Container(
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
                      padding: const EdgeInsets.symmetric(horizontal: 12),
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
                                      duration:
                                          const Duration(milliseconds: 150),
                                      opacity: selected ? 1 : 0.7,
                                      child: AnimatedScale(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        scale: selected ? 1.1 : 1,
                                        child: Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            i == 0 ? 8 : 15,
                                            6,
                                            15 + 4,
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
                                            BalanceProvider.usdt =>
                                              SvgIcons.usdtLogo,
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
                                            BalanceProvider.bitcoin =>
                                              'Bitcoin',
                                            BalanceProvider.usdt => 'USDT',
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
                  ),
                )
              : null,
        );
      },
    );
  }

  Widget _card({
    double width = 64,
    double height = 36,
    required Widget child,
    EdgeInsets padding = const EdgeInsets.fromLTRB(0, 1, 0, 1),
  }) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(6),
      ),
      child: child,
    );
  }

  Widget _nominal(
    BuildContext context,
    BalanceProviderController c, {
    int price = 0,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      switchInCurve: Curves.ease,
      switchOutCurve: Curves.linearToEaseOut,
      child: NominalCard(
        key: Key(NominalCard.assetFor(price)),
        amount: price,
        num: c.myUser.value?.num,
      ),
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
}
