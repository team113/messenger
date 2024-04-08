import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/balance/widget/currency_field.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/line_divider.dart';
import 'package:messenger/ui/page/home/page/user/widget/money_field.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/block.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/country_selector2.dart';
import 'package:messenger/ui/widget/info_tile.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:phone_form_field/phone_form_field.dart' hide CountrySelector;
import 'package:circle_flags/circle_flags.dart';

import 'controller.dart';
import 'widget/uploadable_file.dart';
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
                      text: c.method.value.l10n,
                      headline: Text('Способ'.l10n),
                      onPressed: () async {
                        await WithdrawMethodView.show(
                          context,
                          initial: c.method.value,
                          onChanged: (e) {
                            c.method.value = e;
                            c.recalculateAmount();
                          },
                        );
                      },
                      style: style.fonts.normal.regular.primary,
                    );
                  }),
                ],
              ),
              Obx(() {
                switch (c.method.value) {
                  case WithdrawMethod.usdt:
                    return Block(
                      title: c.method.value.l10n,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        InfoTile(
                          title: 'Минимальная сумма транзакции',
                          content: '10 USDT',
                        ),
                        SizedBox(height: 16),
                        InfoTile(
                          title: 'Максимальная сумма транзакции',
                          content: '1000 USDT',
                        ),
                        SizedBox(height: 16),
                        InfoTile(
                          title: 'Комиссия',
                          content: '3 USDT',
                        ),
                      ],
                    );

                  case WithdrawMethod.bitcoin:
                    return Block(
                      title: c.method.value.l10n,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        InfoTile(
                          title: 'Минимальная сумма транзакции',
                          content: '0.000014 BTC',
                        ),
                        SizedBox(height: 16),
                        InfoTile(
                          title: 'Максимальная сумма транзакции',
                          content: '0.014 BTC',
                        ),
                        SizedBox(height: 16),
                        InfoTile(
                          title: 'Комиссия',
                          content: '0.000042 BTC',
                        ),
                      ],
                    );

                  case WithdrawMethod.card:
                    return Block(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
                      children: [
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            c.method.value.l10n,
                            style: style.fonts.big.regular.onBackground,
                          ),
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
                        const InfoTile(
                          title: 'Минимальная сумма транзакции',
                          content: '\$3.00',
                        ),
                        const SizedBox(height: 16),
                        const InfoTile(
                          title: 'Максимальная сумма транзакции',
                          content: '\$550.00',
                        ),
                        const SizedBox(height: 16),
                        const InfoTile(
                          title: 'Комиссия',
                          content: '1.5%',
                        ),
                      ],
                    );

                  case WithdrawMethod.sepa:
                    return Block(
                      title: c.method.value.l10n,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        InfoTile(
                          title: 'Минимальная сумма транзакции',
                          content: '€5.00',
                        ),
                        SizedBox(height: 16),
                        InfoTile(
                          title: 'Комиссия',
                          content: '€5.00',
                        ),
                      ],
                    );

                  case WithdrawMethod.swift:
                    return Block(
                      title: c.method.value.l10n,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        InfoTile(
                          title: 'Минимальная сумма транзакции',
                          content: '\$100.00',
                        ),
                        SizedBox(height: 16),
                        InfoTile(
                          title: 'Комиссия',
                          content: '\$100.00',
                        ),
                      ],
                    );

                  default:
                    return const SizedBox();
                }
              }),
              Obx(() {
                final List<Widget> more = [];

                switch (c.method.value) {
                  case WithdrawMethod.usdt:
                    more.addAll([
                      const SizedBox(height: 8),
                      ReactiveTextField(
                        state: c.usdtWallet,
                        label: 'Номер кошелька',
                        hint: 'T0000000000000000',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 8),
                    ]);
                    break;

                  case WithdrawMethod.bitcoin:
                    more.addAll([
                      const SizedBox(height: 8),
                      ReactiveTextField(
                        state: c.btcWallet,
                        label: 'Номер кошелька',
                        hint: '0000000000000000000',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 8),
                    ]);
                    break;

                  case WithdrawMethod.card:
                    more.addAll([
                      const SizedBox(height: 8),
                      ReactiveTextField(
                        state: c.cardNumber,
                        label: 'Номер карты',
                        hint: '0000 0000 0000 0000',
                        onChanged: () {
                          c.cardNumber.text = UserNum.unchecked(
                            c.cardNumber.text.replaceAll(' ', ''),
                          ).toString();

                          c.cardNumber.text = c.cardNumber.text.substring(
                            0,
                            min(c.cardNumber.text.length, 19),
                          );
                        },
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 16),
                      ReactiveTextField(
                        state: c.cardExpire,
                        label: 'Срок действия',
                        hint: '00/00',
                        onChanged: () {
                          c.cardExpire.text = c.cardExpire.text.substring(
                            0,
                            min(c.cardExpire.text.length, 5),
                          );
                        },
                        formatters: [
                          CardExpirationFormatter(),
                          FilteringTextInputFormatter.allow(
                            RegExp(r'[1-9]|/'),
                          )
                        ],
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                      ),
                      const SizedBox(height: 8),
                    ]);
                    break;

                  default:
                    break;
                }

                return Block(
                  title: 'Реквизиты',
                  children: [
                    Text(
                      'Все поля заполняются латинскими буквами так, как они указаны в банке, платежной системе или на платежной карте.',
                      style: style.fonts.normal.regular.secondary,
                    ),
                    const SizedBox(height: 24),
                    ReactiveTextField(
                      label: 'Имя получателя',
                      state: c.name,
                      hint: 'JOHN SMITH',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      formatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]|[ ]|[.]|[,]'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      return FieldButton(
                        text: c.country.value?.name ?? 'Не выбрано',
                        headline: Text('Страна'.l10n),
                        onPressed: () async {
                          final result = await const _CountrySelectorNavigator()
                              .navigate(context, FlagCache());
                          if (result != null) {
                            c.country.value = result;
                          }
                        },
                        style: style.fonts.normal.regular.primary,
                      );
                    }),
                    const SizedBox(height: 16),
                    ReactiveTextField(
                      label: 'Адрес',
                      hint: 'Дом, улица, город, область/район/провинция/штат',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      state: c.address,
                      formatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[A-Za-z0-9]|[ ]|[.]|[,]'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ReactiveTextField(
                      label: 'Почтовый индекс',
                      hint: '00000',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      state: c.index,
                    ),
                    const SizedBox(height: 16),
                    Obx(() {
                      if (c.method.value == WithdrawMethod.paypal) {
                        return ReactiveTextField(
                          label: 'E-mail в PayPal',
                          hint: 'dummy@example.com',
                          floatingLabelBehavior: FloatingLabelBehavior.always,
                          state: c.email,
                        );
                      }

                      return ReactiveTextField(
                        label: 'E-mail',
                        hint: 'dummy@example.com',
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        state: c.email,
                      );
                    }),
                    const SizedBox(height: 16),
                    ReactiveTextField(
                      label: 'Телефон',
                      floatingLabelBehavior: FloatingLabelBehavior.always,
                      hint: '+1 234 567 8901',
                      state: c.phone,
                      formatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'[0-9]|[ ]|[+]'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...more,
                  ],
                );
              }),
              Block(
                title: 'Документы',
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Важно!',
                          style: style.fonts.normal.regular.onBackground,
                        ),
                        TextSpan(
                          text:
                              ' Каждая траназкция должна сопровождаться документами, подтверждающими личность получателя и назначение платежа. Это требование финансовых институтов и государственных органов.',
                          style: style.fonts.normal.regular.secondary,
                        ),
                      ],
                    ),
                    style: style.fonts.normal.regular.secondary,
                  ),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Важно!',
                          style: style.fonts.normal.regular.onBackground,
                        ),
                        TextSpan(
                          text: ' Принимаются только:\n'
                              '- фотографии документов (НЕ СКАН-КОПИИ);\n'
                              '- формат: JPG, PNG, PDF;\n- разрешение не ниже 200 DPI;\n'
                              '- весь текст должен быть читаем (отсутствие бликов, размытий и т.п.);\n'
                              '- документ должен быть сфотографирован полностью, ВКЛЮЧАЯ КРАЯ.',
                          style: style.fonts.normal.regular.secondary,
                        ),
                      ],
                    ),
                    style: style.fonts.normal.regular.secondary,
                  ),
                  const SizedBox(height: 24),
                  const LineDivider('Подписанный договор'),
                  const SizedBox(height: 12),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: 'Договор ',
                          style: style.fonts.small.regular.secondary,
                        ),
                        TextSpan(
                          text: 'скачать здесь',
                          style: style.fonts.small.regular.primary,
                          recognizer: TapGestureRecognizer()..onTap = () {},
                        ),
                        TextSpan(
                          text:
                              '. Необходимо распечатать, подписать, сфотографировать и загрузить.',
                          style: style.fonts.small.regular.secondary,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    return UploadableFile(
                      label: 'Договор',
                      onChanged: (f) => c.contract.value = f,
                      file: c.contract.value,
                    );
                  }),
                  const SizedBox(height: 24),
                  const LineDivider('Документ, удостоверяющий личность'),
                  const SizedBox(height: 12),
                  Text(
                    'Документом, удостоверяющим личность, считается только: заграничный паспорт, внутренний паспорт, внутренняя ID карта, водительское удостоверение.',
                    style: style.fonts.small.regular.secondary,
                  ),
                  const SizedBox(height: 24),
                  Obx(() {
                    return UploadableFile(
                      label: 'Загранпаспорт, паспорт, ID карта',
                      onChanged: (f) => c.passport.value = f,
                      file: c.passport.value,
                    );
                  }),
                ],
              ),
              Block(
                children: [
                  const SizedBox(height: 8),
                  MoneyField(
                    currency: null,
                    state: c.coins,
                    onChanged: (e) {
                      c.amount.value = e;
                      c.recalculateAmount();
                    },
                    label: 'Сумма к списанию, ¤',
                  ),
                  const SizedBox(height: 16),
                  Obx(() {
                    final currency = switch (c.method.value) {
                      WithdrawMethod.card ||
                      WithdrawMethod.paypal ||
                      WithdrawMethod.swift =>
                        CurrencyKind.usd,
                      WithdrawMethod.sepa => CurrencyKind.eur,
                      WithdrawMethod.usdt => CurrencyKind.usdt,
                      WithdrawMethod.bitcoin => CurrencyKind.btc,
                    };

                    final double? minimum = switch (c.method.value) {
                      WithdrawMethod.card => 3.5,
                      WithdrawMethod.paypal => null,
                      WithdrawMethod.swift => 100,
                      WithdrawMethod.sepa => 5,
                      WithdrawMethod.usdt => 10,
                      WithdrawMethod.bitcoin => 0.0000014,
                    };

                    final double? maximum = switch (c.method.value) {
                      WithdrawMethod.card => 550,
                      WithdrawMethod.paypal => null,
                      WithdrawMethod.swift => null,
                      WithdrawMethod.sepa => null,
                      WithdrawMethod.usdt => 1000,
                      WithdrawMethod.bitcoin => 0.014,
                    };

                    return CurrencyField(
                      currency: null,
                      value: c.total.value,
                      label: 'Сумма к отправке, ${currency.toSymbol()}',
                      onChanged: (e) {
                        c.total.value = e.toDouble();
                        c.recalculateTotal();
                      },
                      minimum: minimum,
                      maximum: maximum,
                    );
                  }),
                  const SizedBox(height: 16),
                  Obx(() {
                    bool enabled = !c.name.isEmpty.value &&
                        !c.address.isEmpty.value &&
                        !c.email.isEmpty.value &&
                        !c.phone.isEmpty.value &&
                        c.amount.value != 0;

                    switch (c.method.value) {
                      case WithdrawMethod.usdt:
                        enabled = enabled && !c.usdtWallet.isEmpty.value;
                        break;

                      default:
                        break;
                    }

                    return PrimaryButton(
                      title: 'btn_proceed'.l10n,
                      onPressed: enabled ? () {} : null,
                    );
                  }),
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

class _CountrySelectorNavigator extends CountrySelectorNavigator {
  const _CountrySelectorNavigator()
      : super(
          searchAutofocus: false,
        );

  @override
  Future<Country?> navigate(BuildContext context, dynamic flagCache) {
    return ModalPopup.show(
      context: context,
      child: CountrySelector(
        countries: countries,
        onCountrySelected: (country) =>
            Navigator.of(context, rootNavigator: true).pop(country),
        flagCache: flagCache,
        subtitle: null,
      ),
    );
  }
}

class CardExpirationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final newValueString = newValue.text;
    String valueToReturn = '';

    for (int i = 0; i < newValueString.length; i++) {
      if (newValueString[i] != '/') valueToReturn += newValueString[i];
      var nonZeroIndex = i + 1;
      final contains = valueToReturn.contains(RegExp(r'\/'));
      if (nonZeroIndex % 2 == 0 &&
          nonZeroIndex != newValueString.length &&
          !(contains)) {
        valueToReturn += '/';
      }
    }
    return newValue.copyWith(
      text: valueToReturn,
      selection: TextSelection.fromPosition(
        TextPosition(offset: valueToReturn.length),
      ),
    );
  }
}
