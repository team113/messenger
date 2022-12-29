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

import 'package:collection/collection.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/api/backend/schema.dart' show ForwardChatItemsErrorCode;
import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';
import '/util/message_popup.dart';
import '/util/obs/obs.dart';

export 'view.dart';

/// Controller of a [ChatForwardView].
class ChatForwardController extends GetxController {
  ChatForwardController(
    this._chatService,
    this._userService, {
    required this.from,
    required List<ChatItemQuote> quotes,
    this.text,
    this.pop,
    RxList<MapEntry<GlobalKey, Attachment>>? attachments,
  })  : quotes = RxList(quotes),
        attachments = RxObsList(attachments ?? []);

  /// Selected items in [SearchView] popup.
  final Rx<SearchViewResults?> searchResults = Rx(null);

  /// ID of the [Chat] the [quotes] are forwarded from.
  final ChatId from;

  /// Initial [String] to put in the [MessageFieldController.send] field.
  final String? text;

  /// [ChatItemQuote]s to be forwarded.
  final RxList<ChatItemQuote> quotes;

  /// Callback, called when a [ChatForwardView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function()? pop;

  /// [Attachment]s to attach to the [quotes].
  final RxObsList<MapEntry<GlobalKey, Attachment>> attachments;

  /// Indicator whether there is an ongoing drag-n-drop at the moment.
  final RxBool isDraggingFiles = RxBool(false);

  /// [Chat]s service forwarding the [quotes].
  final ChatService _chatService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// [Worker] to react on the [quotes] updates.
  late final Worker quotesChanges;

  /// [MessageFieldController] controller sending the [ChatMessage].
  late final MessageFieldController send;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    send = MessageFieldController(
      _chatService,
      _userService,
      onSubmit: () async {
        if (searchResults.value?.isEmpty != false) {
          send.field.unsubmit();
          return;
        }

        send.field.status.value = RxStatus.loading();
        send.field.editable.value = false;

        try {
          List<Future> uploads = send.attachments
              .whereType<LocalAttachment>()
              .map((e) => e.upload.value?.future)
              .whereNotNull()
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

          final ChatMessageText? text =
              send.field.text.isEmpty ? null : ChatMessageText(send.field.text);

          List<Future<void>> futures = [
            ...searchResults.value!.chats.map((e) async {
              return _chatService.forwardChatItems(
                from,
                e.chat.value.id,
                send.quotes,
                text: text,
                attachments: attachments,
              );
            }),
            ...searchResults.value!.users.map((e) async {
              Chat? dialog = e.user.value.dialog;
              dialog ??= (await _chatService.createDialogChat(e.id)).chat.value;

              return _chatService.forwardChatItems(
                from,
                dialog.id,
                send.quotes,
                text: text,
                attachments: attachments,
              );
            }),
            ...searchResults.value!.contacts.map((e) async {
              Chat? dialog = e.user.value?.user.value.dialog;
              dialog ??= (await _chatService.createDialogChat(e.user.value!.id))
                  .chat
                  .value;

              return _chatService.forwardChatItems(
                from,
                dialog.id,
                send.quotes,
                text: text,
                attachments: attachments,
              );
            })
          ];

          await Future.wait(futures);
          pop?.call();
        } on ForwardChatItemsException catch (e) {
          MessagePopup.error(e);
        } catch (e) {
          MessagePopup.error(e);
          rethrow;
        } finally {
          send.field.unsubmit();
        }
      },
    )..onInit();

    send.quotes.addAll(quotes);
    send.attachments.addAll(attachments);

    quotesChanges = ever(quotes, (_) {
      if (quotes.isEmpty) {
        pop?.call();
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    quotesChanges.dispose();
    super.onClose();
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Adds the specified [details] files to the [attachments].
  void dropFiles(DropDoneDetails details) async {
    for (var file in details.files) {
      send.addPlatformAttachment(PlatformFile(
        path: file.path,
        name: file.name,
        size: await file.length(),
        readStream: file.openRead(),
      ));
    }
  }
}
