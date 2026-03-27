// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:get/get.dart';

import '/ui/worker/upgrade.dart';

/// Possible [UpgradePopupView] screens.
enum UpgradePopupScreen { notice, download }

/// Controller of an [UpgradePopupView].
class UpgradePopupController extends GetxController {
  UpgradePopupController(this._upgradeWorker);

  /// [UpgradePopupScreen] to display currently.
  final Rx<UpgradePopupScreen> screen = Rx(UpgradePopupScreen.notice);

  /// [UpgradeWorker] to skip the [Release]s.
  final UpgradeWorker _upgradeWorker;

  /// Skips the provided [release].
  Future<void> skip(Release release) async {
    await _upgradeWorker.skip(release);
  }

  /// Initiates the downloading of the provided [artifact].
  Future<void> download(ReleaseArtifact artifact) async {
    await _upgradeWorker.download(artifact);
  }
}
