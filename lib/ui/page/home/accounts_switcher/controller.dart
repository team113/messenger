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

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/api/backend/schema.graphql.dart';
import '/domain/model/my_user.dart';
import '/domain/model/session.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';
import '/ui/widget/text_field.dart';
import '/routes.dart';
import 'view.dart';

/// Controller of an [AccountsSwitcherView].
class AccountsSwitcherController extends GetxController {
  AccountsSwitcherController(this._myUserService, this._authService);

  /// [MyUser.status] field state.
  late final TextFieldState status = TextFieldState(
    text: myUser.value?.status?.val,
    onFocus: (s) async {
      s.error.value = null;

      if (s.text.trim().isNotEmpty) {
        try {
          UserTextStatus(s.text);
        } on FormatException catch (_) {
          s.error.value = 'err_incorrect_input'.l10n;
          return;
        }
      }

      final UserTextStatus? status = UserTextStatus.tryParse(s.text);

      try {
        await _myUserService.updateUserStatus(status);
      } catch (_) {
        s.error.value = 'err_data_transfer'.l10n;
      }
    },
  );

  /// Known [MyUser] accounts that can be displayed in view.
  final RxList<Rx<MyUser>> accounts = RxList();

  /// [MyUserService] to obtain [accounts] and [me].
  final MyUserService _myUserService;

  /// [AuthService] providing the authentication capabilities.
  final AuthService _authService;

  /// Subscription for [MyUserService.profiles] changes updating the [accounts]
  /// list.
  StreamSubscription? _profilesSubscription;

  /// [Stopwatch] measuring how much time has passed since last
  /// [_scheduleRebuild] to stop it when it exceeds some limit.
  Stopwatch? _startedAt;

  /// Returns [UserId] of currently authenticated [MyUser].
  UserId? get me => _authService.userId;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get myUser => _myUserService.myUser;

  /// Returns a reactive map of all the active [Credentials] for [accounts].
  ///
  /// Accounts whose [UserId]s are present in this set are available for
  /// switching.
  RxMap<UserId, Rx<Credentials>> get sessions => _authService.accounts;

  /// Returns a reactive map of all the known [MyUser] profiles for [accounts].
  RxObsMap<UserId, Rx<MyUser>> get _profiles => _myUserService.profiles;

  @override
  void onInit() {
    _scheduleRebuild();

    for (var e in _profiles.values) {
      accounts.add(e);
    }
    accounts.sort(_compareAccounts);

    _profilesSubscription = _profiles.changes.listen((e) async {
      switch (e.op) {
        case OperationKind.added:
          accounts.add(e.value!);
          accounts.sort(_compareAccounts);
          break;

        case OperationKind.removed:
          accounts.removeWhere((u) => u.value.id == e.key);
          break;

        case OperationKind.updated:
          accounts.sort(_compareAccounts);
          break;
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    _profilesSubscription?.cancel();
    super.onClose();
  }

  /// Toggles [MyUser.presence] between [UserPresence.present] and
  /// [UserPresence.away].
  Future<void> togglePresence() async {
    final UserPresence presence = switch (myUser.value?.presence) {
      UserPresence.present => UserPresence.away,
      UserPresence.away => UserPresence.present,
      (_) => UserPresence.present,
    };

    await _myUserService.updateUserPresence(presence);
  }

  /// Switches to the account with the given [id].
  Future<void> switchTo(UserId id) async {
    try {
      router.nowhere();

      final bool succeeded = await _authService.switchAccount(id);
      if (succeeded) {
        await Future.delayed(500.milliseconds);
        router.tab = HomeTab.chats;
        router.home();
      } else {
        await Future.delayed(500.milliseconds);
        router.home();
        await Future.delayed(500.milliseconds);
        MessagePopup.error('err_account_unavailable'.l10n);
      }
    } catch (e) {
      await Future.delayed(500.milliseconds);
      router.home();
      await Future.delayed(500.milliseconds);
      MessagePopup.error(e);
    }
  }

  /// Continuously schedules rebuilds to sync [GlobalKey] changes with the
  /// transition animation.
  void _scheduleRebuild() {
    if (isClosed) {
      return;
    }

    _startedAt ??= Stopwatch()..start();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (_startedAt == null) {
        return;
      }

      // This should equal the duration of `AccountsSwitcherView.show()`
      // transition so that any changes of `GlobalKey` are applied during that.
      if (_startedAt!.elapsedMilliseconds >= 300) {
        _startedAt?.stop();
        _startedAt = null;
        return;
      }

      refresh();
      _scheduleRebuild();
    });
  }

  /// Compares two [MyUser]s based on their last seen times and the online
  /// statuses.
  int _compareAccounts(Rx<MyUser> a, Rx<MyUser> b) {
    if (a.value.id == me) {
      return -1;
    } else if (b.value.id == me) {
      return 1;
    } else if (a.value.online && !b.value.online) {
      return -1;
    } else if (!a.value.online && b.value.online) {
      return 1;
    } else if (a.value.lastSeenAt == null || b.value.lastSeenAt == null) {
      return -1;
    }

    return -a.value.lastSeenAt!.compareTo(b.value.lastSeenAt!);
  }
}
