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

  // REPORT:
  // final foundStringPaths = await _findUsedSvgPaths(dartFiles);
  // print('${sourceOfTruthPaths.length}; ${foundStringPaths.length}');
  // print('Defined and not used: ${foundStringPaths.difference(sourceOfTruthPaths)}');


  // GET SOURCE OF TRUTH IN DEFINED [SvgIcons] PROPERTIES:
  // (they are 358)
  final Map<String, List<String>> sourceOfTruthPropsMap =
      await _parseSvgIconClass(pathToSvgIcons);
  final Set<String> sourceOfTruthPropsSet = sourceOfTruthPropsMap.keys.toSet();

  // FIND USED [SvgIcons] PROPERTIES.
  final Set<String> foundProps = <String>{};
  for (final file in dartFiles) {
    final Set<String> newProps = await _parseDartFileForProps(file);
    foundProps.addAll(newProps);
  }

  // COMPARE THOSE TWO.
  final diff = sourceOfTruthPropsSet.difference(foundProps);
  print('Difference: ${diff.length}');
}

/// Finds .svg paths by parsing [SimpleStringLiteral]s in [dartFiles].
Future<Set<String>> _findUsedSvgPaths(List<File> dartFiles) async {
  final Set<String> foundPaths = <String>{};
  for (final file in dartFiles) {
    final Set<String> newPaths = await _parseDartFileForStrings(file);
    // if (newPaths.isNotEmpty) print('${file.path} $newPaths');
    foundPaths.addAll(newPaths);
  }

  // print(foundPaths.length);
  return foundPaths;
}

/// Returns all the found [SvgIcons] properties found in [file].
Future<Set<String>> _parseDartFileForProps(File file) async {
  final fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgIconUsageCollector();
  fileUnit.visitChildren(visitor);
  return visitor.hits;
}

/// Returns all the [SimpleStringLiteral]s that are .svg paths in [file].
Future<Set<String>> _parseDartFileForStrings(File file) async {
  final fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgLiteralCollector();
  fileUnit.visitChildren(visitor);
  return visitor.hits;
}

/// Searches for usage of properties of [SvgIcons].
///
/// Example:
///
/// ```dart
/// ProfileTab.legal => const SvgIcon(SvgIcons.menuLegal),
/// ```
///
/// From this chunk of code collector finds [SvgIcons.menuLegal].
class _SvgIconUsageCollector extends RecursiveAstVisitor {
  final hits = <String>{};

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'SvgIcons') {
      hits.add(node.identifier.name);
      // print(node);
    }
    return super.visitPrefixedIdentifier(node);
  }
}

/// Searches for usage of .svg paths within [SimpleStringLiteral]s.
class _SvgLiteralCollector extends RecursiveAstVisitor<void> {
  final Set<String> hits = {};

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final value = node.value;
    if (value.endsWith('.svg') && value.length > '.svg'.length) {
      hits.add(value);
    }
    super.visitSimpleStringLiteral(node);
  }
}

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

/// Returns mapping of names of properties to list of paths.
///
/// Examples:
/// `propertyToPathMap[head] == [assets/images/logo/head_0.svg, assets/...]`
/// `propertyToPathMap[other] == [_some_aset.svg]`
///
/// Parses specifically [SvgData] properties of [SvgIcons] class.
Future<Map<String, List<String>>> _parseSvgIconClass(String pathToClass) async {
  final Map<String, List<String>> propertyToPathMap;

  final fileUnit = parseFile(
    path: pathToClass,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _DeclaredIconsCollector();
  fileUnit.visitChildren(visitor);
  propertyToPathMap = visitor.findingsMap;

  return propertyToPathMap;
}

/// Visitor for [SvgIcons] class.
class _DeclaredIconsCollector extends RecursiveAstVisitor<void> {
  final Map<String, List<String>> findingsMap = {};
  final Set<String> foundProperties = {};
  int _counter = 1;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // We only care about: static const properties.
    if (!node.isStatic || !node.fields.isConst) return;

    for (final variable in node.fields.variables) {
      // Field name.
      final name = variable.name.lexeme;

      // In order to find out the string, dive in init.
      final init = variable.initializer;

      // initializer must exist.
      if (init == null) continue;

      // Instantly add list to map.
      foundProperties.add(name);

      /// What are children? Children are tokens of initialization.
      ///
      /// For example,
      /// static const SvgData menuSupport = SvgData(
      ///  'assets/icons/menu/help.svg',
      ///  width: 50,
      ///  height: 50,
      ///  );
      ///
      /// for this tokens are the following:
      /// list[0] == SvgData
      /// list[1] == ('assets/icons/fullscreen_enter_small.svg', width: 13, height: 13)
      ///
      /// We also have list. for it
      ///
      /// static const List<SvgData> head = [
      ///   SvgData('assets/images/logo/head_0.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_1.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_2.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_3.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_4.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_5.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_6.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_7.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_8.svg', width: 206.33, height: 220.68),
      ///   SvgData('assets/images/logo/head_9.svg', width: 206.33, height: 220.68),
      /// ];
      ///
      /// for it something like this:
      /// list[0]       == [
      /// list[1:N - 1] == SvgData('path.svg', width: x, height: y)
      /// list[N]       == ]
      final children = init.childEntities;
      for (final child in children) {
        final tokenString = child.toString();
        final indexStart = tokenString.indexOf("'");
        final indexEnd = tokenString.lastIndexOf("'");

        // Check whether string results in a .svg path.
        if (indexStart != -1 && indexStart != indexEnd) {
          final path = tokenString.substring(indexStart + 1, indexEnd);

          // Sanity check.
          if (!path.endsWith('.svg')) continue;

          // Safely add path to name.
          findingsMap.putIfAbsent(name, () => []).add(path);
        }
      }
    }

    super.visitFieldDeclaration(node);
  }
}
