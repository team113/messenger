// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:universal_io/io.dart';

import '/pubspec.g.dart';
import '/util/log.dart';
import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// [File]-system provider for manipulating the persisted [LogEntry].
class LogFileProvider extends DisposableInterface {
  /// [File] to write [LogEntry] to.
  File? _file;

  /// [IOSink] of a [_file] opened for writing.
  IOSink? _sink;

  /// [LogEntry]ies that were [write]en while [_sink] wasn't available.
  final List<LogEntry> _buffer = [];

  /// Returns the [File] to write [LogEntry] to.
  File? get file => _file;

  @override
  void onInit() {
    Log.debug('onInit()', '$runtimeType');

    _open();
    super.onInit();
  }

  @override
  void onClose() {
    Log.debug('onClose()', '$runtimeType');

    _buffer.clear();
    _sink?.close();
    _sink = null;
    _file = null;

    super.onClose();
  }

  /// Writes the [entry] to a [File].
  void write(LogEntry entry) {
    if (_sink == null) {
      return _buffer.add(entry);
    }

    _sink?.writeln(entry);
  }

  /// Returns a [FileStat] of the currently opened logs [File], if any.
  Future<FileStat?> stat() async {
    return await _file?.stat();
  }

  /// Opens the [_file] and appends the initial payload.
  Future<void> _open() async {
    final FutureOr<Directory> futureOrTemp = PlatformUtils.temporaryDirectory;
    final Directory temp = futureOrTemp is Future
        ? await futureOrTemp
        : futureOrTemp;

    _file = File('${temp.path}/report.log');
    final FileStat? stat = await _file?.stat();
    final int size = stat?.size ?? 0;

    _sink = _file?.openWrite(
      mode: switch (size) {
        >= 64 * 1024 * 1024 => FileMode.writeOnly, // 64 MB.
        (_) => FileMode.writeOnlyAppend,
      },
    );

    Log.debug(
      '_open() -> size(${size ~/ 1024} KB, logs will be placed at `${_file?.path}`',
      '$runtimeType',
    );

    _sink?.writeln('''\n
================ Launch ================

Created at: ${DateTime.now().toUtc()}
Application: ${Pubspec.ref}
Is PWA: ${WebUtils.isPwa}

========================================
      ''');

    _sink?.writeAll(_buffer, '\n');
    _buffer.clear();
  }
}
