import 'package:get/get.dart';
import 'package:messenger/domain/service/work.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/text_field.dart';

class WithdrawController extends GetxController {
  WithdrawController(this._workService);

  final TextFieldState money = TextFieldState(
    onChanged: (e) {},
  );

  final RxInt amount = RxInt(0);

  final Rx<WithdrawMethod> method = Rx(WithdrawMethod.usdt);

  final WorkService _workService;

  RxDouble get balance => _workService.balance;
}
