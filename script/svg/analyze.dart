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

import 'package:analyzer/dart/analysis/features.dart' show FeatureSet;
import 'package:analyzer/dart/analysis/utilities.dart' show parseFile;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Command-line utility scanning `.dart` files for unused [SvgIcons].
///
/// ### Usage examples
///
/// ```bash
/// dart run analyze.dart
/// ```
///
/// ### Exit flags
///
/// - 0, on success.
/// - 1, when unused `SvgIcons` are found.
void main() async {
  const String svgsSource = 'lib/ui/widget/svg/svgs.dart';

  // TODO: Remove when WebAssembly performance is fixed.
  final List<RegExp> ignoreRegExps = [
    'callNotCutVideo',
    'callNotCutVideoWhite',
    'callCutVideo',
    'callCutVideoWhite',
  ].map(RegExp.new).toList();

  stdout.write('Scanning `SvgIcons` class...');

  // Collect defined [SvgIcons].
  final Map<String, String> assets = _parseIcons(svgsSource);
  final Set<String> keys = assets.keys.toSet();

  stdout.writeln(' done.');

  // Collect used [SvgIcons] class properties.
  stdout.write('Scanning `SvgIcons` used...');

  // Collect project files.
  final List<File> dartFiles = await Directory('lib/')
      .list(recursive: true)
      .where(
        (file) =>
            file is File &&
            file.path.endsWith('.dart') &&
            // File containing [SvgIcons] isn't considered a Dart source file.
            file.path != svgsSource,
      )
      .cast<File>()
      .toList();

  final Set<String> icons = <String>{};
  for (final File file in dartFiles) {
    icons.addAll(_parseFile(file));
  }

  stdout.writeln(' done.');
  stdout.writeln();

  // Differentiate and report.
  final Set<String> ignored = keys
      .where((key) => ignoreRegExps.any((ignore) => ignore.hasMatch(key)))
      .toSet();

  final Set<String> unused = keys.difference(icons).difference(ignored);

  stdout.writeln('SVGs unused: ${unused.length}');
  for (final String asset in unused) {
    stdout.writeln('• SvgIcons.$asset(${assets[asset]})');
  }
  stdout.writeln();

  // Prevents stdout and stderr streams' outputs from mixing.
  await stdout.flush();

  if (unused.isNotEmpty) {
    stderr.writeln('⛔️ Unused SVGs are found. Remove them.');
    exit(1);
  }

  stdout.writeln('✅ Unused SVGs were not found.');
  exit(0);
}

/// Returns all the found [SvgIcons] in the provided [file].
Set<String> _parseFile(File file) {
  final CompilationUnit fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final _SvgIconsVisitor visitor = _SvgIconsVisitor();
  fileUnit.visitChildren(visitor);

  return visitor.properties;
}

/// Parses [SvgIcons] class and returns [Map] of properties with their assets.
Map<String, String> _parseIcons(String path) {
  final CompilationUnit unit = parseFile(
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final _SvgIconsDeclarationVisitor visitor = _SvgIconsDeclarationVisitor();
  unit.visitChildren(visitor);

  return visitor.assets;
}

/// Visitor collecting [SvgIcons] themselves.
class _SvgIconsDeclarationVisitor extends RecursiveAstVisitor<void> {
  /// [Map] of [SvgIcons] to their corresponding [String] asset.
  final Map<String, String> assets = {};

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // Look only for static constant fields, as this is how icons are defined:
    //
    // ```dart
    // static const SvgData chatAudioCall = SvgData(/* ... */);
    // ```
    if (!node.isStatic || !node.fields.isConst) {
      return;
    }

    for (final variable in node.fields.variables) {
      final String name = variable.name.lexeme;
      final Expression? initializer = variable.initializer;

      if (initializer == null) {
        continue;
      }

      // Initializer looks like comma separated parameters list:
      //
      // ```dart
      // SvgData('assets/icons/add_contact.svg', width: 21.01, height: 19.43)
      // ```
      //
      // We only are interested in the first parameter (the asset).
      assets[name] = initializer
          .toString()
          .replaceFirst('SvgData(', '')
          .split(',')
          .first;
    }

    super.visitFieldDeclaration(node);
  }
}

/// Visitor collecting accessed properties of [SvgIcons].
///
/// Example:
///
/// ```dart
/// ProfileTab.legal => const SvgIcon(SvgIcons.menuLegal),
/// ```
class _SvgIconsVisitor extends RecursiveAstVisitor {
  /// [Set] of [SvgIcons] property names found during visiting the node.
  final Set<String> properties = <String>{};

  @override
  dynamic visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'SvgIcons') {
      properties.add(node.identifier.name);
    }

    return super.visitPrefixedIdentifier(node);
  }
}
