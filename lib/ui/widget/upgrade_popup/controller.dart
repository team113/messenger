import 'package:get/get.dart';

import '/ui/worker/upgrade.dart';

/// Possible [UpgradePopupView] screens.
enum UpgradePopupScreen { notice, download }

class UpgradePopupController extends GetxController {
  UpgradePopupController(this._upgradeWorker);

  final Rx<UpgradePopupScreen> screen = Rx(UpgradePopupScreen.notice);

  /// [UpgradeWorker] to skip the [Release]s.
  final UpgradeWorker _upgradeWorker;

  Future<void> skip(Release release) async {
    await _upgradeWorker.skip(release);
  }
}
