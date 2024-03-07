// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

import 'package:dio/dio.dart' as dio;
import 'package:flutter/services.dart';
import 'package:gherkin/gherkin.dart';
import 'package:http_parser/http_parser.dart';
import 'package:messenger/api/backend/extension/chat.dart';
import 'package:messenger/provider/gql/graphql.dart';
import 'package:messenger/util/mime.dart';

import '../parameters/users.dart';
import '../world/custom_world.dart';

/// Sends a message from the specified [User] to the authenticated [MyUser] in
/// their [Chat]-dialog with the provided attachment.
///
/// Examples:
/// - Then Bob sends "test.txt" attachment to me
/// - Then Bob sends "test.jpg" attachment to me
/// - Then Bob sends "test.mp3" attachment to me
final StepDefinitionGeneric sendsAttachmentToMe =
    and2<TestUser, String, CustomWorld>(
  '{user} sends {string} attachment to me',
  (TestUser user, String filename, context) async {
    final provider = GraphQlProvider();
    provider.token = context.world.sessions[user.name]?.token;

    final String? type = MimeResolver.lookup(filename);
    final MediaType? mime = type != null ? MediaType.parse(type) : null;
    Uint8List fileBytes;

    if (mime?.type == 'image') {
      fileBytes = base64Decode(
          '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==');
    } else if (mime?.type == 'audio') {
      // fileBytes = generateAudioFile(durationSeconds: 20);

      ByteData data = await rootBundle.load('assets/audio/sample_audio.mp3');
      final buffer = data.buffer;
      var list = buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      fileBytes = list;
    } else {
      fileBytes = Uint8List.fromList([1, 1]);
    }

    final response = await provider.uploadAttachment(
      dio.MultipartFile.fromBytes(
        fileBytes,
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

Uint8List generateAudioFile({int durationSeconds = 10}) {
  // Set some basic parameters
  const int sampleRate = 44100;
  const int bitDepth = 16;
  const double frequency = 440.0; // Hz

  // Calculate the number of samples based on the duration
  int numSamples = durationSeconds * sampleRate;

  // Prepare the byte buffer for the audio data
  Uint8List audioBytes = Uint8List(numSamples * bitDepth ~/ 8);

  // Generate audio data
  for (int i = 0; i < numSamples; i++) {
    double t = i / sampleRate;
    double value = sin(2 * pi * frequency * t);
    int intValue = (value * (pow(2, bitDepth) / 2 - 1)).round();
    for (int j = 0; j < bitDepth ~/ 8; j++) {
      audioBytes[i * bitDepth ~/ 8 + j] = (intValue >> (8 * j)) & 0xff;
    }
  }

  return audioBytes;
}
