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

import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../domain/model/chat_call.dart';
import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/service/call.dart';
import '/routes.dart';
import '/util/log.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of the [Routes.call] page.
class PopupCallController extends GetxController {
  PopupCallController(this.chatId, this._calls);

  /// ID of a [Chat] this [call] is taking place in.
  final ChatId chatId;

  /// Reactive [OngoingCall] this [PopupCallController] represents.
  final Rx<Rx<OngoingCall>?> call = Rx(null);

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
  void onInit() async {
    _storageSubscription = WebUtils.onStorageChange.listen((e) {
      Log.debug(
        'WebUtils.onStorageChange(${e.key}): ${e.newValue}',
        '$runtimeType',
      );

      if (e.key == null) {
        WebUtils.closeWindow();
      } else if (e.newValue == null) {
        if (e.key == 'call_${call.value?.value.chatId}') {
          WebUtils.closeWindow();
        }
      }
      // else if (e.key == 'call_${call.value.chatId}') {
      //   var stored = WebStoredCall.fromJson(json.decode(e.newValue!));
      //   call.value.call.value = stored.call;
      //   call.value.creds = call.value.creds ?? stored.creds;
      //   call.value.deviceId = call.value.deviceId ?? stored.deviceId;
      //   call.value.chatId.value = stored.chatId;
      //   _tryToConnect();
      // }
    });

    ActiveCall? stored = await _calls.getCall(chatId);
    if (stored == null) {
      return WebUtils.closeWindow();
    }

    call.value = _calls.addStored(
      stored,
      withAudio: router.arguments?['audio'] != 'false',
      withVideo: router.arguments?['video'] == 'true',
      withScreen: router.arguments?['screen'] == 'true',
    );

    if (call.value != null) {
      _stateWorker = ever(
        call.value!.value.state,
        (OngoingCallState state) {
          // WebUtils.setCall(call.value.toStored());
          if (state == OngoingCallState.ended) {
            WebUtils.closeWindow();
          }
        },
      );
    }

    _tryToConnect();
    WakelockPlus.enable().onError((_, __) => false);

    super.onInit();
  }

  @override
  void onClose() {
    WakelockPlus.disable().onError((_, __) => false);
    _storageSubscription?.cancel();
    _stateWorker.dispose();
    if (call.value != null) {
      _calls.leave(call.value!.value.chatId.value);
    }
    WebUtils.closeWindow();
    super.dispose();
  }

  /// Invokes the [OngoingCall.connect], if [me] is the caller or the [call] is
  /// in its active state.
  ///
  /// Otherwise the [OngoingCall.connect] should be invoked via the
  /// [CallService.join] method.
  void _tryToConnect() {
    if (call.value?.value.caller?.id == me ||
        call.value?.value.isActive == true) {
      call.value?.value.connect(_calls);
    }
  }
}
