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

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:isar/isar.dart';
import 'package:messenger/provider/isar/user.dart';
import 'package:messenger/util/platform_utils.dart';

/// Initializes [Isar] for the tests.
Future<Isar> initializeIsar({String? path}) async {
  final url = PlatformUtils.isWindows
      ? 'isar_windows_x64.dll'
      : PlatformUtils.isMacOS
          ? 'libisar_macos.dylib'
          : 'libisar_linux_x64.so';

  final name = PlatformUtils.isWindows
      ? 'isar.dll'
      : PlatformUtils.isMacOS
          ? 'libisar.dylib'
          : 'libisar.so';

  final binary = '${Directory.current.path}/$name';

  if (!File(binary).existsSync()) {
    await Dio().download(
      'https://github.com/isar/isar/releases/download/4.0.0-dev.9/$url',
      binary,
    );
  }

  await Isar.initialize(binary);

  return Isar.open(
    schemas: [IsarUserSchema],
    directory: path ?? Isar.sqliteInMemory,
    engine: path == null ? IsarEngine.sqlite : IsarEngine.isar,
  );
}
