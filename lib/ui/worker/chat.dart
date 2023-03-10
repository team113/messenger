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

import 'package:get/get.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/routes.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

/// Worker responsible for showing a new [Chat] message notification.
class ChatWorker extends DisposableService {
  ChatWorker(
    this._chatService,
    this._myUserService,
  );

  /// [ChatService], used to get the [Chat]s list.
  final ChatService _chatService;

  /// [MyUserService] used to getting [MyUser.muted] status.
  final MyUserService _myUserService;

  /// [Duration] indicating whether the difference between [ChatItem.at] and
  /// [DateTime.now] is small enough to show a new message notification.
  static const Duration newMessageThreshold = Duration(seconds: 30);

  /// Subscription to the [ChatService.chats] map.
  late final StreamSubscription _subscription;

  /// [Map] of [_ChatWatchData]s, used to react on the [Chat] changes.
  final Map<ChatId, _ChatWatchData> _chats = {};

  /// Subscription to the [PlatformUtils.onFocusChanged] updating the
  /// [_focused].
  StreamSubscription? _onFocusChanged;

  /// Indicator whether the application's window is in focus.
  bool _focused = true;

  /// Indicator whether the icon in the taskbar has a flash effect applied.
  bool _flashed = false;

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get _myUser => _myUserService.myUser;

  @override
  void onReady() {
    _chatService.chats.forEach((_, value) => _onChatAdded(value));
    _subscription = _chatService.chats.changes.listen((event) {
      switch (event.op) {
        case OperationKind.added:
          _onChatAdded(event.value!, true);
          break;

        case OperationKind.removed:
          _chats.remove(event.key)?.dispose();
          break;

        default:
          break;
      }
    });

    if (PlatformUtils.isWindows && !PlatformUtils.isWeb) {
      PlatformUtils.isFocused.then((value) => _focused = value);

      _onFocusChanged = PlatformUtils.onFocusChanged.listen((_) async {
        _focused = await PlatformUtils.isFocused;
        if (_focused) {
          _flashed = false;
        }
      });
    }

    super.onReady();
  }

  @override
  void onClose() {
    _subscription.cancel();
    _onFocusChanged?.cancel();
    _chats.forEach((_, value) => value.dispose());
    super.onClose();
  }

  /// Reacts to the provided [Chat] being added and populates the [Worker] to
  /// react on its [Chat.lastItem] changes to show a notification.
  void _onChatAdded(RxChat c, [bool viaSubscription = false]) {
    // Display a new group chat notification.
    if (viaSubscription && c.chat.value.isGroup) {
      bool newChat = false;

      if (c.chat.value.lastItem is ChatInfo) {
        final msg = c.chat.value.lastItem as ChatInfo;
        if (msg.action.kind == ChatInfoActionKind.memberAdded) {
          final action = msg.action as ChatInfoActionMemberAdded;
          newChat = msg.action.kind == ChatInfoActionKind.memberAdded &&
              action.user.id == _chatService.me &&
              DateTime.now()
                      .difference(msg.at.val)
                      .compareTo(newMessageThreshold) <=
                  -1;
        }
      } else if (c.chat.value.lastItem == null) {
        // The chat was created just now.
        newChat = DateTime.now()
                .difference(c.chat.value.updatedAt.val)
                .compareTo(newMessageThreshold) <=
            -1;
      }

      if (newChat) {
        if (_myUser.value?.muted == null) {
          _flashTaskbarIcon();
        }
      }
    }

    _chats[c.chat.value.id] ??= _ChatWatchData(
      c.chat,
      onNotification: () async {
        if (_myUser.value?.muted == null) {
          await _flashTaskbarIcon();
        }
      },
      me: () => _chatService.me,
    );
  }

  /// Applies the flashing effect to the application's icon in the taskbar.
  Future<void> _flashTaskbarIcon() async {
    if (PlatformUtils.isWindows &&
        !PlatformUtils.isWeb &&
        !_focused &&
        !_flashed) {
      try {
        await WindowsTaskbar.setFlashTaskbarAppIcon(
          mode: TaskbarFlashMode.tray | TaskbarFlashMode.timer,
          flashCount: 1,
        );

        _flashed = true;
      } catch (_) {
        // No-op.
      }
    }
  }
}

/// Container of data, used to show a notification on the [Chat.lastItem]
/// updates.
class _ChatWatchData {
  _ChatWatchData(
    Rx<Chat> c, {
    void Function()? onNotification,
    UserId? Function()? me,
  }) : updatedAt = PreciseDateTime.now() {
    worker = ever(
      c,
      (Chat chat) {
        if (chat.lastItem != null) {
          if (router.lifecycle.value.inForeground &&
              chat.lastItem!.at.isAfter(updatedAt) &&
              DateTime.now()
                      .difference(chat.lastItem!.at.val)
                      .compareTo(ChatWorker.newMessageThreshold) <=
                  -1 &&
              chat.lastItem!.authorId != me?.call() &&
              chat.muted == null) {
            onNotification?.call();
          }

          updatedAt = chat.lastItem!.at;
        }
      },
    );
  }

  /// [Worker] to react on the [Chat] updates.
  late final Worker worker;

  /// [PreciseDateTime] the [Chat.lastItem] was updated at.
  PreciseDateTime updatedAt;

  /// Disposes the [worker].
  void dispose() {
    worker.dispose();
  }
}
