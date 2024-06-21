import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/service/balance.dart';
import '/domain/service/my_user.dart';
import '/ui/widget/text_field.dart';

class TransactionsController extends GetxController {
  TransactionsController(this._balanceService, this._myUserService);

  final RxBool expanded = RxBool(false);

  final RxBool includeHold = RxBool(true);
  final RxBool includeCompleted = RxBool(true);

  final GlobalKey filterKey = GlobalKey();

  final TextFieldState search = TextFieldState();

  final RxnString query = RxnString();

  final RxSet<String> ids = RxSet();

  final BalanceService _balanceService;
  final MyUserService _myUserService;

  RxList<Transaction> get transactions => _balanceService.transactions;
  Rx<MyUser?> get myUser => _myUserService.myUser;

  RxDouble get hold => _balanceService.hold;
}
