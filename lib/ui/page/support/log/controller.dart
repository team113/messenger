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

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/model/push_token.dart';
import '/domain/model/session.dart';
import '/domain/repository/session.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/domain/service/session.dart';
import '/pubspec.g.dart';
import '/util/log.dart';

/// Controller of a [LogView].
class LogController extends GetxController {
  LogController(
    this._authService,
    this._myUserService,
    this._sessionService,
    this._notificationService,
  );

  /// [ScrollController] to use in a [ListView].
  final ScrollController scrollController = ScrollController();

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

  /// Returns a report of the technical information and [Log]s.
  String report() {
    final Session? session = sessions
        ?.firstWhereOrNull((e) => e.session.value.id == sessionId)
        ?.session
        .value;

    return '''
================ Report ================

Created at: ${DateTime.now()}
Application: ${Pubspec.ref}

MyUser:
${myUser?.toJson()}

SessionId:
$sessionId

Session:
${session?.toJson()}

Token:
$token

================= Logs =================

${Log.logs.map((e) => '[${e.at.toStamp}] [${e.level.name}] ${e.text}').join('\n')}

========================================
''';
  }

  /// Refreshes the current [Session].
  Future<void> refreshSession() async {
    await _authService.refreshSession(proceedIfRefreshBefore: DateTime.now());
  }

  /// Clears the [Log.logs].
  void clearLogs() {
    Log.logs.clear();
  }
}

/// Extention adding text representation in stamp view of [DateTime].
extension DateTimeToStamp on DateTime {
  /// Returns this [DateTime] formatted as a stamp.
  String get toStamp {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}:${second.toString().padLeft(2, '0')}.${millisecond.toString().padLeft(4, '0')}';
  }
}
