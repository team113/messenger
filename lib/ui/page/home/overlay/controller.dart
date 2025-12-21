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

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/application_settings.dart';
import '/domain/model/chat_call.dart';
import '/domain/model/chat.dart';
import '/domain/model/mute_duration.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/settings.dart';
import '/domain/service/call.dart';
import '/domain/service/chat.dart';
import '/domain/service/my_user.dart';
import '/l10n/l10n.dart';
import '/util/log.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of an [OngoingCall]s overlay.
class CallOverlayController extends GetxController {
  CallOverlayController(
    this._callService,
    this._chatService,
    this._myUserService,
    this._settingsRepo,
  );

  /// Call service used to expose the [calls].
  final CallService _callService;

  /// [ChatService] used to [ChatService.get] chats.
  final ChatService _chatService;

  /// [MyUserService] used to retrieve [MyUser]'s muted status.
  final MyUserService _myUserService;

  /// Settings repository, used to get the stored [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// Reactive ordered list of [OngoingCall]s.
  final RxList<OverlayCall> calls = RxList<OverlayCall>([]);

  /// Subscription to [CallService.calls] map.
  late final StreamSubscription _subscription;

  /// [Worker]s reacting on [OngoingCall.call] changes, used to put the calls to
  /// the browser's storage.
  final Map<ChatId, Worker> _workers = {};

  /// Returns the stored [ApplicationSettings].
  Rx<ApplicationSettings?> get _settings => _settingsRepo.applicationSettings;

  @override
  void onInit() {
    _subscription = _callService.calls.changes.listen((event) async {
      Log.debug(
        '_callService.calls.changes -> ${event.op}: key(${event.key}), value(${event.value?.value})',
        '$runtimeType',
      );

      switch (event.op) {
        case OperationKind.added:
          if (WebUtils.containsCall(event.key!)) {
            // Call's popup is already displayed, perhaps by another tab, so
            // don't react to this call at all.
            return;
          }

          // Unfocus any inputs being active.
          FocusManager.instance.primaryFocus?.unfocus();

          bool window = false;

          final OngoingCall ongoingCall = event.value!.value;

          // Check whether the call notification should be displayed at all,
          // which should only be applied to pending calls only.
          switch (ongoingCall.state.value) {
            case OngoingCallState.pending:
              // If global `MyUser` mute is applied, then ignore the call.
              final MuteDuration? meMuted = _myUserService.myUser.value?.muted;
              if (meMuted != null) {
                return _callService.remove(ongoingCall.chatId.value);
              }

              bool redialed = false;

              final ChatMembersDialed? dialed = ongoingCall.call.value?.dialed;
              if (dialed is ChatMembersDialedConcrete) {
                redialed = dialed.members.any(
                  (e) => e.user.id == _chatService.me,
                );
              }

              // If redialed, then show the notification anyway.
              if (!redialed) {
                try {
                  // If this exact `Chat` is muted, then ignore the call.
                  final RxChat? chat = await _chatService.get(
                    ongoingCall.chatId.value,
                  );
                  final MuteDuration? chatMuted = chat?.chat.value.muted;
                  if (chatMuted != null) {
                    return _callService.remove(ongoingCall.chatId.value);
                  }
                } catch (_) {
                  // No-op, as it's ok to fail.
                }
              }
              break;

            case OngoingCallState.local:
            case OngoingCallState.joining:
            case OngoingCallState.active:
            case OngoingCallState.ended:
              // No-op.
              break;
          }

          if (PlatformUtils.isWeb &&
              !PlatformUtils.isMobile &&
              _settings.value?.enablePopups != false) {
            window = WebUtils.openPopupCall(
              event.key!,
              withAudio:
                  ongoingCall.audioState.value == LocalTrackState.enabling ||
                  ongoingCall.audioState.value == LocalTrackState.enabled,
              withVideo:
                  ongoingCall.videoState.value == LocalTrackState.enabling ||
                  ongoingCall.videoState.value == LocalTrackState.enabled,
              withScreen:
                  ongoingCall.screenShareState.value ==
                      LocalTrackState.enabling ||
                  ongoingCall.screenShareState.value == LocalTrackState.enabled,
            );

            // If [window] is `true`, then a new popup window is created, so
            // treat this call as a popup windowed call.
            if (window) {
              WebUtils.setCall(ongoingCall.toStored());
              if (ongoingCall.callChatItemId == null ||
                  ongoingCall.deviceId == null) {
                _workers[event.key!] = ever(event.value!.value.call, (
                  ChatCall? call,
                ) {
                  WebUtils.setCall(
                    WebStoredCall(
                      chatId: ongoingCall.chatId.value,
                      call: call,
                      creds: ongoingCall.creds,
                      deviceId: ongoingCall.deviceId,
                      state: ongoingCall.state.value,
                    ),
                  );

                  if (call?.id != null) {
                    _workers[event.key!]?.dispose();
                  }
                });
              }
            } else {
              Future.delayed(Duration.zero, () {
                ongoingCall.addError('err_call_popup_was_blocked'.l10n);
              });
            }
          }

          if (!window) {
            // Otherwise the popup creation request failed or wasn't invoked, so
            // add this call to the [calls] to display it in the view.
            calls.add(OverlayCall(event.value!));
            event.value?.value.init(getChat: _chatService.get);
          }
          break;

        case OperationKind.removed:
          calls.removeWhere((e) => e.call.value.chatId.value == event.key);

          final OngoingCall call = event.value!.value;
          final WebStoredCall? web = WebUtils.getCall(event.key!);
          if (call.callChatItemId == null ||
              call.connected ||
              web?.state == OngoingCallState.pending) {
            WebUtils.removeCall(event.key!);
          }
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    _subscription.cancel();
    _workers.forEach((_, e) => e.dispose());
    super.onClose();
  }

  /// Moves the given [call] to the end of the [calls].
  void orderFirst(OverlayCall call) {
    var index = calls.indexOf(call);
    if (index != calls.length - 1) {
      calls.removeAt(index);
      calls.add(call);
    }
  }
}

/// Reactive [OngoingCall] with a [GlobalKey] associated with it.
class OverlayCall {
  OverlayCall(this.call);

  /// [GlobalKey] identifying the [call].
  final GlobalKey key = GlobalKey();

  /// Indicator whether the [call] should be minimized or not.
  final RxBool minimized = RxBool(true);

  /// Reactive [OngoingCall] itself.
  final Rx<OngoingCall> call;
}
