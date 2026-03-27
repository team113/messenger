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

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:gherkin/gherkin.dart';
import 'package:messenger/util/platform_utils.dart';

import '../mock/platform_utils.dart';
import '../world/custom_world.dart';

/// Picks the provided file from the [PlatformUtilsMock.filesCompleter].
final StepDefinitionGeneric pickFileInPicker = then1<String, CustomWorld>(
  'I pick {string} file in file picker',
  (String filename, context) async {
    await context.world.appDriver.waitUntil(() async {
      final utils = (PlatformUtils as PlatformUtilsMock);
      final completer = utils.filesCompleter;

      if (completer == null) {
        return false;
      }

      final Uint8List bytes = switch (filename) {
        'test.svg' => Uint8List.fromList(
          Utf8Encoder().convert(
            '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"><circle cx="50" cy="50" r="40" stroke="green" stroke-width="4" fill="yellow" /></svg>',
          ),
        ),
        (_) => base64Decode(
          '/9j/4AAQSkZJRgABAQAAAQABAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/wAALCAABAAEBAREA/8QAFAABAAAAAAAAAAAAAAAAAAAACf/EABQQAQAAAAAAAAAAAAAAAAAAAAD/2gAIAQEAAD8AVN//2Q==',
        ),
      };

      completer.complete(
        FilePickerResult([
          PlatformFile(name: filename, size: bytes.length, bytes: bytes),
        ]),
      );

      return true;
    }, pollInterval: const Duration(seconds: 1));
  },
);
