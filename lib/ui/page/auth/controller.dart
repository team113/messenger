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

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/worker/upgrade.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Possible [Routes.auth] page screens.
enum AuthScreen { accounts, signIn }

/// [Routes.auth] page controller.
class AuthController extends GetxController {
  AuthController(this._authService, this._upgradeWorker);

  /// Current [AnimatedLogo] animation frame.
  final RxInt logoFrame = RxInt(0);

  /// Current [AuthScreen] of this controller.
  late final Rx<AuthScreen> screen = Rx(
    profiles.isEmpty ? AuthScreen.signIn : AuthScreen.accounts,
  );

  /// Authorization service used for signing up.
  final AuthService _authService;

  /// [UpgradeWorker] for displaying the [UpgradeWorker.scheduled].
  final UpgradeWorker _upgradeWorker;

  /// [Timer] periodically increasing the [logoFrame].
  Timer? _animationTimer;

  /// [Sentry] transaction monitoring this [AuthController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.auth.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  )..startChild('ready');

  /// [profiles] subscription to set [screen] to [AuthScreen.signIn] when
  /// [profiles] become empty.
  StreamSubscription? _accountsSubscription;

  /// Returns user authentication status.
  Rx<RxStatus> get authStatus => _authService.status;

  /// Returns the reactive list of known [MyUser]s.
  RxList<MyUser> get profiles => _authService.profiles;

  /// Returns the [Credentials] of the available accounts.
  RxMap<UserId, Rx<Credentials>> get accounts => _authService.accounts;

  /// Returns the latest [Release] being scheduled to be displayed.
  Rx<Release?> get scheduled => _upgradeWorker.scheduled;

  /// Returns the [ReleaseDownload] being active, if any.
  Rx<ReleaseDownload?> get activeDownload => _upgradeWorker.activeDownload;

  @override
  void onReady() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());

    _accountsSubscription = profiles.listen((accounts) {
      if (accounts.isEmpty) {
        screen.value = AuthScreen.signIn;
      } else {
        screen.value = AuthScreen.accounts;
      }
    });

    super.onReady();
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    _accountsSubscription?.cancel();
    super.onClose();
  }

  /// Registers and redirects to the [Routes.home] page.
  Future<void> register() async {
    try {
      await _authService.register();
      router.home();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Signs in as the provided [MyUser] and redirects to the [Routes.home] page.
  Future<void> signInAs(MyUser myUser) async {
    final bool succeeded = await _authService.switchAccount(myUser.id);

    router.home();

    if (!succeeded) {
      await Future.delayed(500.milliseconds);
      MessagePopup.error('err_account_unavailable'.l10n);
    }
  }

  /// Removes the [myUser] from both the [profiles] and [accounts].
  Future<void> deleteAccount(MyUser myUser) async {
    await _authService.removeAccount(myUser.id);
  }

  /// Resets the [logoFrame] and starts the blinking animation.
  void animate() {
    logoFrame.value = 1;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(const Duration(milliseconds: 45), (t) {
      ++logoFrame.value;
      if (logoFrame >= 9) t.cancel();
    });
  }
}
