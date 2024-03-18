import 'package:get/get.dart';

enum UpgradePopupScreen { notice, download }

class UpgradePopupController extends GetxController {
  final Rx<UpgradePopupScreen> screen = Rx(UpgradePopupScreen.notice);
}
