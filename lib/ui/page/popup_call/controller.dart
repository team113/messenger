// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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
import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:get/get.dart';
import 'package:wakelock/wakelock.dart';

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

  /// Controller of the popup window on desktop.
  WindowController? _windowController;

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
      _windowController =
          WindowController.fromWindowId(PlatformUtils.windowId!);
    }

    StoredCall? stored;
    if (PlatformUtils.isWeb) {
      stored = WebUtils.getCall(chatId);
    } else if (PlatformUtils.isDesktop) {
      stored = router.call;
    }

    if (stored == null ||
        (PlatformUtils.isWeb && WebUtils.credentials == null)) {
      if (PlatformUtils.isWeb) {
        WebUtils.closeWindow();
      } else {
        _windowController?.close();
      }
      return;
    }

    bool withAudio, withVideo, withScreen;
    if (PlatformUtils.isWeb) {
      Uri uri = Uri.parse(router.route);
      withAudio = uri.queryParameters['audio'] != 'false';
      withVideo = uri.queryParameters['video'] == 'true';
      withScreen = uri.queryParameters['screen'] == 'true';
    } else {
      withAudio = stored.withAudio;
      withVideo = stored.withVideo;
      withScreen = stored.withScreen;
    }

    call = _calls.addStored(
      stored,
      withAudio: withAudio,
      withVideo: withVideo,
      withScreen: withScreen,
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
            DesktopMultiWindow.mainWindowId,
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
          var newValue = StoredCall.fromJson(json.decode(e.newValue!));
          call.value.call.value = newValue.call;
          call.value.creds = call.value.creds ?? newValue.creds;
          call.value.deviceId = call.value.deviceId ?? newValue.deviceId;
          call.value.chatId.value = newValue.chatId;
          _tryToConnect();
        }
      });
    } else {
      _windowController!.setOnWindowClose(() async {
        _storageSubscription?.cancel();
        _stateWorker.dispose();
        await DesktopMultiWindow.invokeMethod(
          DesktopMultiWindow.mainWindowId,
          'call_${call.value.chatId.value.val}',
        );
        if (call.value.deviceId != null) {
          _calls.leave(call.value.chatId.value, call.value.deviceId!);
        }
      });

      DesktopMultiWindow.addMethodHandler((methodCall, _) async {
        if (methodCall.arguments == null) {
          _windowController?.close();
        }

        if (methodCall.method == 'call') {
          var newValue = StoredCall.fromJson(json.decode(methodCall.arguments));

          call.value.call.value = newValue.call;
          call.value.creds = call.value.creds ?? newValue.creds;
          call.value.deviceId = call.value.deviceId ?? newValue.deviceId;
          call.value.chatId.value = newValue.chatId;
          _tryToConnect();
        }
      });
      DesktopMultiWindow.setMethodHandlers();
    }

    _tryToConnect();
    Wakelock.enable().onError((_, __) => false);
    super.onInit();
  }

  @override
  void onClose() {
    Wakelock.disable().onError((_, __) => false);
    if (PlatformUtils.isWeb) {
      WebUtils.removeCall(call.value.chatId.value);
    } else {
      DesktopMultiWindow.invokeMethod(
        DesktopMultiWindow.mainWindowId,
        'call_${call.value.chatId.value.val}',
      );
    }
    _storageSubscription?.cancel();
    _stateWorker.dispose();
    _calls.leave(call.value.chatId.value);
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
