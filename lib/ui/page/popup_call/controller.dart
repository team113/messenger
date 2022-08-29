// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
import 'dart:convert';

import 'package:get/get.dart';
import 'package:wakelock/wakelock.dart';

import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/service/call.dart';
import '/routes.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of the [Routes.call] page.
class PopupCallController extends GetxController {
  PopupCallController(this.chatId, this._calls);

  /// ID of a [Chat] this [call] is taking place in.
  final ChatId chatId;

  /// Reactive [OngoingCall] this [PopupCallController] represents.
  late final Rx<OngoingCall> call;

  /// [CallService] maintaining the [call].
  final CallService _calls;

  /// [StreamSubscription] to [WebUtils.onStorageChange] communicating with the
  /// main application.
  StreamSubscription? _storageSubscription;

  /// [Worker] reacting on [OngoingCall.state] changes updating the [call] in
  /// the browser's storage.
  late final Worker _stateWorker;

  /// Returns ID of the authenticated [MyUser].
  UserId get me => _calls.me;

  @override
  void onInit() {
    Uri uri = Uri.parse(router.route);

    WebStoredCall? stored = WebUtils.getCall(chatId);
    if (stored == null || WebUtils.credentials == null) {
      return WebUtils.closeWindow();
    }

    call = _calls.addStored(
      stored,
      withAudio: uri.queryParameters['audio'] != 'false',
      withVideo: uri.queryParameters['video'] == 'true',
      withScreen: uri.queryParameters['screen'] == 'true',
    );

    _stateWorker = ever(
      call.value.state,
      (OngoingCallState state) {
        WebUtils.setCall(call.value.toStored());
        if (state == OngoingCallState.ended) {
          WebUtils.closeWindow();
        }
      },
    );

    _storageSubscription = WebUtils.onStorageChange.listen((e) {
      if (e.key == null) {
        WebUtils.closeWindow();
      } else if (e.newValue == null) {
        if (e.key == 'credentials' || e.key == 'call_${call.value.chatId}') {
          WebUtils.closeWindow();
        }
      } else if (e.key == 'call_${call.value.chatId}') {
        var stored = WebStoredCall.fromJson(json.decode(e.newValue!));
        call.value.call.value = stored.call;
        call.value.creds = call.value.creds ?? stored.creds;
        call.value.deviceId = call.value.deviceId ?? stored.deviceId;
        call.value.chatId.value = stored.chatId;
        _tryToConnect();
      }
    });

    _tryToConnect();
    Wakelock.enable();
    super.onInit();
  }

  @override
  void onClose() {
    Wakelock.disable();
    WebUtils.removeCall(call.value.chatId.value);
    _storageSubscription?.cancel();
    _stateWorker.dispose();
    _calls.leave(call.value.chatId.value, call.value.deviceId!);
    super.dispose();
  }

  /// Invokes the [OngoingCall.connect], if [me] is the caller or the [call] is
  /// in its active state.
  ///
  /// Otherwise the [OngoingCall.connect] should be invoked via the
  /// [CallService.join] method.
  void _tryToConnect() {
    if (call.value.caller?.id == me || call.value.isActive) {
      call.value.connect(_calls);
    }
  }
}
