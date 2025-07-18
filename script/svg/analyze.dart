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

import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart' show FeatureSet;
import 'package:analyzer/dart/analysis/utilities.dart' show parseFile;
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

/// Command-line utility scanning `.dart` files for unused [SvgIcons]
/// properties.
///
/// ### Exit flags
///
/// - 0, on success.
/// - 1, when unused properties are found.
void main() async {
  const String pathToSvgIcons = 'lib/ui/widget/svg/svgs.dart';
  const String rootDir = 'lib/';

  // Collect project files.
  final List<File> dartFiles = await Directory(rootDir)
      .list(recursive: true)
      .where(
        (file) =>
            file is File &&
            file.path.endsWith('.dart') &&
            // SvgIcons file is collected separately.
            file.path != pathToSvgIcons,
      )
      .cast<File>()
      .toList();

  // Collect defined [SvgIcons] class properties.
  stdout.write('Scanning `SvgIcons` class...');

  final Map<String, List<String>> svgIconsPropsMap = _parseSvgIconsClass(
    pathToSvgIcons,
  );
  final Set<String> definedSvgIconsProps = svgIconsPropsMap.keys.toSet();

  stdout.writeln(' done.');

  // Collect used [SvgIcons] class properties.
  stdout.write('Scanning `SvgIcons` properties used...');

  final Set<String> usedSvgIconsProps = <String>{};
  for (final file in dartFiles) {
    final Set<String> newProps = _parseSvgIconsUsedProps(file);
    usedSvgIconsProps.addAll(newProps);
  }

  stdout.writeln(' done.');
  stdout.writeln();

  // Differentiate and report.
  final unused = definedSvgIconsProps.difference(usedSvgIconsProps);

  stdout.writeln('Properties unused: ${unused.length}');
  for (final asset in unused) {
    final svgPaths = svgIconsPropsMap[asset]!;
    final type = svgPaths.length > 1 ? 'List<SvgData>' : 'SvgData';

    stdout.writeln('  • SvgIcons.$asset ($type $asset)');

    for (final svgPath in svgPaths) {
      stdout.writeln('    - $svgPath');
    }
  }

  stdout.writeln();

  // Prevents stdout and stderr streams' outputs from mixing.
  await stdout.flush();

  if (unused.isNotEmpty) {
    stderr.writeln('⛔️ Unused properties are found. Remove them.');
    exit(1);
  }

  stdout.writeln('\n✅ Unused properties were not found.');
  exit(0);
}

/// Returns all the found [SvgIcons] properties found in [file].
Set<String> _parseSvgIconsUsedProps(File file) {
  final fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgIconsPropsVisitor();
  fileUnit.visitChildren(visitor);
  return visitor.properties;
}

/// Parses [SvgIcons] class and returns [Map] of property names to `.svg`
/// paths.
Map<String, List<String>> _parseSvgIconsClass(String path) {
  final fileUnit = parseFile(
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgIconsDeclarationVisitor();
  fileUnit.visitChildren(visitor);
  return visitor.propertyToPaths;
}

/// Visitor collecting properties of the [SvgIcons] class.
///
/// Handles two patterns:
///
/// 1. Declaration of [SvgData]:
/// ```dart
/// static const SvgData callTurnVideoOffWhite = SvgData(
///   'path/to/asset.svg',
///   width: x,
///   height: y,
/// );
/// ```
///
/// 2. Declaration of [List] of [SvgData]:
/// ```dart
/// static const List<SvgData> head = [
///   SvgData('path/to/asset/x1.svg'),
///   ...
///   SvgData('path/to/asset/x2.svg'),
/// ];
/// ```
class _SvgIconsDeclarationVisitor extends RecursiveAstVisitor<void> {
  /// [Map] associating property name from [SvgIcons] with their `.svg` asset
  /// paths.
  ///
  /// The paths list contains one entry for a single [SvgData] declaration,
  /// multiple entries for a [List] of [SvgData].
  final Map<String, List<String>> propertyToPaths = {};

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    if (!node.isStatic || !node.fields.isConst) return;

    for (final variable in node.fields.variables) {
      final propertyName = variable.name.lexeme;
      final propertyInit = variable.initializer;

      if (propertyInit == null) continue;

      // Syntactic elements of the property's init expression.
      //
      // When parsing an init like `x = SvgData(...)`, the child entities will
      // be the type (`SvgData`) and its arguments list (`(...)`). For a list,
      // they will be the brackets and the elements within then.
      final children = propertyInit.childEntities;

      for (final child in children) {
        final tokenString = child.toString();
        // Assume path is inside single-quotes.
        // Example: 'assets/images/logo/head_3.svg'.
        final indexStart = tokenString.indexOf("'");
        final indexEnd = tokenString.lastIndexOf("'");

        // Check for valid .svg path.
        if (indexStart != -1 && indexStart != indexEnd) {
          // Both ends are exclusive to trim quotes.
          final path = tokenString.substring(indexStart + 1, indexEnd);
          if (!path.endsWith('.svg')) continue;

          // Safely map property name to path.
          propertyToPaths.putIfAbsent(propertyName, () => []).add(path);
        }
      }
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
///
/// From this chunk of code visitor collects `menuLegal`.
class _SvgIconsPropsVisitor extends RecursiveAstVisitor {
  /// [Set] of [SvgIcons] property names found during visiting the node.
  final Set<String> properties = <String>{};

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    final prefixName = node.prefix.name;
    final propertyName = node.identifier.name;

    if (prefixName == 'SvgIcons') {
      properties.add(propertyName);
    }

    return super.visitPrefixedIdentifier(node);
  }
}
