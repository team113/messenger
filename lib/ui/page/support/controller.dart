import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/ui/worker/upgrade.dart';
import '/util/message_popup.dart';

/// Controller of the `Routes.support` page.
class SupportController extends GetxController {
  SupportController(this._upgradeWorker);

  /// [UpgradeWorker] to check for new application updates.
  final UpgradeWorker _upgradeWorker;

  /// Indicator whether [checkForUpdates] is currently being executed.
  final RxBool checkingForUpdates = RxBool(false);

  /// Fetches the application updates via the [UpgradeWorker].
  Future<void> checkForUpdates() async {
    checkingForUpdates.value = true;

    try {
      final hasUpdates = await _upgradeWorker.fetchUpdates(force: true);
      if (!hasUpdates) {
        MessagePopup.alert(
          'label_no_updates_are_available_title'.l10n,
          description: [
            TextSpan(text: 'label_no_updates_are_available_subtitle'.l10n)
          ],
        );
      }
    } finally {
      checkingForUpdates.value = false;
    }
  }
}
