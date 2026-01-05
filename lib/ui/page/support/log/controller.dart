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

import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_io/io.dart';

import '/config.dart';
import '/domain/model/my_user.dart';
import '/domain/model/push_token.dart';
import '/domain/model/session.dart';
import '/domain/repository/session.dart';
import '/domain/service/auth.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/domain/service/session.dart';
import '/provider/file/log.dart';
import '/pubspec.g.dart';
import '/util/log.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// Controller of a [LogView].
class LogController extends GetxController {
  LogController(
    this._authService,
    this._myUserService,
    this._sessionService,
    this._notificationService,
    this._logProvider,
  );

  /// [ScrollController] to use in a [ListView].
  final ScrollController scrollController = ScrollController();

  /// [PlatformUtilsImpl.userAgent] string.
  final RxnString userAgent = RxnString();

  /// [NotificationSettings] the [FirebaseMessaging] has currently.
  final Rx<NotificationSettings?> notificationSettings = Rx(null);

  /// [FileStat] of the written [File] of the [LogEntry]ies.
  final Rx<FileStat?> stat = Rx(null);

  /// [AuthService] used to retrieve the current [sessionId].
  final AuthService _authService;

  /// [MyUserService] used to retrieve the current [MyUser].
  final MyUserService? _myUserService;

  /// [SessionService] maintaining the [Session]s.
  final SessionService? _sessionService;

  /// [NotificationService] having the [DeviceToken] information.
  final NotificationService? _notificationService;

  /// [LogFileProvider] to read a [File] of the [LogEntry] from.
  final LogFileProvider? _logProvider;

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

  @override
  void onInit() {
    PlatformUtils.userAgent.then((e) => userAgent.value = e);
    getNotificationSettings().then((e) => notificationSettings.value = e);
    _tryFile();
    super.onInit();
  }

  /// Creates and downloads the [report] as a `.txt` file.
  static Future<void> download({
    List<RxSession>? sessions,
    SessionId? sessionId,
    String? userAgent,
    MyUser? myUser,
    DeviceToken? token,
    bool? pushNotifications,
    NotificationSettings? notificationSettings,
  }) async {
    try {
      final encoder = Utf8Encoder();

      final DateTime utc = DateTime.now().toUtc();
      final String app = PlatformUtils.isWeb
          ? Config.origin
                .replaceFirst('https://', '')
                .replaceFirst('http://', '')
          : Config.userAgentProduct;

      final file = await PlatformUtils.createAndDownload(
        '${app.toLowerCase()}_bug_report_${utc.year.toString().padLeft(4, '0')}.${utc.month.toString().padLeft(2, '0')}.${utc.day.toString().padLeft(2, '0')}_${utc.hour.toString().padLeft(2, '0')}.${utc.minute.toString().padLeft(2, '0')}.${utc.second.toString().padLeft(2, '0')}.log',
        encoder.convert(
          LogController.report(
            sessions: sessions,
            sessionId: sessionId,
            userAgent: userAgent,
            myUser: myUser,
            token: token,
            pushNotifications: pushNotifications,
            notificationSettings: notificationSettings,
          ),
        ),
      );

      if (file != null && PlatformUtils.isMobile) {
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
      }
    } catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Returns a report of the technical information and [LogEntry]s.
  static String report({
    List<RxSession>? sessions,
    SessionId? sessionId,
    String? userAgent,
    MyUser? myUser,
    DeviceToken? token,
    bool? pushNotifications,
    NotificationSettings? notificationSettings,
  }) {
    final Session? session = sessions
        ?.firstWhereOrNull((e) => e.session.value.id == sessionId)
        ?.session
        .value;

    return '''
================ Report ================

Created at: ${DateTime.now().toUtc()}
Application: ${Pubspec.ref}
User-Agent: $userAgent
Is PWA: ${WebUtils.isPwa}

MyUser:
${myUser?.toJson()}

SessionId:
$sessionId

Session:
${session?.toJson()}

Push Notifications are considered active:
$pushNotifications

Push Notifications permissions are:
${notificationSettings?.authorizationStatus.name}

Token:
$token

================= Logs =================

${Log.logs.map((e) => e.toString()).join('\n')}

========================================
''';
  }

  /// Tries to retrieve the [notificationSettings] by invoking
  /// [FirebaseMessaging].
  static Future<NotificationSettings?> getNotificationSettings() async {
    if (!PlatformUtils.pushNotifications) {
      // If push notifications aren't considered supported on this device, then
      // there's no need to even try.
      return null;
    }

    try {
      return await FirebaseMessaging.instance.getNotificationSettings();
    } catch (e) {
      Log.debug(
        'Unable to `getNotificationSettings()` due to: $e',
        'LogController',
      );
    }

    return null;
  }

  /// Refreshes the current [Session].
  Future<void> refreshSession() async {
    await _authService.refreshSession(proceedIfRefreshBefore: DateTime.now());
  }

  /// Clears the [LogImpl.logs].
  void clearLogs() {
    Log.logs.clear();
  }

  /// Downloads the [File] with the whole dump of logs, if any.
  Future<void> downloadArchive() async {
    // [File]s aren't available for Web platform.
    if (PlatformUtils.isWeb) {
      return;
    }

    try {
      final File? file = _logProvider?.file;
      if (file == null) {
        return;
      }

      final DateTime utc = DateTime.now().toUtc();
      final String app = PlatformUtils.isWeb
          ? Config.origin
                .replaceFirst('https://', '')
                .replaceFirst('http://', '')
          : Config.userAgentProduct;

      final String filename =
          '${app.toLowerCase()}_dump_${utc.year.toString().padLeft(4, '0')}.${utc.month.toString().padLeft(2, '0')}.${utc.day.toString().padLeft(2, '0')}_${utc.hour.toString().padLeft(2, '0')}.${utc.minute.toString().padLeft(2, '0')}.${utc.second.toString().padLeft(2, '0')}.log';

      if (PlatformUtils.isMobile) {
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, name: filename)]),
        );
      } else if (PlatformUtils.isDesktop) {
        await FilePicker.platform.saveFile(
          fileName: filename,
          lockParentWindow: true,
          bytes: await file.readAsBytes(),
        );
      }
    } catch (e) {
      MessagePopup.error(e);
    }
  }

  /// Retrieves the [FileStat] from the [_logProvider].
  Future<void> _tryFile() async {
    // [File]s aren't available for Web platform.
    if (PlatformUtils.isWeb) {
      return;
    }

    stat.value = await _logProvider?.stat();
  }
}
