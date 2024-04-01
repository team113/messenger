import 'package:get/get.dart';
import 'package:messenger/routes.dart';

class WithdrawMethodController extends GetxController {
  WithdrawMethodController({
    WithdrawMethod initial = WithdrawMethod.usdt,
  }) : method = Rx(initial);

  final Rx<WithdrawMethod> method;
}
