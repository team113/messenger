import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/service/work.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:phone_form_field/phone_form_field.dart';

class WithdrawController extends GetxController {
  WithdrawController(this._workService);

  final TextFieldState coins = TextFieldState(onChanged: (e) {});
  final TextFieldState money = TextFieldState(onChanged: (e) {});

  final TextFieldState name = TextFieldState();
  final TextFieldState address = TextFieldState();
  final TextFieldState index = TextFieldState();
  final TextFieldState email = TextFieldState();
  final TextFieldState phone = TextFieldState();

  final Rx<Country?> country = Rx(null);
  final Rx<PlatformFile?> contract = Rx(null);
  final Rx<PlatformFile?> passport = Rx(null);

  final TextFieldState usdtWallet = TextFieldState();
  final TextFieldState btcWallet = TextFieldState();
  final TextFieldState cardNumber = TextFieldState();
  final TextFieldState cardExpire = TextFieldState();

  final RxInt amount = RxInt(0);
  final RxDouble total = RxDouble(0);

  final Rx<WithdrawMethod> method = Rx(WithdrawMethod.usdt);

  final WorkService _workService;

  RxDouble get balance => _workService.balance;

  double _commission() {
    return switch (method.value) {
      WithdrawMethod.card => total.value * 0.015,
      WithdrawMethod.paypal => 0,
      WithdrawMethod.swift => 100,
      WithdrawMethod.sepa => 5,
      WithdrawMethod.usdt => 3,
      WithdrawMethod.bitcoin => 0.000042,
    };
  }

  void recalculateAmount() {
    total.value = switch (method.value) {
      WithdrawMethod.card ||
      WithdrawMethod.paypal ||
      WithdrawMethod.swift =>
        amount.value / 100 / 2,
      WithdrawMethod.sepa => amount.value / 110 / 2,
      WithdrawMethod.usdt => amount.value / 100 / 2,
      WithdrawMethod.bitcoin => amount.value / 100000000 / 2,
    };

    total.value = max(0, total.value - _commission());

    total.value = switch (method.value) {
      WithdrawMethod.bitcoin => total.value,
      (_) => double.tryParse(total.value.toStringAsFixed(2)) ?? total.value,
    };

    money.text = amount.value.toString();

    print('[recalculateAmount]: ${amount.value} vs ${total.value}');
  }

  void recalculateTotal() {
    double convert(num from) {
      return switch (method.value) {
        WithdrawMethod.card ||
        WithdrawMethod.paypal ||
        WithdrawMethod.swift =>
          from * 100 * 2,
        WithdrawMethod.sepa => from * 110 * 2,
        WithdrawMethod.usdt => from * 100 * 2,
        WithdrawMethod.bitcoin => from * 100000000 * 2,
      };
    }

    amount.value = convert(total.value + _commission()).round();
    coins.text = amount.value.withSpaces();
  }
}

extension on int {
  String withSpaces() {
    return NumberFormat('#,##0').format(this);
  }
}
