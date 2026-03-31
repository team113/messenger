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

import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:gherkin/gherkin.dart';
import 'package:http_parser/http_parser.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/domain/model/chat_item.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/ui/page/style/page/widgets/common/cat.dart';

import '../parameters/attachment.dart';
import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Sends the provided amount of [ChatMessage]s with [Attachment]s to the
/// specified [Chat]-group.
///
/// Examples:
/// - Then Alice posts 15 image attachments to "Gallery" group
final StepDefinitionGeneric postsNAttachmentsToGroup =
    and4<TestUser, int, AttachmentType, String, CustomWorld>(
      '{user} posts {int} {attachment} attachments to {string} group',
      (
        TestUser user,
        int count,
        AttachmentType type,
        String group,
        context,
      ) async {
        final GraphQlProvider provider = GraphQlProvider()
          ..client.withWebSocket = false
          ..token = context.world.sessions[user.name]?.token;

        final response = await provider.uploadAttachment(
          dio.MultipartFile.fromBytes(
            switch (type) {
              AttachmentType.image => CatImage.bytes,
              AttachmentType.file => Uint8List.fromList([1, 1]),
            },
            filename: switch (type) {
              AttachmentType.image => 'image.jpg',
              AttachmentType.file => 'file.bin',
            },
            contentType: switch (type) {
              AttachmentType.image => MediaType('image', 'jpeg'),
              AttachmentType.file => MediaType('application', 'octet-stream'),
            },
          ),
        );

        for (int i = 0; i < count; ++i) {
          await provider.postChatMessage(
            context.world.groups[group]!,
            text: ChatMessageText('$i'),
            attachments: [response.attachment.toModel().id],
          );
        }

        provider.disconnect();
      },
      configuration: StepDefinitionConfiguration()
        ..timeout = const Duration(minutes: 5),
    );
