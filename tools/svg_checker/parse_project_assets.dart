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

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

void main() async {
  // Start by defining dart files to search in.
  const String pathToSvgIcons = 'lib/ui/widget/svg/svgs.dart';
  const String rootDir = 'lib/';
  final List<File> dartFiles = await Directory(rootDir)
      .list(recursive: true)
      .where(
        (file) =>
            file is File &&
            file.path.endsWith('.dart') &&
            // Skip SvgIcons from parsing.
            file.path != pathToSvgIcons,
      )
      .cast<File>()
      .toList();

  // GET SOURCE OF TRUTH IN HELD PROJECT ASSETS:
  // (they are 432)
  final Set<String> sourceOfTruthPaths = <String>{};
  const folderPaths = ['assets/icons', 'assets/images'];
  for (final path in folderPaths) {
    final parsedAssets = await _parseFolder(path);
    sourceOfTruthPaths.addAll(parsedAssets);
  }

  // GET SOURCE OF TRUTH IN DEFINED [SvgIcons] PROPERTIES:
  // (they are 358)
  final Map<String, List<String>> sourceOfTruthProps = _parseSvgIconClass(
    pathToSvgIcons,
  );

  // FIND USED [SvgIcons] PROPERTIES.
  final Set<String> foundProps = <String>{};
  for (final file in dartFiles) {
    final Set<String> newProps = _parseSvgIconsProps(file);
    foundProps.addAll(newProps);
  }

  // Here we analyzer SvgIcons usage.
  // final sourceOfTruthPropsSet = sourceOfTruthPropsMap.keys.toSet();
  // final diff = sourceOfTruthPropsSet.difference(foundProps);
  // print('Difference: ${diff.length}');
  // for (final asset in diff) {
  //   print('  • SvgIcons.$asset');
  // }

  // let's actually abstract from SvgIcons and see what defined there.
  // Parse paths found in SvgIcons.
  final pathsDefinedInSvgIcons = <String>{};
  for (final listOfPaths in sourceOfTruthProps.values) {
    for (final path in listOfPaths) {
      pathsDefinedInSvgIcons.add(path);
    }
  }

  // Let's analyze not defined paths.
  // I believe, that most of them are dynamic.
  final pathsNotDefinedInSvgIcons = sourceOfTruthPaths.difference(
    pathsDefinedInSvgIcons,
  );

  for (final path in pathsNotDefinedInSvgIcons) {
    print(path);
  }
  // print(pathsNotDefinedInSvgIcons.length);

  // Let's see which we used in project.
  // kind of useless variable
  // final foundStaticPaths = await _findUsedSvgPaths(dartFiles);
}

/// Finds .svg paths by parsing [SimpleStringLiteral]s in [dartFiles].
Future<Set<String>> _findUsedSvgPaths(List<File> dartFiles) async {
  final Set<String> foundPaths = <String>{};
  for (final file in dartFiles) {
    final Set<String> newPaths = await _parseSvgAssets(file);
    // if (newPaths.isNotEmpty) print('${file.path} $newPaths');
    foundPaths.addAll(newPaths);
  }

  // print(foundPaths.length);
  return foundPaths;
}

/// Returns all the found [SvgIcons] properties found in [file].
Set<String> _parseSvgIconsProps(File file) {
  final fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgIconsPropsVisitor();
  fileUnit.visitChildren(visitor);
  return visitor.properties;
}

/// Returns all the [SimpleStringLiteral]s that are .svg paths in [file].
Set<String> _parseSvgAssets(File file) {
  final fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgAssetPathVisitor();
  fileUnit.visitChildren(visitor);
  return visitor.paths;
}

/// Returns mapping `propertyName -> PathsList`.
///
/// Parses specifically [SvgData] properties of [SvgIcons] class.
Map<String, List<String>> _parseSvgIconClass(String pathToClass) {
  final Map<String, List<String>> propertyToPathMap;

  final fileUnit = parseFile(
    path: pathToClass,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgIconsDeclarationVisitor();
  fileUnit.visitChildren(visitor);
  propertyToPathMap = visitor.propertyToPaths;

  return propertyToPathMap;
}

/// Visitor that parses accessed **properties**
///
/// Searches for usage of properties of [SvgIcons].
///
/// Example:
///
/// ```dart
/// ProfileTab.legal => const SvgIcon(SvgIcons.menuLegal),
/// ```
///
/// From this chunk of code collector finds [SvgIcons.menuLegal].
class _SvgIconsPropsVisitor extends RecursiveAstVisitor {
  final properties = <String>{};

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'SvgIcons') {
      properties.add(node.identifier.name);
      // print(node);
    }
    return super.visitPrefixedIdentifier(node);
  }
}

/// Visitor that parses [SimpleStringLiteral]s for .svg paths usage.
class _SvgAssetPathVisitor extends RecursiveAstVisitor<void> {
  final Set<String> paths = {};

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final value = node.value;
    if (value.endsWith('.svg') && value.contains('/')) {
      paths.add(value);
    }
    super.visitSimpleStringLiteral(node);
  }
}

/// Visitor that parses properties of the [SvgIcons] class.
///
/// Handles two patterns:
///
/// 1. Declaration of [SvgData].
/// ```dart
/// static const SvgData callTurnVideoOffWhite = SvgData(
///   'path/to/asset.svg',
///   width: n,
///   height: m,
/// );
/// ```
///
/// 2. Declaration of [List] of [SvgData].
/// ```dart
/// static const List<SvgData> head = [
///   SvgData('path/to/asset/x1.svg'),
///   ...
///   SvgData('path/to/asset/x2.svg'),
/// ];
/// ```
class _SvgIconsDeclarationVisitor extends RecursiveAstVisitor<void> {
  final Map<String, List<String>> propertyToPaths = {};

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // We only care about: static const properties.
    if (!node.isStatic || !node.fields.isConst) return;

    for (final variable in node.fields.variables) {
      // Property name.
      final name = variable.name.lexeme;

      // Dive in initializer to collect more information.
      final init = variable.initializer;

      // Initializer must exist.
      if (init == null) continue;

      /// [init.childEntities] - are tokens of initialization.
      ///
      /// For init of single SvgData
      /// ```dart
      /// static const SvgData menuSupport = SvgData(
      ///  'assets/icons/menu/help.svg',
      ///  width: 50,
      ///  height: 50,
      ///  );
      /// ```
      /// tokens are the following:
      /// ```
      /// init.childEntities[0] == SvgData
      /// init.childEntities[1] == ('assets/icons/fullscreen_enter_small.svg',
      ///                           width: 13, height: 13)
      /// ```
      ///
      /// For init of list of SvgData
      /// ```dart
      /// static const List<SvgData> head = [
      ///   SvgData('assets/images/logo/head_0.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_1.svg', width: 206.33, height: 220.68),
      ///   ...
      ///   SvgData('assets/images/logo/head_9.svg', width: 206.33, height: 220.68),
      /// ];
      /// ```
      /// tokens are the following:
      /// ```
      /// list[0]       == [
      /// list[1:N - 1] == SvgData('path_Zn.svg', width: Xn, height: Yn)
      /// list[N]       == ]
      /// ```
      final children = init.childEntities;

      for (final child in children) {
        final tokenString = child.toString();
        // We assume, that path is inside single-quotes.
        // Example: 'assets/images/logo/head_3.svg'.
        final indexStart = tokenString.indexOf("'");
        final indexEnd = tokenString.lastIndexOf("'");

        // Check for valid .svg path.
        if (indexStart != -1 && indexStart != indexEnd) {
          final path = tokenString.substring(indexStart + 1, indexEnd);
          if (!path.endsWith('.svg')) continue;

          // Safely add path to name.
          propertyToPaths.putIfAbsent(name, () => []).add(path);
        }
      }
    }

    super.visitFieldDeclaration(node);
  }
}

/// Returns a set of full file paths to `.svg` files found in [path].
Future<Set<String>> _parseFolder(String path) async {
  final dir = Directory(path);
  // Or might throw.
  if (!await dir.exists()) return {};

  final Set<String> paths = {};
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File && entity.path.toLowerCase().endsWith('.svg')) {
      paths.add(entity.path);
    }
  }

  return paths;
}
