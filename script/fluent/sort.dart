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

import 'dart:io';

import 'package:args/args.dart';

/// Command-line utility sorting `.ftl` labels.
///
/// ### Usage examples
///
/// ```bash
/// dart run sort.dart
/// ```
///
/// #### Exit instead of applying the sorting
///
/// ```bash
/// dart run sort.dart --exit
/// ```
///
/// #### Custom locations
///
/// ```bash
/// dart run sort.dart \
///          --ftl=assets/l10n/ru-RU.ftl
/// ```
///
/// ### Exit flags
///
/// - 0, on success.
/// - 1, when sorting is required (applicable when `--exit` flag is provided).
/// - 64, when invalid arguments are passed.
/// - 66, when input files can't be found.
Future<void> main(List<String> argv) async {
  // Parse arguments.
  final ArgParser cli = ArgParser()
    ..addOption(
      'target',
      abbr: 't',
      defaultsTo: 'assets/l10n',
      help: 'Path to one `.ftl` file or a directory that contains those.',
    )
    ..addFlag(
      'exit',
      abbr: 'e',
      negatable: false,
      help: 'Exit instead of applying changes.',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help.');

  late final ArgResults args;
  try {
    args = cli.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(cli.usage);
    exit(64); // EX_USAGE.
  }

  if (args['help'] as bool) {
    stdout
      ..writeln('Sort Fluent-style labels.\n')
      ..writeln('Example:')
      ..writeln('  dart run sort.dart')
      ..writeln(cli.usage);
    return;
  }

  final String fileOrDirectory = args['target'] as String;
  final bool shouldExit = args['exit'] as bool;

  // Collect `.ftl` files.
  final List<File> files = await _readFiles(fileOrDirectory);
  if (files.isEmpty) {
    stderr.writeln('No .ftl files found under $fileOrDirectory.');
    exit(66); // EX_NOINPUT.
  }

  for (var file in files) {
    String? currentKey;

    final List<String> lines = await file.readAsLines();

    // Read and keep the header of the file.
    final List<String> headers = [];
    for (var e in lines) {
      if (!e.startsWith('#')) {
        break;
      }

      headers.add(e);
    }

    final List<MapEntry<String, String>> entries = [];
    final StringBuffer buffer = StringBuffer();
    final RegExp keyRegex = RegExp(r'^([a-zA-Z0-9_-]+)\s*=');

    // Flashes the [currentKey] to the [entries] list.
    void flush() {
      if (currentKey != null) {
        entries.add(MapEntry(currentKey, buffer.toString().trimRight()));
      }
    }

    for (final line in lines) {
      final match = keyRegex.firstMatch(line);

      if (match != null) {
        // Flush, as new entry begins.
        flush();

        currentKey = match.group(1);
        buffer.clear();
        buffer.writeln(line);
      } else {
        // Continuation of the current entry (multiline).
        if (currentKey != null) {
          buffer.writeln(line);
        }
      }
    }

    // Account the last key.
    flush();

    // Sort entries by key.
    final List<MapEntry<String, String>> sorted = entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    if (shouldExit) {
      for (int i = 0; i < sorted.length; ++i) {
        final MapEntry<String, String>? source = entries.elementAtOrNull(i);
        final MapEntry<String, String>? target = sorted.elementAtOrNull(i);

        if (source?.key != target?.key) {
          stdout.writeln(
            '\n⛔️ `${source?.key}` in `${file.path.split('/').last}` seems to be not sorted.',
          );
          exit(1);
        }
      }

      stdout.writeln('\n✅ All files are sorted.');
      exit(0);
    }

    final StringBuffer result = StringBuffer();
    if (headers.isNotEmpty) {
      result.write('${headers.join('\n')}\n\n');
    }
    result.write('${sorted.map((e) => e.value).join('\n')}\n');

    await file.writeAsString(result.toString());
  }

  stdout.writeln('\n✅ Sorted.');
  exit(0);
}

/// Parses [path] and returns a list of all the found `.ftl` files by this path.
///
/// Takes either [path] to file or to folder.
Future<List<File>> _readFiles(String path) async {
  if (await FileSystemEntity.isDirectory(path)) {
    return Directory(path)
        .list(recursive: true)
        .where((file) => file is File && file.path.endsWith('.ftl'))
        .cast<File>()
        .toList();
  }

  final f = File(path);
  return await f.exists() ? [f] : <File>[];
}
