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
import 'dart:typed_data';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/precise_date_time/precise_date_time.dart';
import 'package:messenger/domain/repository/settings.dart';

import '/domain/model/chat.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/domain/service/chat.dart';
import '/domain/service/user.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/controller.dart';

export 'view.dart';

/// Controller of a [ChatForwardView].
class WelcomeMessageController extends GetxController {
  WelcomeMessageController(
    this._chatService,
    this._userService,
    this._settingsRepo, {
    ChatMessage? initial,
    this.pop,
  }) : message = Rx(initial);

  /// Selected items in [SearchView] popup.
  final Rx<SearchViewResults?> searchResults = Rx(null);

  /// Callback, called when a [ChatForwardView] this controller is bound to
  /// should be popped from the [Navigator].
  final void Function(dynamic)? pop;

  /// [ScrollController] to pass to a [Scrollbar].
  final ScrollController scrollController = ScrollController();

  /// Indicator whether there is an ongoing drag-n-drop at the moment.
  final RxBool isDraggingFiles = RxBool(false);

  /// [Chat]s service forwarding the [quotes].
  final ChatService _chatService;

  /// [User]s service fetching the [User]s in [getUser] method.
  final UserService _userService;

  /// Settings repository, used to update the [ApplicationSettings].
  final AbstractSettingsRepository _settingsRepo;

  /// [MessageFieldController] controller sending the [ChatMessage].
  late final MessageFieldController send;

  late final Rx<ChatMessage?> message;

  /// Returns [MyUser]'s [UserId].
  UserId? get me => _chatService.me;

  /// Returns the current background's [Uint8List] value.
  Rx<Uint8List?> get background => _settingsRepo.background;

  @override
  void onInit() {
    send = MessageFieldController(
      _chatService,
      _userService,
      text: message.value?.text?.val,
      attachments: message.value?.attachments ?? [],
      onSubmit: () async {
        pop?.call(
          ChatMessage(
            message.value?.id ?? ChatItemId.local(),
            message.value?.chatId ?? const ChatId('123'),
            message.value?.authorId ?? me!,
            message.value?.at ?? PreciseDateTime.now(),
            text: ChatMessageText(send.field.text),
            attachments: send.attachments.map((e) => e.value).toList(),
          ),
        );

        send.clear();
      },
    );

    send.editing.value = message.value != null;

    super.onInit();
  }

  @override
  void onClose() {
    send.onClose();
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
