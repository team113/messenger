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

import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/service/auth.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// [Routes.chatDirectLink] page controller.
class ChatDirectLinkController extends GetxController {
  ChatDirectLinkController(String url, this._auth) {
    ChatDirectLinkSlug? link;
    try {
      link = ChatDirectLinkSlug(url);
    } on FormatException catch (_) {
      // No-op.
    }

    slug = Rx<ChatDirectLinkSlug?>(link);
  }

  /// [ChatDirectLinkSlug] of this controller.
  late final Rx<ChatDirectLinkSlug?> slug;

  /// Authorization service used for signing up.
  final AuthService _auth;

  @override
  void onReady() async {
    if (_auth.status.value.isSuccess) {
      await _useChatDirectLink();
    } else if (_auth.status.value.isEmpty) {
      await _register();
      if (_auth.status.value.isSuccess) {
        await _useChatDirectLink();
      }
    }

    super.onReady();
  }

  /// Creates a new [MyUser].
  Future<void> _register() async {
    try {
      await _auth.register();
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }

  /// Uses the [slug] and redirects to the fetched [Routes.chats] page on
  /// success.
  Future<void> _useChatDirectLink() async {
    try {
      ChatId chatId = await _auth.useChatDirectLink(slug.value!);
      router.chat(chatId);
    } on UseChatDirectLinkException catch (e) {
      if (e.code == UseChatDirectLinkErrorCode.unknownDirectLink) {
        slug.value = null;
      } else {
        MessagePopup.error(e);
      }
    } catch (e) {
      MessagePopup.error(e);
      rethrow;
    }
  }
}
