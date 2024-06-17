import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:messenger/ui/page/home/page/balance/widget/currency_field.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/line_divider.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/uploadable_photo.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/verification.dart';
import 'package:messenger/ui/page/home/page/user/widget/money_field.dart';
import 'package:messenger/ui/page/home/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/highlighted_container.dart';
import 'package:messenger/ui/page/login/widget/primary_button.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../../util/message_popup.dart';
import '../../../../../util/platform_utils.dart';
import '../../../style/page/widgets/common/cat.dart';
import '../../widget/contact_tile.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/info_tile.dart';
import '/ui/page/home/widget/rectangle_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

class WithdrawView extends StatelessWidget {
  const WithdrawView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: WithdrawController(Get.find(), Get.find()),
      builder: (WithdrawController c) {
        final List<Widget> blocks = [
          Block(
            title: 'Данные получателя',
            children: [_verification(context, c)],
          ),
          Block(
            title: 'Способ выплаты',
            children: [
              Flexible(
                child: Column(
                  children: WithdrawMethod.values.map((e) {
                    return Obx(() {
                      final bool selected = c.method.value == e;

                      return Padding(
                        padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                        child: RectangleButton(
                          selected: selected,
                          onPressed: selected
                              ? null
                              : () {
                                  c.method.value = e;
                                  c.method.value = e;
                                  c.recalculateAmount();
                                },
                          label: e.l10n,
                          subtitle: switch (e) {
                            WithdrawMethod.balance => 'Комиссия: 0%, мгновенно',
                            WithdrawMethod.usdt =>
                              'Комиссия: 3%, не менее 3 USDT',
                            WithdrawMethod.paypal => 'Комиссия: 0%',
                            WithdrawMethod.paysera => 'Комиссия: €5.00',
                            WithdrawMethod.payeer => 'Комиссия: 10%',
                            WithdrawMethod.monobank => 'Комиссия: €0.25',
                            WithdrawMethod.skrill => 'Комиссия: 1%',
                            WithdrawMethod.revolut => 'Комиссия: 0%',
                            WithdrawMethod.card => 'Комиссия: 1.5%',
                            WithdrawMethod.sepa => 'Комиссия: €5.00',
                            WithdrawMethod.swift => 'Комиссия: \$100.00',
                          },
                        ),
                      );
                    });
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          Obx(() {
            switch (c.method.value) {
              case WithdrawMethod.usdt:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(
                      title: 'Минимальная сумма транзакции',
                      content: '10 USDT',
                    ),
                    const SizedBox(height: 16),
                    const InfoTile(
                      title: 'Максимальная сумма транзакции',
                      content: '1000 USDT',
                    ),
                    const SizedBox(height: 16),
                    const InfoTile(
                      title: 'Комиссия',
                      content: '3%, не менее 3 USDT',
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.paysera:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(title: 'Комиссия', content: '€1.00'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.payeer:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(
                      title: 'Минимальная сумма транзакции',
                      content: '€1',
                    ),
                    const SizedBox(height: 16),
                    const InfoTile(
                      title: 'Максимальная сумма транзакции',
                      content: '€200',
                    ),
                    const SizedBox(height: 16),
                    const InfoTile(title: 'Комиссия', content: '10%'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.monobank:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(title: 'Комиссия', content: '€0.25'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.skrill:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(title: 'Комиссия', content: '1%'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
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
                    const InfoTile(title: 'Комиссия', content: '1.5%'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.sepa:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(
                      title: 'Минимальная сумма транзакции',
                      content: '€5.00',
                    ),
                    const SizedBox(height: 16),
                    const InfoTile(title: 'Комиссия', content: '€5.00'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.swift:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(
                      title: 'Минимальная сумма транзакции',
                      content: '\$100.00',
                    ),
                    const SizedBox(height: 16),
                    const InfoTile(title: 'Комиссия', content: '\$100.00'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.revolut:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(title: 'Комиссия', content: '0%'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.balance:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(title: 'Комиссия', content: '0%'),
                    const SizedBox(height: 16),
                    Text(
                      'Операция выполняется автоматически. Баланс пополняется мгновенно.',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );

              case WithdrawMethod.paypal:
                return Block(
                  title: c.method.value.l10n,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const InfoTile(title: 'Комиссия', content: '0%'),
                    const SizedBox(height: 16),
                    Text(
                      'Заявка на выплату обрабатывается в течение трёх рабочих дней',
                      style: style.fonts.small.regular.secondary,
                    ),
                    const SizedBox(height: 8),
                  ],
                );
            }
          }),
          Obx(() {
            final List<Widget> more = [];

            switch (c.method.value) {
              case WithdrawMethod.balance:
                more.addAll([
                  const Text('Пополнение баланса пользователя:'),
                  const SizedBox(height: 8),
                  ContactTile(
                    myUser: c.myUser.value,
                    subtitle: [
                      const SizedBox(height: 5),
                      Text(
                        '${c.myUser.value?.num.toString()}',
                        style: style.fonts.normal.regular.secondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ]);
                break;

              case WithdrawMethod.usdt:
                more.addAll([
                  // const SizedBox(height: 8),
                  ReactiveTextField(
                    state: c.usdtWallet,
                    label: 'Номер кошелька',
                    hint: 'T0000000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-z]|[A-Z]'),
                      )
                    ],
                  ),
                  // const SizedBox(height: 8),
                ]);
                break;

              case WithdrawMethod.paypal:
                more.addAll([
                  ReactiveTextField(
                    state: c.email,
                    label: 'E-mail',
                    hint: 'dummy@example.com',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ]);
                break;

              case WithdrawMethod.paysera:
                more.addAll([
                  ReactiveTextField(
                    state: c.payseraWallet,
                    label: 'Номер счёта',
                    hint: 'EVP00000000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-z]|[A-Z]'),
                      )
                    ],
                  ),
                ]);
                break;

              case WithdrawMethod.payeer:
                more.addAll([
                  ReactiveTextField(
                    state: c.payeerWallet,
                    label: 'Номер счёта',
                    hint: 'P00000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-z]|[A-Z]'),
                      )
                    ],
                  ),
                ]);
                break;

              case WithdrawMethod.monobank:
                more.addAll([
                  ReactiveTextField(
                    state: c.monobankWallet,
                    label: 'Номер счёта (IBAN)',
                    hint: 'UA0000000000000000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.monobankBik,
                    label: 'Код банка',
                    hint: '0000000000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.monobankName,
                    label: 'Название банка',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.monobankAddress,
                    label: 'Адрес банка',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ]);
                break;

              case WithdrawMethod.skrill:
                more.addAll([
                  ReactiveTextField(
                    state: c.email,
                    label: 'E-mail',
                    hint: 'dummy@example.com',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ]);
                break;

              case WithdrawMethod.revolut:
                more.addAll([
                  ReactiveTextField(
                    state: c.revolutWallet,
                    label: 'Номер счёта в формате IBAN',
                    hint: '00000000000000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-z]|[A-Z]'),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.revolutBik,
                    label: 'Код банка получателя',
                    hint: 'REVOLT21XXX',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                    formatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[0-9]|[a-z]|[A-Z]'),
                      )
                    ],
                  ),
                ]);
                break;

              case WithdrawMethod.card:
                more.addAll([
                  // const SizedBox(height: 8),
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
                  // const SizedBox(height: 8),
                ]);
                break;

              case WithdrawMethod.sepa:
                more.addAll([
                  ReactiveTextField(
                    state: c.sepaWallet,
                    label: 'Номер счёта (IBAN)',
                    hint: '0000000000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.sepaName,
                    label: 'Название банка получателя',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.sepaAddress,
                    label: 'Адрес банка получателя',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.sepaBik,
                    label: 'Код банка получателя',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ]);
                break;

              case WithdrawMethod.swift:
                more.addAll([
                  ReactiveTextField(
                    state: c.swiftCurrency,
                    label: 'Валюта счёта',
                    hint: 'USD',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftWallet,
                    label: 'Номер счёта получателя',
                    hint: '0000000000000000000',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftName,
                    label: 'Название банка получателя',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftAddress,
                    label: 'Адрес банка получателя',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftBik,
                    label: 'Код банка получателя',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftCorrespondentName,
                    label: 'Название банка-корреспондента',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftCorrespondentAddress,
                    label: 'Адрес банка-корреспондента',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftCorrespondentBik,
                    label: 'Код банка-корреспондента',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  const SizedBox(height: 16),
                  ReactiveTextField(
                    state: c.swiftCorrespondentWallet,
                    label: 'Номер счёта банка в банке-корреспонденте',
                    hint: '',
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                ]);
                break;

              default:
                break;
            }

            return Block(
              title: 'Реквизиты',
              children: [
                ...more,
                const SizedBox(height: 16),
                MoneyField(
                  currency: null,
                  state: c.coins,
                  onChanged: (e) {
                    c.amount.value = e;
                    c.recalculateAmount();
                  },
                  maximum: c.balance.value,
                  label: 'Сумма к списанию, \$',
                ),
                const SizedBox(height: 16),
                Obx(() {
                  final CurrencyKind currency = c.method.value.currency;
                  final double? minimum = c.method.value.minimum;
                  final double? maximum = c.method.value.maximum;

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
                const SizedBox(height: 8),
              ],
            );
          }),
          Block(
            children: [
              Text.rich(
                const TextSpan(
                  children: [
                    TextSpan(
                      text:
                          'Я подтверждаю, что реквизиты и данные получателя денежных средств указаны верно, и принимаю на себя всю ответственность в случае ввода некорректных данных.',
                    ),
                  ],
                ),
                style: style.fonts.small.regular.secondary,
              ),
              const SizedBox(height: 12),
              Obx(() {
                return RectangleButton(
                  label: 'Подтверждаю',
                  selected: c.confirmed.value,
                  onPressed: c.confirmed.toggle,
                  radio: true,
                  toggleable: true,
                );
              }),
              const SizedBox(height: 12),
              const SizedBox(height: 12),
              Text(
                'Счет-фактура формируется автоматически во время отправки денежных средств и прилагается к соответствующей транзакции.',
                style: style.fonts.small.regular.secondary,
              ),
              const SizedBox(height: 12),
              Obx(() {
                bool enabled = c.amount.value != 0 &&
                    c.verified.value &&
                    c.confirmed.value;

                switch (c.method.value) {
                  case WithdrawMethod.usdt:
                    enabled = enabled && !c.usdtWallet.isEmpty.value;
                    break;

                  case WithdrawMethod.paypal:
                    enabled = enabled && !c.email.isEmpty.value;
                    break;

                  case WithdrawMethod.paysera:
                    enabled = enabled && !c.payseraWallet.isEmpty.value;
                    break;

                  case WithdrawMethod.payeer:
                    enabled = enabled && !c.payeerWallet.isEmpty.value;
                    break;

                  case WithdrawMethod.monobank:
                    enabled = enabled &&
                        !c.monobankWallet.isEmpty.value &&
                        !c.monobankBik.isEmpty.value &&
                        !c.monobankName.isEmpty.value &&
                        !c.monobankAddress.isEmpty.value;
                    break;

                  case WithdrawMethod.skrill:
                    enabled = enabled && !c.email.isEmpty.value;
                    break;

                  case WithdrawMethod.revolut:
                    enabled = enabled &&
                        !c.revolutWallet.isEmpty.value &&
                        !c.revolutBik.isEmpty.value;
                    break;

                  case WithdrawMethod.sepa:
                    enabled = enabled &&
                        !c.sepaWallet.isEmpty.value &&
                        !c.sepaName.isEmpty.value &&
                        !c.sepaAddress.isEmpty.value &&
                        !c.sepaBik.isEmpty.value;
                    break;

                  case WithdrawMethod.swift:
                    enabled = enabled &&
                        !c.swiftCurrency.isEmpty.value &&
                        !c.swiftName.isEmpty.value &&
                        !c.swiftAddress.isEmpty.value &&
                        !c.swiftBik.isEmpty.value;
                    break;

                  default:
                    break;
                }

                return PrimaryButton(
                  title: 'Отправить заявку'.l10n,
                  onPressed: () async {
                    void verify() {
                      c.itemScrollController.scrollTo(
                        index: 1,
                        alignment: 1,
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 600),
                      );
                      c.highlight(0);
                    }

                    if (c.name.isEmpty.value) {
                      c.name.error.value = 'err_input_empty'.l10n;
                      return verify();
                    }

                    if (c.birthday.value == null) {
                      c.birthdayError.value = 'err_input_empty'.l10n;
                      return verify();
                    }

                    if (c.address.isEmpty.value) {
                      c.address.error.value = 'err_input_empty'.l10n;
                      return verify();
                    }

                    if (c.index.isEmpty.value) {
                      c.index.error.value = 'err_input_empty'.l10n;
                      return verify();
                    }

                    if (c.phone.isEmpty.value) {
                      c.phone.error.value = 'err_input_empty'.l10n;
                      return verify();
                    }

                    if (c.passport.value == null) {
                      c.passportError.value = 'Отсутствует фото'.l10n;
                      c.itemScrollController.scrollTo(
                        index: 0,
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 600),
                      );
                      c.highlight(0);
                      return;
                    }

                    void scroll() {
                      c.itemScrollController.scrollTo(
                        index: 3,
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 600),
                      );
                      c.highlight(3);
                    }

                    switch (c.method.value) {
                      case WithdrawMethod.usdt:
                        if (c.usdtWallet.isEmpty.value) {
                          c.usdtWallet.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      case WithdrawMethod.paypal:
                        if (c.email.isEmpty.value) {
                          c.email.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      case WithdrawMethod.paysera:
                        if (c.payseraWallet.isEmpty.value) {
                          c.payseraWallet.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      case WithdrawMethod.payeer:
                        if (c.payeerWallet.isEmpty.value) {
                          c.payeerWallet.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      case WithdrawMethod.monobank:
                        if (c.monobankWallet.isEmpty.value) {
                          c.monobankWallet.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.monobankBik.isEmpty.value) {
                          c.monobankBik.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.monobankName.isEmpty.value) {
                          c.monobankName.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.monobankAddress.isEmpty.value) {
                          c.monobankAddress.error.value =
                              'err_input_empty'.l10n;
                        }
                        break;

                      case WithdrawMethod.skrill:
                        if (c.email.isEmpty.value) {
                          c.email.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      case WithdrawMethod.revolut:
                        if (c.revolutWallet.isEmpty.value) {
                          c.revolutWallet.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.revolutBik.isEmpty.value) {
                          c.revolutBik.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      case WithdrawMethod.sepa:
                        if (c.sepaWallet.isEmpty.value) {
                          c.sepaWallet.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.sepaName.isEmpty.value) {
                          c.sepaName.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.sepaAddress.isEmpty.value) {
                          c.sepaAddress.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.sepaBik.isEmpty.value) {
                          c.sepaBik.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      case WithdrawMethod.swift:
                        if (c.swiftCurrency.isEmpty.value) {
                          c.swiftCurrency.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.swiftWallet.isEmpty.value) {
                          c.swiftWallet.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.swiftName.isEmpty.value) {
                          c.swiftName.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.swiftAddress.isEmpty.value) {
                          c.swiftAddress.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        if (c.swiftBik.isEmpty.value) {
                          c.swiftBik.error.value = 'err_input_empty'.l10n;
                          return scroll();
                        }
                        break;

                      default:
                        break;
                    }

                    if (c.coins.isEmpty.value) {
                      c.coins.error.value = 'err_input_empty'.l10n;
                      return scroll();
                    } else if (c.coins.error.value != null) {
                      return scroll();
                    }

                    final double? minimum = c.method.value.minimum;
                    final double? maximum = c.method.value.maximum;

                    if (minimum != null && c.total.value < minimum) {
                      return scroll();
                    }

                    if (maximum != null && c.total.value > maximum) {
                      return scroll();
                    }

                    if (c.balance.value < c.amount.value) {
                      return scroll();
                    }

                    if (!c.confirmed.value) {
                      await MessagePopup.error(
                        'Я подтверждаю, что реквизиты и данные получателя денежных средств указаны верно, и принимаю на себя всю ответственность в случае ввода некорректных данных.',
                        title: 'label_confirmation',
                        button: (context) {
                          return RectangleButton(
                            label: 'Подтверждаю',
                            onPressed: () => Navigator.of(context).pop(true),
                            radio: true,
                            toggleable: true,
                          );
                        },
                      );
                      c.confirmed.value = true;
                      return;
                    }

                    await MessagePopup.error('Hooray!', title: 'Sent 🎉');
                  },
                  // onPressed: enabled ? () {} : null,
                );
              }),
              const SizedBox(height: 8),
            ],
          ),
        ];

        return Scaffold(
          appBar: CustomAppBar(
            leading: const [StyledBackButton()],
            title: Row(
              children: [
                const SizedBox(width: 8),
                if (context.isNarrow) ...[
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, snapshot) {
                        final double occupies =
                            'label_order_payment'.l10n.length * 12;

                        if (occupies >= snapshot.maxWidth) {
                          return Text(
                            'label_order_payment_desc'.l10n,
                            textAlign: TextAlign.left,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: style.fonts.medium.regular.onBackground
                                .copyWith(height: 1),
                          );
                        }

                        return Text(
                          'label_order_payment'.l10n,
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
                      '\$ ${c.balance.value.toInt().withSpaces()}',
                      style: style.fonts.big.regular.onBackground.copyWith(
                        color: style.colors.acceptPrimary,
                      ),
                    );
                  }),
                ] else ...[
                  Expanded(
                    child: Text(
                      'label_order_payment'.l10n,
                      textAlign:
                          context.isNarrow ? TextAlign.left : TextAlign.center,
                      style: style.fonts.large.regular.onBackground,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                const SizedBox(width: 16),
              ],
            ),
          ),
          body: ScrollablePositionedList.builder(
            key: const Key('UserScrollable'),
            itemCount: blocks.length,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            itemBuilder: (_, i) => Obx(() {
              return HighlightedContainer(
                highlight: c.highlighted.value == i,
                child: blocks[i],
              );
            }),
            scrollController: c.scrollController,
            itemScrollController: c.itemScrollController,
            itemPositionsListener: c.positionsListener,
            initialScrollIndex: 0,
          ),
        );
      },
    );
  }

  Widget _verification(BuildContext context, WithdrawController c) {
    final style = Theme.of(context).style;

    return VerificationBlock(
      person: c.person.value,
      editing: c.verificationEditing.value,
      onChanged: (s) => c.person.value = s,
      onEditing: (e) {
        c.itemScrollController.scrollTo(
          index: 0,
          curve: Curves.ease,
          duration: const Duration(milliseconds: 600),
        );

        c.highlight(0);

        c.verificationEditing.value = e;
        if (!e) {
          c.verify();
        }
      },
      myUser: c.myUser,
    );
  }
}

extension on int {
  String withSpaces() {
    return NumberFormat('#,##0').format(this);
  }
}

// class _CountrySelectorNavigator extends CountrySelectorNavigator {
//   const _CountrySelectorNavigator()
//       : super(
//           searchAutofocus: false,
//         );

//   @override
//   Future<Country?> navigate(BuildContext context, dynamic flagCache) {
//     return ModalPopup.show(
//       context: context,
//       child: CountrySelector(
//         countries: countries,
//         onCountrySelected: (country) =>
//             Navigator.of(context, rootNavigator: true).pop(country),
//         flagCache: flagCache,
//         subtitle: null,
//       ),
//     );
//   }
// }

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
