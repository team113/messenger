// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
//
// This program is free software: you can redistribute it and/or modify it under
// the terms of the GNU Affero General Public License v3.0 as published by the
// Free Software Foundation, either version 3 of the License, or (at your
// option) any later version.
//
// This program is distributed in the hope that it will be useful, but WITHOUT
// ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
// FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License v3.0 for
// more details.
//
// You should have received a copy of the GNU Affero General Public License v3.0
// along with this program. If not, see
// <https://www.gnu.org/licenses/agpl-3.0.html>.

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
