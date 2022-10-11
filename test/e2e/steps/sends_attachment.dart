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

import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart' as dio;
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:gherkin/gherkin.dart';
import 'package:http_parser/http_parser.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/mime.dart';

import '../parameters/users.dart';
import '../mock/graphql.dart';
import '../world/custom_world.dart';

/// Sends a message from the specified [User] to the authenticated [MyUser] in
/// their [Chat]-dialog with the provided attachment.
///
/// Examples:
/// - Then Bob sends "test.txt" attachment to me
final StepDefinitionGeneric sendsAttachmentToMe =
    and2<TestUser, String, CustomWorld>(
  '{user} sends {string} attachment to me',
  (TestUser user, String filename, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;

    String? type = MimeResolver.lookup(filename);
    var response = await provider.uploadAttachment(
      dio.MultipartFile.fromBytes(
        Uint8List.fromList([1, 1]),
        filename: filename,
        contentType: type != null ? MediaType.parse(type) : null,
      ),
    );

    await provider.postChatMessage(
      context.world.sessions[user.name]!.dialog!,
      text: null,
      attachments: [response.attachment.toModel().id],
    );

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
