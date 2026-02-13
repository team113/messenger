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

import 'package:collection/collection.dart';
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

  /// Reactive ordered list of [OngoingCall]s.
  final RxList<OverlayCall> calls = RxList<OverlayCall>([]);

  /// Call service used to expose the [calls].
  final CallService _callService;

  /// [ChatService] used to [ChatService.get] chats.
  final ChatService _chatService;

  /// [MyUserService] used to retrieve [MyUser]'s muted status.
  final MyUserService _myUserService;

  /// Settings repository, used to get the stored [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

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
          if (event.key == null || event.value == null) {
            Log.error(
              '_callService.calls.changes -> ${event.op} -> Unreachable situation with `null`s: `${event.key}` or ${event.value}',
              '$runtimeType',
            );
            return;
          }

          await _handleAddedCall(event.key!, event.value!);
          break;

        case OperationKind.removed:
          if (event.key == null) {
            Log.error(
              '_callService.calls.changes -> ${event.op} -> Unreachable situation with `null` at: `${event.key}`',
              '$runtimeType',
            );
            return;
          }

          _handleCallRemoved(event.key!, event.value);
          break;

        case OperationKind.updated:
          // No-op.
          break;
      }
    });

    // Account the calls that are already present in the service.
    for (var e in _callService.calls.entries) {
      _handleAddedCall(e.key, e.value);
    }

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

  /// Accounts a call happening in [key] chat and either displays it in the
  /// [calls] or creates a [WebUtils.openPopupCall] popup, if available.
  Future<void> _handleAddedCall(ChatId key, Rx<OngoingCall> reactive) async {
    Log.debug('_handleAddedCall($key, ${reactive.value})', '$runtimeType');

    final OngoingCall value = reactive.value;

    if (WebUtils.containsCall(key)) {
      // Call's popup is already displayed, perhaps by another tab, so
      // don't react to this call at all.
      return;
    }

    // Unfocus any inputs being active.
    FocusManager.instance.primaryFocus?.unfocus();

    bool window = false;

    // Check whether the call notification should be displayed at all,
    // which should only be applied to pending calls only.
    switch (value.state.value) {
      case OngoingCallState.pending:
        // If global `MyUser` mute is applied, then ignore the call.
        final MuteDuration? meMuted = _myUserService.myUser.value?.muted;
        if (meMuted != null) {
          Log.debug(
            '_handleAddedCall($key) -> ignoring due to `meMuted` being: $meMuted',
            '$runtimeType',
          );

          // Remove the call after a tick due to this event already being a
          // change in the list of calls.
          return Future.delayed(
            Duration.zero,
            () => _callService.remove(value.chatId.value),
          );
        }

        bool redialed = false;

        final ChatMembersDialed? dialed = value.call.value?.dialed;
        if (dialed is ChatMembersDialedConcrete) {
          redialed = dialed.members.any((e) => e.user.id == _chatService.me);
        }

        final bool alreadyJoined =
            value.call.value?.members.none(
              (e) => e.user.id == _chatService.me,
            ) ==
            false;

        // If this call is already joined by our user, then ignore it.
        if (alreadyJoined) {
          Log.debug(
            '_handleAddedCall($key) -> ignoring due to `alreadyJoined`: ${value.call.value?.members.map((e) => '${e.user.id} (${e.user.name ?? e.user.num})').join(', ')} already contains me(${_chatService.me})',
            '$runtimeType',
          );

          // Remove the call after a tick due to this event already being a
          // change in the list of calls.
          return Future.delayed(
            Duration.zero,
            () => _callService.remove(value.chatId.value),
          );
        }

        // If redialed, then show the notification anyway.
        if (!redialed) {
          try {
            // If this exact `Chat` is muted, then ignore the call.
            final RxChat? chat = await _chatService.get(value.chatId.value);
            final MuteDuration? chatMuted = chat?.chat.value.muted;
            if (chatMuted != null) {
              // Remove the call after a tick due to this event already being a
              // change in the list of calls.
              return Future.delayed(
                Duration.zero,
                () => _callService.remove(value.chatId.value),
              );
            }
          } catch (_) {
            // No-op, as it's ok to fail.
          }
        } else {
          Log.debug(
            '_handleAddedCall($key) -> ignoring due to `redialed`: ${value.call.value?.dialed})',
            '$runtimeType',
          );
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
        key,
        withAudio:
            value.audioState.value == LocalTrackState.enabling ||
            value.audioState.value == LocalTrackState.enabled,
        withVideo:
            value.videoState.value == LocalTrackState.enabling ||
            value.videoState.value == LocalTrackState.enabled,
        withScreen:
            value.screenShareState.value == LocalTrackState.enabling ||
            value.screenShareState.value == LocalTrackState.enabled,
      );

      // If [window] is `true`, then a new popup window is created, so
      // treat this call as a popup windowed call.
      if (window) {
        WebUtils.setCall(value.toStored());
        if (value.callChatItemId == null || value.deviceId == null) {
          _workers[key] = ever(value.call, (ChatCall? call) {
            WebUtils.setCall(
              WebStoredCall(
                chatId: value.chatId.value,
                call: call,
                creds: value.creds,
                deviceId: value.deviceId,
                state: value.state.value,
              ),
            );

            if (call?.id != null) {
              _workers[key]?.dispose();
            }
          });
        }
      } else {
        Future.delayed(Duration.zero, () {
          value.addError('err_call_popup_was_blocked'.l10n);
        });
      }
    }

    if (!window) {
      // Otherwise the popup creation request failed or wasn't invoked, so
      // add this call to the [calls] to display it in the view.
      calls.add(OverlayCall(reactive));
      value.init(getChat: _chatService.get);
    }
  }

  /// Removes an [OngoingCall] from the provided [key] chat.
  void _handleCallRemoved(ChatId key, Rx<OngoingCall>? value) {
    Log.debug('_handleCallRemoved($key, ${reactive.value})', '$runtimeType');

    calls.removeWhere((e) => e.call.value.chatId.value == key);

    final OngoingCall? call = value?.value;
    if (call != null) {
      if (call.callChatItemId == null || call.connected) {
        WebUtils.removeCall(key);
      }
    }

    final WebStoredCall? web = WebUtils.getCall(key);
    if (web?.state == OngoingCallState.pending) {
      WebUtils.removeCall(key);
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
