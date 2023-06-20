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
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:messenger/util/platform_utils.dart';

/// Mocked [PlatformUtilsImpl] to use in the tests.
class PlatformUtilsMock extends PlatformUtilsImpl {
  @override
  Future<File?> fileExists(String filename, {int? size, String? url}) async {
    return null;
  }

  @override
  Future<File?> download(
    String url,
    String filename,
    int? size, {
    String? checksum,
    Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async =>
      File('test/path');

  @override
  Future<String> get downloadsDirectory => Future.value('.temp_hive/downloads');
}
