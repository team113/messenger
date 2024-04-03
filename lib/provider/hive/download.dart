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

import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';

import '/util/log.dart';
import 'base.dart';

/// [Hive] storage for [File.path]s.
class DownloadHiveProvider extends HiveLazyProvider<String> {
  @override
  Stream<BoxEvent> get boxEvents => box.watch();

  @override
  String get boxName => 'download';

  @override
  void registerAdapters() {}

  /// Returns a list of [File.path]s from [Hive].
  Future<Iterable<String>> get downloads => valuesSafe;

  /// Puts the provided [File.path] to [Hive].
  Future<void> put(String checksum, String path) async {
    Log.trace('put($checksum, $path)', '$runtimeType');
    await putSafe(checksum, path);
  }

  /// Returns a [File.path] from [Hive] by its [checksum].
  Future<String?> get(String checksum) async {
    Log.trace('get($checksum)', '$runtimeType');
    return await getSafe(checksum);
  }

  /// Removes an [File.path] from [Hive] by its [checksum].
  Future<void> remove(String checksum) async {
    Log.trace('remove($checksum)', '$runtimeType');
    await deleteSafe(checksum);
  }
}
