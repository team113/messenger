import 'dart:async';
import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:messenger/domain/model/native_file.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/domain/model/my_user.dart';
import '/domain/service/balance.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/ui/widget/text_field.dart';

class WithdrawController extends GetxController {
  WithdrawController(this._balanceService, this._myUserService);

  late final TextFieldState coins = TextFieldState(
    onChanged: (e) {},
  );

  final TextFieldState money = TextFieldState(onChanged: (e) {});

  late final TextFieldState name =
      TextFieldState(text: person.value?.name ?? '');
  late final TextFieldState address =
      TextFieldState(text: person.value?.address ?? '');
  late final TextFieldState index =
      TextFieldState(text: person.value?.index ?? '');
  late final TextFieldState phone =
      TextFieldState(text: person.value?.phone ?? '');
  late final Rx<Country?> country = Rx(person.value?.country);
  late final Rx<DateTime?> birthday = Rx(person.value?.birthday);
  final RxnString birthdayError = RxnString();
  late final Rx<NativeFile?> passport = Rx(person.value?.passport);
  final RxnString passportError = RxnString();

  final TextFieldState usdtWallet = TextFieldState();
  final TextFieldState email = TextFieldState();
  final TextFieldState btcWallet = TextFieldState();
  final TextFieldState payseraWallet = TextFieldState();
  final TextFieldState payeerWallet = TextFieldState();
  final TextFieldState monobankWallet = TextFieldState();
  final TextFieldState monobankBik = TextFieldState();
  final TextFieldState monobankName = TextFieldState();
  final TextFieldState monobankAddress = TextFieldState();
  final TextFieldState revolutWallet = TextFieldState();
  final TextFieldState revolutBik = TextFieldState();
  final TextFieldState sepaWallet = TextFieldState();
  final TextFieldState sepaName = TextFieldState();
  final TextFieldState sepaAddress = TextFieldState();
  final TextFieldState sepaBik = TextFieldState();
  final TextFieldState swiftCurrency = TextFieldState();
  final TextFieldState swiftWallet = TextFieldState();
  final TextFieldState swiftName = TextFieldState();
  final TextFieldState swiftAddress = TextFieldState();
  final TextFieldState swiftBik = TextFieldState();
  final TextFieldState swiftCorrespondentName = TextFieldState();
  final TextFieldState swiftCorrespondentAddress = TextFieldState();
  final TextFieldState swiftCorrespondentBik = TextFieldState();
  final TextFieldState swiftCorrespondentWallet = TextFieldState();
  final TextFieldState cardNumber = TextFieldState();
  final TextFieldState cardExpire = TextFieldState();

  final RxInt amount = RxInt(0);
  final RxDouble total = RxDouble(0);

  final Rx<WithdrawMethod> method = Rx(WithdrawMethod.balance);

  late final Rx<VerifiedPerson?> person = Rx(_balanceService.person.value);

  late final TextFieldState paidServices = TextFieldState(
    text: _balanceService.services.value,
  );

  late final RxBool verificationEditing = RxBool(!verified.value);

  final RxBool confirmed = RxBool(false);

  /// Index of an item from [ProfileTab] that should be highlighted.
  final RxnInt highlighted = RxnInt(null);

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [ItemScrollController] of the profile's [ScrollablePositionedList].
  final ItemScrollController itemScrollController = ItemScrollController();

  /// [ItemPositionsListener] of the profile's [ScrollablePositionedList].
  final ItemPositionsListener positionsListener =
      ItemPositionsListener.create();

  final BalanceService _balanceService;
  final MyUserService _myUserService;

  /// [Duration] of the highlighting.
  static const Duration _highlightTimeout = Duration(seconds: 1);

  /// [Timer] resetting the [highlighted] value after the [_highlightTimeout]
  /// has passed.
  Timer? _highlightTimer;

  RxDouble get balance => _balanceService.balance;
  RxBool get verified => _balanceService.verified;
  Rx<MyUser?> get myUser => _myUserService.myUser;

  Future<void> verify() async {
    _balanceService.person.value = person.value?.copyWith();
    verified.value = true;
  }

  void savePerson() {
    _balanceService.person.value = VerifiedPerson(
      name: name.text,
      address: address.text,
      index: index.text,
      phone: phone.text,
      country: country.value,
      birthday: birthday.value,
      passport: passport.value,
    );
  }

  double _commission() {
    return switch (method.value) {
      WithdrawMethod.balance => 0,
      WithdrawMethod.card => total.value * 0.015,
      WithdrawMethod.paypal => 0,
      WithdrawMethod.swift => 100,
      WithdrawMethod.sepa => 5,
      WithdrawMethod.usdt => max(3, total.value * 0.03),
      WithdrawMethod.paysera => 5,
      WithdrawMethod.payeer => total.value * 0.1,
      WithdrawMethod.monobank => 0.25 * 1.1,
      WithdrawMethod.skrill => total.value * 0.01,
      WithdrawMethod.revolut => 0,
    };
  }

  void recalculateAmount() {
    total.value = switch (method.value) {
      WithdrawMethod.balance => amount.value / 1,
      WithdrawMethod.card ||
      WithdrawMethod.paypal ||
      WithdrawMethod.swift =>
        amount.value / 1,
      WithdrawMethod.sepa => amount.value / 1.1,
      WithdrawMethod.usdt => amount.value / 1,
      WithdrawMethod.paysera => amount.value / 1.1,
      WithdrawMethod.payeer => amount.value / 1.1,
      WithdrawMethod.monobank => amount.value / 1.1,
      WithdrawMethod.skrill => amount.value / 1.1,
      WithdrawMethod.revolut => amount.value / 1.1,
    };

    total.value = max(0, total.value - _commission());

    total.value = switch (method.value) {
      // WithdrawMethod.bitcoin => total.value,
      (_) => double.tryParse(total.value.toStringAsFixed(2)) ?? total.value,
    };

    money.text = amount.value.toString();

    print('[recalculateAmount]: ${amount.value} vs ${total.value}');
  }

  void recalculateTotal() {
    double convert(num from) {
      return switch (method.value) {
        WithdrawMethod.balance => from * 1,
        WithdrawMethod.card ||
        WithdrawMethod.paypal ||
        WithdrawMethod.swift =>
          from * 1,
        WithdrawMethod.sepa => from * 1.1,
        WithdrawMethod.usdt => from * 1,
        WithdrawMethod.paysera => from * 1.1,
        WithdrawMethod.payeer => from * 1.1,
        WithdrawMethod.monobank => from * 1.1,
        WithdrawMethod.skrill => from * 1.1,
        WithdrawMethod.revolut => from * 1.1,
      };
    }

    amount.value = convert(total.value + _commission()).round();
    coins.text = amount.value.withSpaces();
  }

  /// Highlights the provided [i].
  Future<void> highlight(int i) async {
    highlighted.value = i;

    _highlightTimer?.cancel();
    _highlightTimer = Timer(_highlightTimeout, () {
      highlighted.value = null;
    });
  }
}

extension on int {
  String withSpaces() {
    return NumberFormat('#,##0').format(this);
  }
}
