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

//
// ──────────────────────────────────────────────────────────────────────────────
//  labels_checker.dart – find unused Fluent-FTL labels in a Dart project
// ──────────────────────────────────────────────────────────────────────────────
//  Usage:
//      dart run tools/labels_checker.dart -f assets/l10n/en-US.ftl -s lib
//  or (after chmod):
//      tools/labels_checker.dart -f … -s …
//
//  Requires: Dart 3.x, package:analyzer, package:args
// ──────────────────────────────────────────────────────────────────────────────

import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:analyzer/dart/analysis/features.dart' show FeatureSet;
import 'package:analyzer/dart/analysis/utilities.dart' show parseFile;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

Future<void> main(List<String> argv) async {
  // Parse CLI.
  final cli = ArgParser()
    ..addOption(
      'ftl',
      abbr: 'f',
      help: 'Path to the source .ftl file (en-US.ftl, ru-RU.ftl, etc.)',
    )
    ..addOption(
      'src',
      abbr: 's',
      help: 'Directory that contains Dart sources to scan (e.g. "lib")',
    )
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show this help');

  ArgResults args;
  try {
    args = cli.parse(argv);
  } on FormatException catch (e) {
    stderr.writeln(e.message);
    stderr.writeln(cli.usage);
    exit(64); // EX_USAGE.
  }

  if (args['help'] as bool ||
      !args.wasParsed('ftl') ||
      !args.wasParsed('src')) {
    stdout
      ..writeln('Find unused Fluent-style labels in Dart code\n')
      ..writeln('Example:')
      ..writeln(
        '  dart run tools/labels_checker.dart -f assets/l10n/en-US.ftl -s lib\n',
      )
      ..writeln(cli.usage);
    return;
  }

  final ftlPath = args['ftl'] as String;
  final srcDir = args['src'] as String;

  // Parse labels from the .ftl file.
  final ftlLabels = await _parseFtlFile(ftlPath);

  // Walk every Dart file and collect literals.
  final projectLabels = <String>{};

  final dartFiles = await Directory(srcDir)
      .list(recursive: true)
      .where((e) => e is File && e.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  if (dartFiles.isEmpty) {
    stderr.writeln('No dart files were found in $srcDir');
    exit(0);
  }

  for (final file in dartFiles) {
    final fileUnit = parseFile(
      path: file.path,
      featureSet: FeatureSet.latestLanguageVersion(),
    ).unit;

    final visitor = _StringLiteralCollector();
    fileUnit.visitChildren(visitor);
    projectLabels.addAll(visitor.findings);
  }

  // Diff and report.
  final unused = ftlLabels.difference(projectLabels);

  stdout
    ..writeln('Labels in $ftlPath: ${ftlLabels.length}')
    ..writeln('UNUSED labels (${unused.length}):');
  for (final l in unused) {
    stdout.writeln('  • $l');
  }
}

/// Parses a Fluent-FTL file and returns the label identifiers on the left side
/// of “labelId = …”.
Future<Set<String>> _parseFtlFile(String path) async {
  const copyrightLines = 17;
  final labels = <String>{};

  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Error: .ftl file not found: $path');
    exit(66); // EX_NOINPUT.
  }

  final lines = file
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .skip(copyrightLines);

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
