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

import 'package:collection/collection.dart';
import 'package:get/get.dart';
import 'package:windows_taskbar/windows_taskbar.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_info.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
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

  /// Indicates whether the [_notificationService] should display a
  /// notification.
  bool get _displayNotification =>
      _myUser.value?.muted == null &&
      (_focused || !_notificationService.pushNotifications);

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
    if (viaSubscription && c.chat.value.isGroup && _displayNotification) {
      if (c.chat.value.lastItem is ChatInfo) {
        final msg = c.chat.value.lastItem as ChatInfo;
        if (msg.action.kind == ChatInfoActionKind.memberAdded) {
          final action = msg.action as ChatInfoActionMemberAdded;
          if (msg.action.kind == ChatInfoActionKind.memberAdded &&
              action.user.id == _chatService.me &&
              DateTime.now()
                      .difference(msg.at.val)
                      .compareTo(newMessageThreshold) <=
                  -1) {
            _notificationService.show(
              c.title.value,
              body: 'fcm_user_added_you_to_group'.l10nfmt({
                'authorName': msg.author.name?.val ?? 'x',
                'authorNum': msg.author.num.val,
              }),
              payload: '${Routes.chats}/${c.chat.value.id}',
              icon: c.avatar.value?.original.url,
              tag: c.chat.value.lastItem != null
                  ? '${c.chat.value.id}_${c.chat.value.lastItem?.id}'
                  : null,
            );

            _flashTaskbarIcon();
          }
        }
      }
    }

    _chats[c.chat.value.id] ??= _ChatWatchData(
      c.chat,
      onNotification: (body, tag, image) async {
        if (_displayNotification) {
          await _notificationService.show(
            c.title.value,
            body: body,
            payload: '${Routes.chats}/${c.chat.value.id}',
            icon: c.avatar.value?.original.url,
            tag: tag,
            image: image,
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
    void Function(String, String?, String?)? onNotification,
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
            final ChatItem msg = chat.lastItem!;
            String? image;

            if (msg is ChatMessage) {
              final String? text = _message(
                isGroup: chat.isGroup,
                author: await getUser(msg.authorId),
                text: msg.text,
                attachments: msg.attachments,
              );

              image = msg.attachments
                  .whereType<ImageAttachment>()
                  .firstOrNull
                  ?.big
                  .url;

              if (text != null) {
                body.write(text);
              }
            } else if (msg is ChatForward) {
              final ChatItemQuote quote = msg.quote;
              if (quote is ChatMessageQuote) {
                final String? text = _message(
                  isGroup: chat.isGroup,
                  author: await getUser(msg.authorId),
                  text: quote.text,
                  attachments: quote.attachments,
                );

                image = quote.attachments
                    .whereType<ImageAttachment>()
                    .firstOrNull
                    ?.big
                    .url;

                if (text != null) {
                  body.write(text);
                }
              } else if (quote is ChatInfoQuote) {
                if (quote.action != null) {
                  final String? text = _info(
                    author: (await getUser(msg.authorId))?.user.value,
                    info: quote.action!,
                  );

                  if (text != null) {
                    body.write(text);
                  }
                }
              }
            } else if (msg is ChatInfo) {
              final String? text = _info(author: msg.author, info: msg.action);

              if (text != null) {
                body.write(text);
              }
            }

            if (body.isNotEmpty) {
              onNotification?.call(
                body.toString(),
                chat.lastItem != null
                    ? '${chat.id}_${chat.lastItem?.id}'
                    : null,
                image,
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
  void dispose() => worker.dispose();

  /// Returns a localized body of a [ChatMessage] notification with provided
  /// [text] and [attachments].
  String? _message({
    required bool isGroup,
    RxUser? author,
    ChatMessageText? text,
    List<Attachment> attachments = const [],
  }) {
    final String name = author?.user.value.name?.val ?? 'x';
    final String num = author?.user.value.num.val ?? 'err_unknown_user'.l10n;

    if (text != null) {
      if (isGroup) {
        return 'fcm_group_message'.l10nfmt({
          'text': text.val,
          'userName': name,
          'userNum': num,
        });
      } else {
        return 'fcm_dialog_message'.l10nfmt({'text': text.val});
      }
    } else if (attachments.isNotEmpty) {
      final String kind = attachments.first is ImageAttachment
          ? 'image'
          : (attachments.first as FileAttachment).isVideo
              ? 'video'
              : 'file';

      if (isGroup) {
        return 'fcm_group_attachment'.l10nfmt({
          'userName': name,
          'userNum': num,
          'kind': kind,
        });
      } else {
        return 'fcm_dialog_attachment'.l10nfmt({'kind': kind});
      }
    }

    return null;
  }

  /// Returns a localized body of a [ChatInfo] notification with provided
  /// [info].
  String? _info({User? author, required ChatInfoAction info}) {
    switch (info.kind) {
      case ChatInfoActionKind.created:
        // No-op, as it shouldn't be in a notification.
        return null;

      case ChatInfoActionKind.memberAdded:
        final action = info as ChatInfoActionMemberAdded;

        if (author?.id == action.user.id) {
          return 'fcm_user_joined_group_by_link'.l10nfmt(
            {
              'authorName': action.user.name?.val ?? 'x',
              'authorNum': action.user.num.val,
            },
          );
        } else {
          return 'fcm_user_added_user'.l10nfmt({
            'authorName': author?.name?.val ?? 'x',
            'authorNum': author?.num.val ?? 'err_unknown_user'.l10n,
            'userName': action.user.name?.val ?? 'x',
            'userNum': action.user.num.val,
          });
        }

      case ChatInfoActionKind.memberRemoved:
        final action = info as ChatInfoActionMemberRemoved;

        if (author?.id == action.user.id) {
          return 'fcm_user_left_group'.l10nfmt(
            {
              'authorName': action.user.name?.val ?? 'x',
              'authorNum': action.user.num.val,
            },
          );
        } else {
          return 'fcm_user_removed_user'.l10nfmt({
            'authorName': author?.name?.val ?? 'x',
            'authorNum': author?.num.val ?? 'err_unknown_user'.l10n,
            'userName': action.user.name?.val ?? 'x',
            'userNum': action.user.num.val,
          });
        }

      case ChatInfoActionKind.avatarUpdated:
        final action = info as ChatInfoActionAvatarUpdated;
        final Map<String, dynamic> args = {
          'author':
              author?.name?.val ?? author?.num.val ?? 'err_unknown_user'.l10n,
        };

        if (action.avatar == null) {
          return 'label_avatar_removed'.l10nfmt(args);
        } else {
          return 'label_avatar_updated'.l10nfmt(args);
        }

      case ChatInfoActionKind.nameUpdated:
        final action = info as ChatInfoActionNameUpdated;
        final Map<String, dynamic> args = {
          'author':
              author?.name?.val ?? author?.num.val ?? 'err_unknown_user'.l10n,
          if (action.name != null) 'name': action.name?.val,
        };

        if (action.name == null) {
          return 'label_name_removed'.l10nfmt(args);
        } else {
          return 'label_name_updated'.l10nfmt(args);
        }
    }
  }
}
