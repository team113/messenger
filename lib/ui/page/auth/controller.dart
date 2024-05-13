// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import '/l10n/l10n.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/routes.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Possible [Routes.auth] page screens.
enum AuthScreen { accounts, signIn }

/// [Routes.auth] page controller.
class AuthController extends GetxController {
  AuthController(this._auth);

  /// Current [AnimatedLogo] animation frame.
  final RxInt logoFrame = RxInt(0);

  /// Current [AuthScreen] of this controller.
  late final Rx<AuthScreen> screen =
      Rx(profiles.isEmpty ? AuthScreen.signIn : AuthScreen.accounts);

  /// Authorization service used for signing up.
  final AuthService _auth;

  /// [Timer] periodically increasing the [logoFrame].
  Timer? _animationTimer;

  /// [Sentry] transaction monitoring this [AuthController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.auth.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  )..startChild('ready');

  /// Returns user authentication status.
  Rx<RxStatus> get authStatus => _auth.status;

  /// Returns the reactive list of known [MyUser]s.
  RxList<MyUser> get profiles => _auth.profiles;

  /// Returns the [Credentials] of the available accounts.
  RxMap<UserId, Rx<Credentials>> get accounts => _auth.accounts;

  @override
  void onReady() {
    SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());
    super.onReady();
  }

  @override
  void onClose() {
    _animationTimer?.cancel();
    super.onClose();
  }

  /// Registers and redirects to the [Routes.home] page.
  Future<void> register() async {
    try {
      await _auth.register();
      router.home();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Signs in as the provided [MyUser] and redirects to the [Routes.home] page.
  Future<void> signInAs(MyUser myUser) async {
    final bool succeeded = await _auth.switchAccount(myUser.id);

    router.home();

    if (!succeeded) {
      await Future.delayed(500.milliseconds);
      MessagePopup.error('err_account_unavailable'.l10n);
    }
  }

  /// Removes the [myUser] from both the [profiles] and [accounts].
  Future<void> deleteAccount(MyUser myUser) async {
    await _auth.removeAccount(myUser.id);
  }

  /// Resets the [logoFrame] and starts the blinking animation.
  void animate() {
    logoFrame.value = 1;
    _animationTimer?.cancel();
    _animationTimer = Timer.periodic(
      const Duration(milliseconds: 45),
      (t) {
        ++logoFrame.value;
        if (logoFrame >= 9) t.cancel();
      },
    );
  }
}
