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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/push_token.dart';
import '/domain/model/session.dart';
import '/domain/repository/session.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/domain/service/session.dart';
import '/l10n/l10n.dart';
import '/ui/worker/upgrade.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Controller of the `Routes.support` page.
class SupportController extends GetxController {
  SupportController(
    this._upgradeWorker,
    this._authService,
    this._myUserService,
    this._sessionService,
    this._notificationService,
  );

  /// [PlatformUtilsImpl.userAgent] string.
  final RxnString userAgent = RxnString();

  /// Indicator whether [checkForUpdates] is currently being executed.
  final RxBool checkingForUpdates = RxBool(false);

  /// [UpgradeWorker] to check for new application updates.
  final UpgradeWorker _upgradeWorker;

  /// [AuthService] used to retrieve the current [sessionId].
  final AuthService _authService;

  /// [MyUserService] used to retrieve the current [MyUser].
  final MyUserService? _myUserService;

  /// [SessionService] maintaining the [Session]s.
  final SessionService? _sessionService;

  /// [NotificationService] having the [DeviceToken] information.
  final NotificationService? _notificationService;

  /// Returns the currently authenticated [MyUser], if any.
  Rx<MyUser?>? get myUser => _myUserService?.myUser;

  /// Returns the [Session]s known to this device, if any.
  RxList<RxSession>? get sessions => _sessionService?.sessions;

  /// Returns the currently authenticated [SessionId], if any.
  SessionId? get sessionId => _authService.credentials.value?.session.id;

  /// Returns the [DeviceToken] of this device, if any.
  DeviceToken? get token => _notificationService?.token;

  /// Indicates whether the [NotificationService] reports push notifications as
  /// being active.
  bool? get pushNotifications => _notificationService?.pushNotifications;

  /// Fetches the application updates via the [UpgradeWorker].
  Future<void> checkForUpdates() async {
    checkingForUpdates.value = true;

    try {
      final hasUpdates = await _upgradeWorker.fetchUpdates(force: true);
      if (!hasUpdates) {
        MessagePopup.alert(
          'label_no_updates_are_available_title'.l10n,
          description: [
            TextSpan(text: 'label_no_updates_are_available_subtitle'.l10n),
          ],
        );
      }
    } finally {
      checkingForUpdates.value = false;
    }
  }
}
