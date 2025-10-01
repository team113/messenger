// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

/// Command-line utility scanning `.dart` files for unused `.ftl` labels.
///
/// By default scans `assets/l10n` and `lib`, skipping labels that start with
/// `email_` or `fcm_`.
///
/// ### Usage examples
///
/// ```bash
/// dart run analyze.dart
/// ```
///
/// #### Custom locations
///
/// ```bash
/// dart run analyze.dart \
///          --ftl=assets/l10n/ru-RU.ftl \
///          --src=lib/api
/// ```
///
/// #### Custom ignore patterns
///
/// ```bash
/// dart run analyze.dart \
///          -i '^push_' \
///          -i '^analytics_'
/// ```
///
/// ### Exit flags
///
/// - 0, on success.
/// - 1, when unused labels are found.
/// - 64, when invalid arguments are passed.
/// - 66, when input files can't be found (including empty `--src` folder).
Future<void> main(List<String> argv) async {
  // Parse arguments.
  final ArgParser cli = ArgParser()
    ..addMultiOption(
      'ignore',
      abbr: 'i',
      defaultsTo: [
        '^email_',
        '^fcm_',
        '^country_',

        // TODO: Remove when WebAssembly performance is fixed.
        'btn_call_cut_video',
        'btn_call_do_not_cut_video',

        // TODO: Remove once desktop apps are shipped.
        'label_desktop_apps',
      ],
      help: 'Labels to ignore in `.ftl` files (supports regular expressions).',
    )
    ..addOption(
      'ftl',
      abbr: 'f',
      defaultsTo: 'assets/l10n',
      help: 'Path to one `.ftl` file or a directory that contains those.',
    )
    ..addOption(
      'src',
      abbr: 's',
      defaultsTo: 'lib',
      help: 'Directory with Dart sources to scan.',
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
      ..writeln('Find unused Fluent-style labels in Dart code.\n')
      ..writeln('Example:')
      ..writeln('  dart run analyze.dart')
      ..writeln(cli.usage);
    return;
  }

  final String ftlPathOrDir = args['ftl'] as String;
  final String srcDir = args['src'] as String;
  final List<RegExp> ignoreRegExps = (args['ignore'] as List<String>)
      .map(RegExp.new)
      .toList();

  // Collect `.ftl` files.
  final List<File> ftlFiles = await _gatherFtlFiles(ftlPathOrDir);
  if (ftlFiles.isEmpty) {
    stderr.writeln('No .ftl files found under $ftlPathOrDir.');
    exit(66); // EX_NOINPUT.
  }

  // Parse labels from the `.ftl` files.
  stdout.write('Scanning ${ftlFiles.length} `.ftl` files...');

  final Set<String> ftlLabels = <String>{};
  for (final f in ftlFiles) {
    ftlLabels.addAll(await _parseFtlFile(f.path));
  }

  stdout.writeln(' done.');

  // Collect project files.
  final List<File> dartFiles = await Directory(srcDir)
      .list(recursive: true)
      .where((file) => file is File && file.path.endsWith('.dart'))
      .cast<File>()
      .toList();

  if (dartFiles.isEmpty) {
    stderr.writeln('No `.dart` files were found in $srcDir.');
    exit(66); // EX_NOINPUT.
  }

  // Parse project files for labels.
  stdout.write('Scanning ${dartFiles.length} `.dart` files...');

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

  stdout.writeln(' done.');
  stdout.writeln();

  // Differentiate and report.
  final Set<String> ignored = ftlLabels
      .where((label) => ignoreRegExps.any((ignore) => ignore.hasMatch(label)))
      .toSet();

  final Set<String> unused = ftlLabels
      .difference(projectLabels)
      .difference(ignored);

  stdout.writeln('Labels discovered: ${ftlLabels.length}');
  stdout.writeln('Labels ignored: ${ignored.length}');
  for (final i in ignored) {
    stdout.writeln('  • $i');
  }
  stdout.writeln('Labels unused: ${unused.length}');
  for (final l in unused) {
    stdout.writeln('  • $l');
  }

  // Look for labels not present in the [ftlLabels], but present in the
  // [projectLabels].
  final Set<String> missed = projectLabels
      .difference(ftlLabels)
      .difference(ignored);

  if (missed.isNotEmpty) {
    stdout.writeln();
    stdout.writeln(
      '⚠️ There seems to be ${missed.length} labels not present in `.ftl` files! ⚠️\n'
      'Be sure to check those:',
    );
    for (final l in missed.toList()..sort()) {
      stdout.writeln('  • $l');
    }
  }

  // Prevents stdout and stderr streams' outputs from mixing.
  await stdout.flush();

  if (unused.isNotEmpty) {
    stderr.writeln('\n⛔️ Unused keys are found. Remove them.');
    exit(1);
  }

  stdout.writeln('\n✅ Unused keys were not found.');
  exit(0);
}

/// Parses [path] and returns a list of all the found `.ftl` files by this path.
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

/// Parses a `.ftl` file and returns a [Set] of keys.
Future<Set<String>> _parseFtlFile(String path) async {
  final labels = <String>{};

  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Error: `.ftl` file not found: $path');
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

/// Grabs and collects all [l10n] and [l10nfmt] referenced [String]s.
class _StringLiteralCollector extends RecursiveAstVisitor<void> {
  /// [Set] of [String] literals found during visiting the node.
  final Set<String> findings = <String>{};

  @override
  void visitPropertyAccess(PropertyAccess node) {
    if (node.propertyName.name == 'l10n') {
      final target = node.target;

      if (target is SimpleStringLiteral) {
        findings.add(target.stringValue ?? '');
      } else if (target is AdjacentStrings) {
        final value = target.strings.map((s) => s.stringValue).join();
        findings.add(value);
      }
    }

    super.visitPropertyAccess(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    if (node.methodName.name == 'l10nfmt') {
      final target = node.target;

      if (target is SimpleStringLiteral) {
        findings.add(target.stringValue ?? '');
      } else if (target is AdjacentStrings) {
        findings.add(target.strings.map((s) => s.stringValue).join());
      }
    }

    super.visitMethodInvocation(node);
  }
}
