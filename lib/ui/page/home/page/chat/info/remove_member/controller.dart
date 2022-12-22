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

import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:messenger/api/backend/schema.dart'
    show ConfirmUserEmailErrorCode;
import 'package:messenger/domain/model/chat.dart';
import 'package:messenger/domain/model/my_user.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/domain/service/chat.dart';
import 'package:messenger/domain/service/my_user.dart';
import 'package:messenger/routes.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/provider/gql/exceptions.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// Controller of a [ChatForwardView].
class RemoveMemberController extends GetxController {
  RemoveMemberController(
    this._chatService, {
    required this.chatId,
    required this.user,
  });

  final ChatId chatId;
  final RxUser user;

  final ChatService _chatService;

  UserId? get me => _chatService.me;

  /// Removes [User] identified by the provided [userId] from the [chat].
  Future<void> removeChatMember() async {
    try {
      await _chatService.removeChatMember(chatId, user.id);
      if (user.id == _chatService.me &&
          router.route.startsWith('${Routes.chat}/$chatId')) {
        router.home();
      }
    } on RemoveChatMemberException catch (e) {
      MessagePopup.error(e);
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }
}
