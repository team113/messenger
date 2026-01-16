// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:super_drag_and_drop/super_drag_and_drop.dart';

import '/api/backend/schema.dart' show ForwardChatItemsErrorCode;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote_input.dart';
import '/domain/model/user.dart';
import '/domain/repository/settings.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/util/data_reader.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of a [ChatForwardView].
class ChatForwardController extends GetxController {
  ChatForwardController(
    this._chatService,
    this._userService,
    this._settingsRepository, {
    this.text,
    this.pop,
    this.attachments = const [],
    this.onSent,
    required this.from,
    required this.quotes,
  });

  /// Selected items in [SearchView] popup.
  final Rx<SearchViewResults?> selected = Rx(null);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// Initial [String] to put in the [MessageFieldController.field].
  final String? text;

  /// [ChatItemQuoteInput]s to be forwarded.
  final List<ChatItemQuoteInput> quotes;

  /// Callback, called when a [ChatForwardView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function([bool])? pop;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// [Attachment]s to attach to the [quotes].
  final List<Attachment> attachments;

  /// Callback, called when the [quotes] are sent.
  final void Function()? onSent;

  /// [Chat]s service forwarding the [quotes].
  final ChatService _chatService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// [AbstractSettingsRepository], used to create a [MessageFieldController].
  final AbstractSettingsRepository _settingsRepository;

  /// [MessageFieldController] controller sending the [ChatMessage].
  late final MessageFieldController send;

  /// Subscription to the [selected] stream changing
  /// [ReactiveFieldState.submittable] depending on the [SearchViewResults].
  StreamSubscription<SearchViewResults?>? _selectedSubscription;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    send = MessageFieldController(
      _chatService,
      _userService,
      _settingsRepository,
      null,
      null,
      null,
      null,
      text: text,
      attachments: attachments,
      canPin: false,
      onSubmit: _send,
    );

    send.field.submittable.value = false;

    _selectedSubscription = selected.listen((e) {
      send.field.submittable.value = e != null && !e.isEmpty;
    });

    super.onInit();
  }

  @override
  void onClose() {
    _selectedSubscription?.cancel();
    send.onClose();
    scrollController.dispose();
    super.onClose();
  }

  /// Returns a [User] from [UserService] by the provided [id].
  FutureOr<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Adds the specified [event] files to the [attachments].
  Future<void> dropFiles(PerformDropEvent event) async {
    for (final DropItem item in event.session.items) {
      final PlatformFile? file = await item.dataReader?.asPlatformFile();
      if (file != null) {
        send.addPlatformAttachment(file);
      }
    }
  }

  /// Forms and sends the forwarded message.
  Future<void> _send() async {
    if (selected.value?.isEmpty != false) {
      send.field.unsubmit();
      return;
    }

    send.field.status.value = RxStatus.loading();
    send.field.editable.value = false;

    try {
      final List<Future> uploads = send.attachments
          .map((e) => e.value)
          .whereType<LocalAttachment>()
          .map((e) => e.upload.value?.future)
          .nonNulls
          .toList();
      if (uploads.isNotEmpty) {
        await Future.wait(uploads);
      }

      if (send.attachments.whereType<LocalAttachment>().isNotEmpty) {
        throw const ConnectionException(
          ForwardChatItemsException(
            ForwardChatItemsErrorCode.unknownAttachment,
          ),
        );
      }

      final List<AttachmentId>? attachments = send.attachments.isEmpty
          ? null
          : send.attachments.map((a) => a.value.id).toList();

      final ChatMessageText? text = send.field.text.isEmpty
          ? null
          : ChatMessageText(send.field.text);

      final List<ChatItemQuoteInput> quotes = this.quotes.reversed.toList();

      // Displays a [MessagePopup.error] visually representing a blocked by
      // the provided [user] error.
      Future<void> showBlockedPopup(User? user) async {
        if (user == null) {
          await MessagePopup.error('err_blocked'.l10n);
        } else {
          await MessagePopup.error(
            'err_blocked_by'.l10nfmt({'user': '${user.name ?? user.num}'}),
          );
        }
      }

      final List<Future<void>> futures = [
        ...selected.value!.chats.map((e) {
          return _chatService
              .forwardChatItems(
                from,
                e.chat.value.id,
                quotes,
                text: text,
                attachments: attachments,
              )
              .onError<ForwardChatItemsException>((_, _) async {
                await showBlockedPopup(
                  e.members.values
                      .firstWhereOrNull((u) => u.user.id != me)
                      ?.user
                      .user
                      .value,
                );
              }, test: (e) => e.code == ForwardChatItemsErrorCode.blocked);
        }),
        ...selected.value!.users.map((u) {
          final User user = u.user.value;
          final ChatId dialog = user.dialog;

          return _chatService
              .forwardChatItems(
                from,
                dialog,
                quotes,
                text: text,
                attachments: attachments,
              )
              .onError<ForwardChatItemsException>(
                (_, _) => showBlockedPopup(user),
                test: (e) => e.code == ForwardChatItemsErrorCode.blocked,
              );
        }),
        ...selected.value!.contacts.map((c) {
          final User user = c.user.value!.user.value;
          final ChatId dialog = user.dialog;

          return _chatService
              .forwardChatItems(
                from,
                dialog,
                quotes,
                text: text,
                attachments: attachments,
              )
              .onError<ForwardChatItemsException>(
                (_, _) => showBlockedPopup(user),
                test: (e) => e.code == ForwardChatItemsErrorCode.blocked,
              );
        }),
      ];

      await Future.wait(futures);
      pop?.call(true);
      onSent?.call();
    } on ForwardChatItemsException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    } finally {
      send.field.unsubmit();
    }
  }
}
