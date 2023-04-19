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

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/my_user.dart';
import '/domain/model/precise_date_time/precise_date_time.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

/// Worker responsible for showing a new [Chat] message notification.
class ChatWorker extends DisposableService {
  ChatWorker(
    this._chatService,
    this._userService,
    this._myUserService,
    this._notificationService,
  );

  /// [ChatService], used to get the [Chat]s list.
  final ChatService _chatService;

  /// [User]s service fetching the [User]s.
  final UserService _userService;

  /// [MyUserService] used to getting [MyUser.muted] status.
  final MyUserService _myUserService;

  /// [NotificationService], used to show a new [Chat] message notification.
  final NotificationService _notificationService;

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

    PlatformUtils.isFocused.then((value) => _focused = value);

    _onFocusChanged = PlatformUtils.onFocusChanged.listen((focused) async {
      _focused = focused;
      if (_focused && PlatformUtils.isWindows && !PlatformUtils.isWeb) {
        _flashed = false;
      }
    });

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
    if (viaSubscription &&
        c.chat.value.isGroup &&
        _myUser.value?.muted == null) {
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

          if (newChat) {
            if (_focused) {
              _notificationService.show(
                c.title.value,
                body: 'fcm_user_added_you_to_group'.l10nfmt({
                  'authorName': msg.author.name?.val ?? 'x',
                  'authorNum': msg.author.num.val,
                }),
                payload: '${Routes.chats}/${c.chat.value.id}',
                icon: c.avatar.value?.original.url,
                tag: '${c.chat.value.id.val}_${c.chat.value.lastItem?.id}',
              );
            }

            _flashTaskbarIcon();
          }
        }
      }
    }

    _chats[c.chat.value.id] ??= _ChatWatchData(
      c.chat,
      onNotification: (body, tag) async {
        if (_myUser.value?.muted == null && _focused) {
          await _notificationService.show(
            c.title.value,
            body: body,
            payload: '${Routes.chats}/${c.chat.value.id}',
            icon: c.avatar.value?.original.url,
            tag: tag,
          );

          await _flashTaskbarIcon();
        }
      },
      me: () => _chatService.me,
      getUser: (id) => _userService.get(id),
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
    void Function(String, String?)? onNotification,
    UserId? Function()? me,
    required Future<RxUser?> Function(UserId) getUser,
  }) : updatedAt = PreciseDateTime.now() {
    worker = ever(
      c,
      (Chat chat) async {
        if (chat.lastItem != null) {
          if (chat.lastItem!.at.isAfter(updatedAt) &&
              DateTime.now()
                      .difference(chat.lastItem!.at.val)
                      .compareTo(ChatWorker.newMessageThreshold) <=
                  -1 &&
              chat.lastItem!.authorId != me?.call() &&
              chat.muted == null) {
            final StringBuffer body = StringBuffer();
            final ChatItem lastItem = chat.lastItem!;

            if (lastItem is ChatMessage ||
                (lastItem is ChatForward &&
                    lastItem.quote.original is ChatMessage)) {
              final msg = lastItem is ChatMessage
                  ? lastItem
                  : (lastItem as ChatForward).quote.original as ChatMessage;
              final RxUser? author = await getUser(msg.authorId);

              if (author != null) {
                final String userName = author.user.value.name?.val ?? 'x';
                final String userNum = author.user.value.num.val;

                if (msg.text != null) {
                  if (chat.isGroup) {
                    body.write(
                      'fcm_group_message'.l10nfmt({
                        'text': msg.text!.val,
                        'userName': userName,
                        'userNum': userNum,
                      }),
                    );
                  } else {
                    body.write(
                      'fcm_dialog_message'.l10nfmt({'text': msg.text!.val}),
                    );
                  }
                } else if (msg.attachments.isNotEmpty) {
                  final String kind = msg.attachments.first is ImageAttachment
                      ? 'image'
                      : (msg.attachments.first as FileAttachment).isVideo
                          ? 'video'
                          : 'file';

                  if (chat.isGroup) {
                    body.write(
                      'fcm_group_attachment'.l10nfmt({
                        'userName': userName,
                        'userNum': userNum,
                        'kind': kind,
                      }),
                    );
                  } else {
                    body.write(
                      'fcm_dialog_attachment'.l10nfmt({'kind': kind}),
                    );
                  }
                }
              }
            } else if (chat.lastItem is ChatInfo) {
              final ChatInfo msg = chat.lastItem as ChatInfo;

              switch (msg.action.kind) {
                case ChatInfoActionKind.created:
                  // No-op, as it shouldn't be in a notification.
                  break;

                case ChatInfoActionKind.memberAdded:
                  final action = msg.action as ChatInfoActionMemberAdded;

                  if (msg.authorId == action.user.id) {
                    body.write(
                      'fcm_user_joined_group_by_link'.l10nfmt(
                        {
                          'authorName': action.user.name?.val ?? 'x',
                          'authorNum': action.user.num.val,
                        },
                      ),
                    );
                  } else {
                    body.write(
                      'fcm_user_added_user'.l10nfmt({
                        'authorName': msg.author.name?.val ?? 'x',
                        'authorNum': msg.author.num.val,
                        'userName': action.user.name?.val ?? 'x',
                        'userNum': action.user.num.val,
                      }),
                    );
                  }
                  break;

                case ChatInfoActionKind.memberRemoved:
                  final action = msg.action as ChatInfoActionMemberRemoved;

                  if (msg.authorId == action.user.id) {
                    body.write(
                      'fcm_user_left_group'.l10nfmt(
                        {
                          'authorName': action.user.name?.val ?? 'x',
                          'authorNum': action.user.num.val,
                        },
                      ),
                    );
                  } else {
                    body.write(
                      'fcm_user_removed_user'.l10nfmt({
                        'authorName': msg.author.name?.val ?? 'x',
                        'authorNum': msg.author.num.val,
                        'userName': action.user.name?.val ?? 'x',
                        'userNum': action.user.num.val,
                      }),
                    );
                  }
                  break;

                case ChatInfoActionKind.avatarUpdated:
                  final action = msg.action as ChatInfoActionAvatarUpdated;
                  final Map<String, dynamic> args = {
                    'author': msg.author.name?.val ?? msg.author.num.val,
                  };

                  if (action.avatar == null) {
                    body.write('label_avatar_removed'.l10nfmt(args));
                  } else {
                    body.write('label_avatar_updated'.l10nfmt(args));
                  }
                  break;

                case ChatInfoActionKind.nameUpdated:
                  final action = msg.action as ChatInfoActionNameUpdated;
                  final Map<String, dynamic> args = {
                    'author': msg.author.name?.val ?? msg.author.num.val,
                    if (action.name != null) 'name': action.name?.val,
                  };

                  if (action.name == null) {
                    body.write('label_name_removed'.l10nfmt(args));
                  } else {
                    body.write('label_name_updated'.l10nfmt(args));
                  }
                  break;
              }
            }

            if (body.isNotEmpty) {
              onNotification?.call(
                body.toString(),
                '${chat.id.val}_${chat.lastItem?.id.val}',
              );
            }
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
