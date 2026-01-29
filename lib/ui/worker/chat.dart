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
import '/domain/service/chat.dart';
import '/domain/service/disposable_service.dart';
import '/domain/service/my_user.dart';
import '/domain/service/notification.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/user/controller.dart';
import '/util/obs/obs.dart';
import '/util/platform_utils.dart';

/// Worker responsible for showing a new [Chat] message notification.
class ChatWorker extends Dependency {
  ChatWorker(this._chatService, this._myUserService, this._notificationService);

  /// [ChatService], used to get the [Chat]s list.
  final ChatService _chatService;

  /// [MyUserService] used to getting [MyUser.muted] status.
  final MyUserService _myUserService;

  /// [NotificationService], used to show a new [Chat] message notification.
  final NotificationService _notificationService;

  /// [Duration] indicating whether the difference between [ChatItem.at] and
  /// [DateTime.now] is small enough to show a new message notification.
  static const Duration newMessageThreshold = Duration(seconds: 30);

  /// Subscription to the [ChatService.chats] map.
  StreamSubscription? _subscription;

  /// [Map] of [_ChatWatchData]s, used to react on the [Chat] changes.
  final Map<ChatId, _ChatWatchData> _chats = {};

  /// Subscription to the [PlatformUtilsImpl.onFocusChanged] updating the
  /// [_focused].
  StreamSubscription? _onFocusChanged;

  /// Subscription to the [PlatformUtilsImpl.onActivityChanged] updating the
  /// [_focused].
  StreamSubscription? _onActivityChanged;

  /// Indicator whether the application's window is in focus.
  bool _focused = true;

  /// Indicator whether the user's activity is considered active.
  bool _active = true;

  /// Indicator whether the icon in the taskbar has a flash effect applied.
  bool _flashed = false;

  /// [Duration] indicating the time after which the push notification should be
  /// considered as lost.
  static const Duration _pushTimeout = Duration(seconds: 10);

  /// Returns the currently authenticated [MyUser].
  Rx<MyUser?> get _myUser => _myUserService.myUser;

  /// Indicates whether the [_notificationService] should display a
  /// notification.
  bool get _displayNotification =>
      _focused || !_notificationService.pushNotifications;

  /// Indicates whether the currently authenticated [MyUser] has any
  /// [MuteDuration] specified.
  bool get _isMuted => _myUser.value?.muted != null;

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
      if (_focused) {
        _flashed = false;
      }
    });

    PlatformUtils.isActive.then((value) => _active = value);
    _onActivityChanged = PlatformUtils.onActivityChanged.listen((v) {
      _active = v;
    });

    super.onReady();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _onFocusChanged?.cancel();
    _onActivityChanged?.cancel();
    _chats.forEach((_, value) => value.dispose());
    super.onClose();
  }

  /// Reacts to the provided [Chat] being added and populates the [Worker] to
  /// react on its [Chat.lastItem] changes to show a notification.
  void _onChatAdded(RxChat c, [bool viaSubscription = false]) {
    // Display a new group chat notification.
    if (viaSubscription && c.chat.value.isGroup && !_isMuted) {
      bool newChat = false;

      if (c.chat.value.lastItem is ChatInfo) {
        final msg = c.chat.value.lastItem as ChatInfo;
        if (msg.action.kind == ChatInfoActionKind.memberAdded) {
          final action = msg.action as ChatInfoActionMemberAdded;
          newChat =
              msg.action.kind == ChatInfoActionKind.memberAdded &&
              action.user.id == _chatService.me &&
              DateTime.now()
                      .difference(msg.at.val)
                      .compareTo(newMessageThreshold) <=
                  -1;
        }
      } else if (c.chat.value.lastItem == null) {
        // The chat was created just now.
        newChat =
            DateTime.now()
                .difference(c.chat.value.updatedAt.val)
                .compareTo(newMessageThreshold) <=
            -1;
      }

      if (newChat) {
        // Displays a local notification via [NotificationService].
        Future<void> notify() async {
          if (!_isMuted && c.chat.value.muted == null) {
            await _notificationService.show(
              c.title(),
              body: 'label_you_were_added_to_group'.l10n,
              payload: '${Routes.chats}/${c.chat.value.id}',
              icon: c.avatar.value?.original,
              thread: '${c.chat.value.id}',
              tag: '${c.chat.value.id}',
            );

            await _flashTaskbarIcon();
          }
        }

        if (_displayNotification) {
          notify();
        } else if (PlatformUtils.isWeb && PlatformUtils.isDesktop) {
          // [NotificationService] will not show the scheduled local
          // notification, if a push with the same tag was already received.
          Future.delayed(_pushTimeout, notify);
        }
      }
    }

    _chats[c.chat.value.id] ??= _ChatWatchData(
      c.chat,
      onActive: () => _active,
      onNotification: (body, tag, thread, image) async {
        // Displays a local notification via [NotificationService].
        Future<void> notify() async {
          if (PlatformUtils.isMobile &&
              !router.lifecycle.value.inForeground &&
              _notificationService.pushNotifications) {
            // Don't display the local notifications when app is in background
            // on mobiles with push notifications enabled, as in this case a
            // push should be displayed.
            //
            // Otherwise the local notification might duplicate the remote one.
            return;
          }

          if (!_isMuted && c.chat.value.muted == null) {
            await _notificationService.show(
              c.title(),
              body: body,
              payload: '${Routes.chats}/${c.chat.value.id}',
              icon: c.avatar.value?.original,
              tag: tag,
              thread: thread,
              image: image,
            );

            await _flashTaskbarIcon();
          }
        }

        if (_displayNotification) {
          notify();
        } else if (PlatformUtils.isWeb && PlatformUtils.isDesktop) {
          // [NotificationService] will not show the scheduled local
          // notification, if a push with the same tag was already received.
          Future.delayed(_pushTimeout, notify);
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
    void Function(String, String?, String?, String?)? onNotification,
    bool Function()? onActive,
    UserId? Function()? me,
  }) : updatedAt = c.value.lastItem?.at ?? PreciseDateTime.now() {
    void showNotification(Chat chat) {
      if (chat.lastItem != null) {
        final UserId? meId = me?.call();

        final bool isAfter = chat.lastItem!.at.isAfter(updatedAt);
        final bool isRelativelyNew =
            DateTime.now()
                .difference(chat.lastItem!.at.val)
                .compareTo(ChatWorker.newMessageThreshold) <=
            -1;
        final bool notFromMe = chat.lastItem!.author.id != meId;
        final bool notMuted = chat.muted == null;
        bool notInChat = true;

        if (onActive != null && meId != null) {
          final bool inChat = c.value.isRoute(router.route, meId);
          notInChat = !inChat || onActive() == false;
        }

        if (isAfter && isRelativelyNew && notFromMe && notMuted && notInChat) {
          final StringBuffer body = StringBuffer();
          final ChatItem msg = chat.lastItem!;
          String? image;

          if (msg is ChatMessage) {
            final String? text = _message(
              isGroup: chat.isGroup,
              author: msg.author,
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
                author: msg.author,
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
                  author: msg.author,
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
              chat.lastItem != null ? '${chat.id}-${chat.lastItem?.id}' : null,
              '${chat.id}',
              image,
            );
          }
        }

        updatedAt = chat.lastItem!.at;
      }
    }

    showNotification(c.value);

    worker = ever(c, showNotification);
  }

  /// [Worker] to react on the [Chat] updates.
  late final Worker worker;

  /// [PreciseDateTime] the [Chat.lastItem] was updated at.
  PreciseDateTime updatedAt;

  /// Callback, called to get the [UserId] of the currently authenticated
  /// [MyUser].
  UserId? Function()? me;

  /// Disposes the [worker].
  void dispose() => worker.dispose();

  /// Returns a localized body of a [ChatMessage] notification with provided
  /// [text] and [attachments].
  String? _message({
    required bool isGroup,
    User? author,
    ChatMessageText? text,
    List<Attachment> attachments = const [],
  }) {
    final String name = author?.title() ?? 'x';
    final String num = author?.num.toString() ?? ('dot'.l10n * 3);
    final String type = isGroup ? 'group' : 'dialog';
    String attachmentsType = attachments.every((e) => e is ImageAttachment)
        ? 'image'
        : attachments.every((e) => e is FileAttachment && e.isVideo)
        ? 'video'
        : attachments.every((e) => e is FileAttachment && !e.isVideo)
        ? 'file'
        : 'attachments';

    return 'fcm_message'.l10nfmt({
      'type': type,
      'text': text?.val ?? '',
      'textLength': text?.val.length ?? 0,
      'userName': name,
      'userNum': num,
      'attachmentsCount': attachments.length,
      'attachmentsType': attachmentsType,
      'donation': 'x',
    });
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
          return 'fcm_user_joined_group_by_link'.l10nfmt({
            'authorName': action.user.title(),
            'authorNum': action.user.num.toString(),
          });
        } else if (action.user.id == me?.call()) {
          return 'fcm_user_added_you_to_group'.l10nfmt({
            'authorName': author?.title() ?? 'x',
            'authorNum': author?.num.toString() ?? ('dot'.l10n * 3),
          });
        } else {
          return 'fcm_user_added_user'.l10nfmt({
            'authorName': author?.title() ?? 'x',
            'authorNum': author?.num.toString() ?? ('dot'.l10n * 3),
            'userName': action.user.title(),
            'userNum': action.user.num.toString(),
          });
        }

      case ChatInfoActionKind.memberRemoved:
        final action = info as ChatInfoActionMemberRemoved;

        if (author?.id == action.user.id) {
          return 'fcm_user_left_group'.l10nfmt({
            'authorName': action.user.title(),
            'authorNum': action.user.num.toString(),
          });
        } else if (action.user.id == me?.call()) {
          return 'fcm_user_removed_you'.l10nfmt({
            'authorName': author?.title() ?? 'x',
            'authorNum': author?.num.toString() ?? ('dot'.l10n * 3),
          });
        } else {
          return 'fcm_user_removed_user'.l10nfmt({
            'authorName': author?.title() ?? 'x',
            'authorNum': author?.num.toString() ?? ('dot'.l10n * 3),
            'userName': action.user.title(),
            'userNum': action.user.num.toString(),
          });
        }

      case ChatInfoActionKind.avatarUpdated:
        final action = info as ChatInfoActionAvatarUpdated;

        return 'fcm_group_avatar_changed'.l10nfmt({
          'userName': author?.title() ?? 'x',
          'userNum': author?.num.toString() ?? ('dot'.l10n * 3),
          'operation': action.avatar == null ? 'remove' : 'update',
        });

      case ChatInfoActionKind.nameUpdated:
        final action = info as ChatInfoActionNameUpdated;

        return 'fcm_group_name_changed'.l10nfmt({
          'userName': author?.title() ?? 'x',
          'userNum': author?.num.toString() ?? ('dot'.l10n * 3),
          'operation': action.name == null ? 'remove' : 'update',
          'groupName': action.name?.val ?? '',
        });
    }
  }
}
