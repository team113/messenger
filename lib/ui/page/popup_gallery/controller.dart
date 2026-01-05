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

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/paginated.dart';
import '/domain/service/chat.dart';
import '/routes.dart';
import '/util/web/web_utils.dart';

export 'view.dart';

/// Controller of the [Routes.gallery] page.
class PopupGalleryController extends GetxController {
  PopupGalleryController(this.chatId, this._chatService);

  /// ID of a [Chat] this [chat] is taking place in.
  final ChatId chatId;

  /// [RxChat] this [PopupGalleryController] is about.
  final Rx<RxChat?> chat = Rx(null);

  /// [RxStatus] of this [PopupGalleryController].
  final Rx<RxStatus> status = Rx(RxStatus.loading());

  /// [GlobalKey] for [PaginatedGallery] to keep builds from happening.
  final GlobalKey key = GlobalKey();

  /// [ChatService] maintaining the [chat].
  final ChatService _chatService;

  @override
  void onInit() {
    _fetchChat();
    super.onInit();
  }

  @override
  void onClose() {
    WebUtils.closeWindow();
    super.dispose();
  }

  /// Returns a [Paginated] of [ChatItem]s containing a collection of all the
  /// media files of this [chat].
  Paginated<ChatItemId, Rx<ChatItem>> calculateGallery(ChatItemId? id) {
    return chat.value!.attachments(item: id);
  }

  /// Fetches the [chat].
  Future<void> _fetchChat() async {
    chat.value = await _chatService.get(chatId);
    if (chat.value == null) {
      status.value = RxStatus.empty();
    } else {
      status.value = RxStatus.success();
    }
  }
}
