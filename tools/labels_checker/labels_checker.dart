#!/usr/bin/env dart run
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

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:analyzer/dart/analysis/features.dart' show FeatureSet;
import 'package:analyzer/dart/analysis/utilities.dart' show parseFile;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Command-line utility that scans `.dart` files for **unused .ftl labels**.
///
/// ### Usage examples
/// **Default run**: scans `assets/l10n` and `lib`,
/// skipping labels that start with `email_` or `fcm_`
/// ```bash
/// dart run tools/labels_checker/labels_checker.dart
/// ```
///
/// **Custom locations**
///   ```bash
///   dart run tools/labels_checker/labels_checker.dart \
///       --ftl=assets/l10n/ru-RU.ftl \
///       --src=lib/api
///   ```
///
/// **Custom ignore patterns**
/// ```bash
/// dart run tools/labels_checker/labels_checker.dart \
///   -i '^push_' -i '^analytics_'
/// ```
///
/// ### Exit flags:
/// 1. `0`  if no labels unused
/// 2. `1`  if there are labels unused
/// 3. `64` if wrong cli usage
/// 4. `66` if some input files are missing (you used flags and specified empty --src folder)
Future<void> main(List<String> argv) async {
  // Parse CLI.
  final cli = ArgParser()
    ..addMultiOption(
      'ignore',
      abbr: 'i',
      defaultsTo: ['^email_', '^fcm_'],
      help:
          'RegExp patterns of labels to ignore'
          ' when reporting unused labels.\n',
    )
    ..addOption(
      'ftl',
      abbr: 'f',
      defaultsTo: 'assets/l10n',
      help: 'Path to one .ftl file or a directory that contains them',
    )
    ..addOption(
      'src',
      abbr: 's',
      defaultsTo: 'lib',
      help: 'Directory that contains Dart sources to scan',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help');

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
      ..writeln('Find unused Fluent-style labels in Dart code\n')
      ..writeln('Example:')
      ..writeln('  dart run tools/labels_checker/labels_checker.dart')
      ..writeln(cli.usage);
    return;
  }

  final ftlPathOrDir = args['ftl'] as String;
  final srcDir = args['src'] as String;
  final ignoreRegExps = (args['ignore'] as List<String>)
      .map((exp) => RegExp(exp))
      .toList();

  // Collect .ftl files.
  final List<File> ftlFiles = await _gatherFtlFiles(ftlPathOrDir);
  if (ftlFiles.isEmpty) {
    stderr.writeln('No .ftl files found under $ftlPathOrDir');
    exit(66); // EX_NOINPUT.
  }

  // Parse labels from the .ftl files.
  stdout.writeln(
    'Scanning ${ftlFiles.length.toString().padRight(3)} '
    '${'.ftl'.padRight(5)} files...',
  );
  final Set<String> ftlLabels = <String>{};
  for (final f in ftlFiles) {
    ftlLabels.addAll(await _parseFtlFile(f.path));
  }

  // Collect project files.
  final List<File> dartFiles = await Directory(srcDir)
      .list(recursive: true)
      .where((file) => file is File && file.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  if (dartFiles.isEmpty) {
    stderr.writeln('No dart files were found in $srcDir');
    exit(66); // EX_NOINPUT.
  }

  // Parse project files for labels.
  stdout.writeln(
    'Scanning ${dartFiles.length.toString().padRight(3)} '
    '${'.dart'.padRight(5)} files...\n',
  );
  final Set<String> projectLabels = <String>{};
  for (final file in dartFiles) {
    final fileUnit = parseFile(
      path: file.path,
      featureSet: FeatureSet.latestLanguageVersion(),
    ).unit;

    final visitor = _StringLiteralCollector();
    fileUnit.visitChildren(visitor);
    projectLabels.addAll(visitor.findings);
  }

  // Difference and report.
  final Set<String> ignored = ftlLabels
      .where((label) => ignoreRegExps.any((ignore) => ignore.hasMatch(label)))
      .toSet();

  final Set<String> unused = ftlLabels
      .difference(projectLabels)
      .difference(ignored);

  stdout.writeln('${'Labels discovered'.padRight(18)} : ${ftlLabels.length}');
  stdout.writeln('${'Labels ignored'.padRight(18)} : ${ignored.length}');
  for (final i in ignored) {
    stdout.writeln('  • $i');
  }
  stdout.writeln('${'Labels unused'.padRight(18)} : ${unused.length}');
  for (final l in unused) {
    stdout.writeln('  • $l');
  }
  // Prevents stdout and stderr streams' outputs from mixing.
  await stdout.flush();

  if (unused.isNotEmpty) {
    stderr.writeln('\nYou have unused assets! Remove them.');
    exit(1);
  }

  stdout.writeln('\nUnused assets were not found.');
  exit(0);
}

/// Parses [path] and returns a list of all the found .ftl files by this path.
///
/// Takes either [path] to file or to folder.
Future<List<File>> _gatherFtlFiles(String path) async {
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

/// Parses a Fluent-FTL file and returns the label identifiers on the left side
/// of “labelId = …”.
Future<Set<String>> _parseFtlFile(String path) async {
  final labels = <String>{};

  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Error: .ftl file not found: $path');
    exit(66); // EX_NOINPUT.
  }

  final lines = file
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  await for (final line in lines) {
    final idx = line.indexOf(' =');
    if (idx > 0) labels.add(line.substring(0, idx));
  }

  return labels;
}

/// Grabs every *simple* string literal (no interpolation) in a compilation unit.
class _StringLiteralCollector extends RecursiveAstVisitor<void> {
  final findings = <String>{};

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    // Trim quotes.
    final rawString = node.toString();
    final string = rawString.substring(1, rawString.length - 1);

    findings.add(string);
    super.visitSimpleStringLiteral(node);
  }
}
