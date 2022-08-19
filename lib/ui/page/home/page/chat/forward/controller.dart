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

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';

import '/domain/model/attachment.dart';
import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat_item_quote.dart';
import '/domain/model/user.dart';
import '/domain/model/native_file.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/provider/gql/exceptions.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

export 'view.dart';

/// Controller of the forward messages modal.
class ChatForwardController extends GetxController {
  ChatForwardController(
    this._chatService,
    this._userService,
    this.fromId,
    this.forwardItem,
  );

  /// Reactive list of sorted [Chat]s.
  late final RxList<RxChat> chats;

  /// Selected chats to forward messages.
  final RxList<ChatId> selectedChats = RxList<ChatId>([]);

  /// ID of [Chat] from messages will forward.
  final ChatId fromId;

  /// Item that was forwarded.
  final ChatItemQuote forwardItem;

  /// State of a send forwarded messages field.
  late final TextFieldState send;

  /// Attachments to be attached to a forward.
  RxList<AttachmentData> attachments = RxList<AttachmentData>();

  /// [Chat]s service used to add members to a [Chat].
  final ChatService _chatService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  @override
  void onInit() {
    chats = RxList<RxChat>(_chatService.chats.values.toList());
    _sortChats();

    send = TextFieldState(
      onChanged: (s) => s.error.value = null,
      onSubmitted: (s) async {
        s.status.value = RxStatus.loading();
        s.editable.value = false;

        try {
          var futures = selectedChats.map(
            (e) async {
              final List<AttachmentId> attachmentIds = [];

              if (attachments.isNotEmpty) {
                Iterable<Future> futures =
                    attachments.map((e) => e.upload.value).whereNotNull();
                await Future.wait(futures);

                for (var file in attachments) {
                  if (file.attachment == null) {
                    s.status.value = RxStatus.empty();
                    s.unsubmit();
                    return;
                  }
                  attachmentIds.add(file.attachment!.id);
                }
              }

              return _chatService.forwardChatItems(
                from: fromId,
                to: e,
                items: [forwardItem],
                text: s.text == '' ? null : ChatMessageText(s.text),
                attachments: attachmentIds.isEmpty ? null : attachmentIds,
              );
            },
          );

          await Future.wait(futures);
        } on ForwardChatItemsException catch (e) {
          MessagePopup.error(e);
        } catch (e) {
          MessagePopup.error(e);
          rethrow;
        } finally {
          s.unsubmit();
        }
      },
    );

    super.onInit();
  }

  /// Opens a file choose popup and adds the selected files to the
  /// [attachments].
  Future<void> pickFile() => _pickAttachment(FileType.any);

  /// Constructs a [NativeFile] from the specified [PlatformFile] and adds it
  /// to the [attachments].
  Future<void> addPlatformAttachment(PlatformFile platformFile) async {
    NativeFile nativeFile = NativeFile.fromPlatformFile(platformFile);
    await _addAttachment(nativeFile);
  }

  /// Returns an [User] from [UserService] by the provided [id].
  Future<RxUser?> getUser(UserId id) => _userService.get(id);

  /// Sorts the [chats] by the [Chat.updatedAt] and [Chat.currentCall] values.
  void _sortChats() {
    chats.sort((a, b) {
      if (a.chat.value.currentCall != null &&
          b.chat.value.currentCall == null) {
        return -1;
      } else if (a.chat.value.currentCall == null &&
          b.chat.value.currentCall != null) {
        return 1;
      }

      return b.chat.value.updatedAt.compareTo(a.chat.value.updatedAt);
    });
  }

  /// Opens a file choose popup of the specified [type] and adds the selected
  /// files to the [attachments].
  Future<void> _pickAttachment(FileType type) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: type,
      allowMultiple: true,
      withReadStream: true,
    );

    if (result != null && result.files.isNotEmpty) {
      for (PlatformFile e in result.files) {
        addPlatformAttachment(e);
      }
    }
  }

  /// Constructs an [AttachmentData] from the specified [file] and adds it to
  /// the [attachments] list.
  ///
  /// May be used to test a [file] upload since [FilePicker] can't be mocked.
  Future<void> _addAttachment(NativeFile file) async {
    var attachment = AttachmentData(file);
    attachments.add(attachment);

    await file.ensureCorrectMediaType();
    if (file.isImage && PlatformUtils.isWeb) {
      await file.readFile();
    }

    attachment.upload.value = _uploadAttachment(attachment);
    attachments.refresh();
  }

  /// Uploads the specified [data] as an attachment.
  Future<void> _uploadAttachment(AttachmentData data) async {
    try {
      data.attachment = await _chatService.uploadAttachment(
        data.file,
        onSendProgress: (now, max) {
          data.progress.value = now / max;
        },
      );
    } on UploadAttachmentException catch (e) {
      data.hasError.value = true;
      MessagePopup.error(e);
    } catch (e) {
      data.hasError.value = true;
      MessagePopup.error(e);
      rethrow;
    } finally {
      data.upload.value = null;
    }
  }
}
