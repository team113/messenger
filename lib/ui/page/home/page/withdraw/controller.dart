import 'package:get/get.dart';
import 'package:messenger/domain/service/work.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';

class WithdrawController extends GetxController {
  WithdrawController(this._workService);

  final TextFieldState coins = TextFieldState(onChanged: (e) {});
  final TextFieldState money = TextFieldState(onChanged: (e) {});

  final RxInt amount = RxInt(0);
  final RxDouble total = RxDouble(0);

  final Rx<WithdrawMethod> method = Rx(WithdrawMethod.usdt);

  final WorkService _workService;

  RxDouble get balance => _workService.balance;

  void recalculateAmount() {
    total.value = switch (method.value) {
      WithdrawMethod.card ||
      WithdrawMethod.paypal ||
      WithdrawMethod.swift =>
        amount.value / 100,
      WithdrawMethod.sepa => amount.value / 110,
      WithdrawMethod.usdt => amount.value / 100,
      WithdrawMethod.bitcoin => amount.value / 100000000,
    };

    money.text = amount.value.toString();

    print('[recalculateAmount]: ${amount.value} vs ${total.value}');
  }

  void recalculateTotal() {
    amount.value = switch (method.value) {
      WithdrawMethod.card ||
      WithdrawMethod.paypal ||
      WithdrawMethod.swift =>
        total.value * 100,
      WithdrawMethod.sepa => total.value * 110,
      WithdrawMethod.usdt => total.value * 100,
      WithdrawMethod.bitcoin => total.value * 100000000,
    }
        .round();

    coins.text = amount.value.toStringAsFixed(0);
  }
}
