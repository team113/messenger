// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
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

import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/api/backend/schema.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/provider/gql/exceptions.dart';
import '/routes.dart';
import '/util/message_popup.dart';

export 'view.dart';

/// [Routes.chatDirectLink] page controller.
class ChatDirectLinkController extends GetxController {
  ChatDirectLinkController(String url, this._chatService)
    : slug = Rx(ChatDirectLinkSlug.tryParse(url));

  /// [ChatDirectLinkSlug] of this controller.
  final Rx<ChatDirectLinkSlug?> slug;

  /// [ChatService] used for using [slug].
  final ChatService _chatService;

  /// [Sentry] transaction monitoring this [ChatDirectLinkController] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.direct_link.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  );

  @override
  void onReady() async {
    try {
      await _useChatDirectLink();
      SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());
    } catch (e) {
      _ready.throwable = e;
      _ready.finish(status: const SpanStatus.internalError());
      rethrow;
    }

    super.onReady();
  }

  /// Uses the [slug] and redirects to the fetched [Routes.chats] page on
  /// success.
  Future<void> _useChatDirectLink() async {
    final ISentrySpan span = _ready.startChild('use');

    try {
      final ChatId chatId = await _chatService.useChatDirectLink(slug.value!);
      final RxChat? chat = await _chatService.get(chatId);
      if (chat == null) {
        throw UseChatDirectLinkException(
          UseChatDirectLinkErrorCode.unknownDirectLink,
        );
      }

      router.dialog(
        chat.chat.value,
        _chatService.me,
        link: slug.value,
        mode: RouteAs.insteadOfLast,
      );
    } on UseChatDirectLinkException catch (e) {
      span.throwable = e;
      span.status = const SpanStatus.internalError();

      if (e.code == UseChatDirectLinkErrorCode.unknownDirectLink) {
        slug.value = null;
      } else {
        MessagePopup.error(e);
      }
    } catch (e) {
      span.throwable = e;
      span.status = const SpanStatus.internalError();

      MessagePopup.error(e);
      rethrow;
    } finally {
      span.finish();
    }
  }
}
