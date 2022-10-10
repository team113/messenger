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
    final GraphQlProvider provider = Get.find();
    filename = 'test.jpg';
    provider.token = context.world.sessions[user.name]?.session.token;
    // final PlatformFile image = PlatformFile(
    //   name: filename,
    //   size: 2,
    //   bytes: base64Decode(
    //     'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVQYV2NgYAAAAAMAAWgmWQ0AAAAASUVORK5CYII=',
    //   ),
    // );
    String? type = MimeResolver.lookup(filename);
    if (type != null) {
      print(MediaType.parse(type));
    }
    String? type2 = MimeResolver.lookup('test.jpg');
    if (type2 != null) {
      print(MediaType.parse(type2));
    }
    var response = await provider.uploadAttachment(
      dio.MultipartFile.fromBytes([
        137,
        80,
        78,
        71,
        13,
        10,
        26,
        10,
        0,
        0,
        0,
        13,
        73,
        72,
        68,
        82,
        0,
        0,
        0,
        1,
        0,
        0,
        0,
        1,
        8,
        6,
        0,
        0,
        0,
        31,
        21,
        196,
        137,
        0,
        0,
        0,
        13,
        73,
        68,
        65,
        84,
        120,
        218,
        99,
        252,
        207,
        192,
        80,
        15,
        0,
        4,
        133,
        1,
        128,
        132,
        169,
        140,
        33,
        0,
        0,
        0,
        0,
        73,
        69,
        78,
        68,
        174,
        66,
        96,
        130
      ], filename: filename, contentType: MediaType.parse('image/png')),
    );

    if (provider is MockGraphQlProvider) {
      print('make delay');
      provider.client.delay = Duration(seconds: 4);
      provider.client.throwException = false;
    }

    provider.postChatMessage(
      context.world.sessions[user.name]!.dialog!,
      text: null,
      attachments: [response.attachment.toModel().id],
    );
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);

/// Sends a message from the specified [User] to the authenticated [MyUser] in
/// their [Chat]-dialog with the provided attachment.
///
/// Examples:
/// - Then Bob sends "test.txt" image to me
final StepDefinitionGeneric sendsAttachmentImageToMe =
    and2<TestUser, String, CustomWorld>(
  '{user} sends {string} image to me',
  (TestUser user, String filename, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.session.token;

    final PlatformFile image = PlatformFile(
      name: filename,
      size: 2,
      bytes: base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );

    print(image.bytes!.toList());

    String? type = MimeResolver.lookup(filename);
    var response = await provider.uploadAttachment(
      dio.MultipartFile.fromBytes(
        image.bytes!.toList(),
        filename: filename,
        contentType: MediaType.parse(type!),
      ),
    );
    // await provider.postChatMessage(
    //   context.world.sessions[user.name]!.dialog!,
    //   text: null,
    //   attachments: [response.attachment.toModel().id],
    // );

    provider.disconnect();
  },
  configuration: StepDefinitionConfiguration()
    ..timeout = const Duration(minutes: 5),
);
