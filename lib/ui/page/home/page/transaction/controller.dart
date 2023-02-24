import 'package:get/get.dart';
import 'package:messenger/domain/model/transaction.dart';
import 'package:messenger/domain/service/balance.dart';
import 'package:messenger/domain/service/partner.dart';

class TransactionController extends GetxController {
  TransactionController(
    this.id,
    this._balanceService,
    this._partnerService,
  );

  final Rx<Transaction?> transaction = Rx(null);

  final String id;
  final BalanceService _balanceService;
  final PartnerService _partnerService;

  @override
  void onInit() {
    transaction.value =
        _balanceService.transactions.firstWhereOrNull((e) => e.id == id) ??
            _partnerService.transactions.firstWhereOrNull((e) => e.id == id);

    super.onInit();
  }
}
