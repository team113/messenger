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

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/service/call.dart';
import '/routes.dart';
import '/util/platform_utils.dart';
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

  late final WindowController? _windowController;

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
    if (!PlatformUtils.isWeb) {
      _windowController = WindowController.fromWindowId(router.windowId!);
    }

    WebStoredCall? stored;
    if (PlatformUtils.isWeb) {
      stored = WebUtils.getCall(chatId);
    } else if (PlatformUtils.isDesktop) {
      stored = router.call;
    }

    if (stored == null ||
        (PlatformUtils.isWeb && WebUtils.credentials == null)) {
      return WebUtils.closeWindow();
    }

    // TODO: get audio, video and screen state from [WebStoredCall]
    call = _calls.addStored(
      stored,
      withAudio: true,
      withVideo: false,
      withScreen: false,
    );

    _stateWorker = ever(
      call.value.state,
      (OngoingCallState state) {
        if (PlatformUtils.isWeb) {
          WebUtils.setCall(call.value.toStored());
          if (state == OngoingCallState.ended) {
            WebUtils.closeWindow();
          }
        } else {
          DesktopMultiWindow.invokeMethod(
            0,
            'call_${call.value.chatId.value.val}',
            json.encode(call.value.toStored().toJson()),
          );
          if (state == OngoingCallState.ended) {
            _windowController?.close();
          }
        }
      },
    );

    if (PlatformUtils.isWeb) {
      _storageSubscription = WebUtils.onStorageChange.listen((e) {
        if (e.key == null) {
          WebUtils.closeWindow();
        } else if (e.newValue == null) {
          if (e.key == 'credentials' || e.key == 'call_${call.value.chatId}') {
            WebUtils.closeWindow();
          }
        } else if (e.key == 'call_${call.value.chatId}') {
          var newValue = WebStoredCall.fromJson(json.decode(e.newValue!));
          call.value.call.value = newValue.call;
          call.value.creds = call.value.creds ?? newValue.creds;
          call.value.deviceId = call.value.deviceId ?? newValue.deviceId;
          call.value.chatId.value = newValue.chatId;
          _tryToConnect();
        }
      });
    } else {
      _windowController?.setOnWindowClose(() async {
        _storageSubscription?.cancel();
        _stateWorker.dispose();
        DesktopMultiWindow.invokeMethod(
          0,
          'call_${call.value.chatId.value.val}',
        );
        await _calls.leave(call.value.chatId.value, call.value.deviceId!);
      });

      DesktopMultiWindow.setMethodHandler((methodCall, fromWindowId) async {
        print('setMethodHandler in separate window');
        print(methodCall.arguments);
        if (methodCall.method == 'call') {
          if (methodCall.arguments == null) {
            _windowController?.close();
          }

          var newValue =
              WebStoredCall.fromJson(json.decode(methodCall.arguments));

          call.value.call.value = newValue.call;
          call.value.creds = call.value.creds ?? newValue.creds;
          call.value.deviceId = call.value.deviceId ?? newValue.deviceId;
          call.value.chatId.value = newValue.chatId;
          _tryToConnect();
        }
      });
    }

    _tryToConnect();
    super.onInit();
  }

  @override
  void onClose() {
    if(PlatformUtils.isWeb) {
      WebUtils.removeCall(call.value.chatId.value);
    } else {
      DesktopMultiWindow.invokeMethod(
        0,
        'call_${call.value.chatId.value.val}',
      );
    }
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
