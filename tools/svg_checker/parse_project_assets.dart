import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

void main() async {

  // PARSE strings:

  // First of all, let's get all the assets in our project.
  //
  // Collects the paths of ALL the assets we hold in project
  final Set<String> heldSVGs = <String>{};

  // Let's append it.
  const folderPaths = ['assets/icons', 'assets/images'];
  for (final path in folderPaths) {
    final parsedAssets = await _parseFolder(path);
    heldSVGs.addAll(parsedAssets);
  }

  // We got all the objects, nice.

  /// Second step:
  /// We have to parse IconsSVG class to build a collection of defined paths
  /// in there.

  /// Example of entry:
  /// Map[SvgIcons.callIncomingAudioOn] = 'assets/icons/speaker_on.svg'
  ///
  /// Hence, we would check for `SvgIcons.callIncomingAudioOn` usage, but not
  /// `assets/icons/speaker_on.svg`. Although, we might have some sort of
  /// counter, that would both be mentioning if addressed via path or property.
  const pathToSvgIcons = 'lib/ui/widget/svg/svgs.dart';
  // final Map<String, String> propertyToPathMap = await _parseSvgIconClass(
  //   pathToSvgIcons,
  // );
  final Set<String> properties = await _parseSvgIconClass(pathToSvgIcons);
  print(properties.length);

  // Now we have a set of properties. Let's collect set of properties of
  // SvgIcons used in .dart files.

  /// PARSE PROPS:
  const String rootDir = 'lib/';
  final List<File> dartFiles = await Directory(rootDir)
      .list(recursive: true)
      .where((file) => file is File && file.path.endsWith('.dart'))
      .cast<File>()
      .toList();
  final Set<String> foundProperties = <String>{};
  final Set<String> foundPaths = <String>{};

  // ATTENTION! HERE WE PARSE BOTH VISITORS!
  for (final file in dartFiles) {
    final foundProps = await _parseDartFileForProps(file);
    Set<String> paths = {};
    if (file.path != pathToSvgIcons) {
      // can not parse since fake.
      paths = await _parseDartFileForStrings(file);
    }
    foundProperties.addAll(foundProps);
    foundPaths.addAll(paths);
  }


  // REPORT:
  final unusedProps = properties.difference(foundProperties);
  final unusedPaths = heldSVGs.difference(foundPaths);
  print('YOU HAVE ${unusedProps.length} UNUSED PROPS!');
  for (final prop in unusedProps) {
    print('  * $prop');
  }
  print('UNUSED PATHS: ${unusedPaths.length}');
}

Future<Set<String>> _parseDartFileForProps(File file) async {
  final fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgIconUseCollector();
  fileUnit.visitChildren(visitor);
  return visitor.hits;
}

class _SvgIconUseCollector extends RecursiveAstVisitor {
  final hits = <String>{};

  @override
  visitPrefixedIdentifier(PrefixedIdentifier node) {
    if (node.prefix.name == 'SvgIcons') {
      hits.add(node.identifier.name);
    }
    return super.visitPrefixedIdentifier(node);
  }
}

Future<Set<String>> _parseDartFileForStrings(File file) async {
  final fileUnit = parseFile(
    path: file.path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _SvgLiteralCollector();
  fileUnit.visitChildren(visitor);
  return visitor.hits;
}

class _SvgLiteralCollector extends RecursiveAstVisitor<void> {
  final Set<String> hits = {};

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    final value = node.value;
    if (value.toLowerCase().endsWith('.svg')) {
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

/// Parses specifically [SvgIcons] class with [SvgData] properties.
Future<Set<String>> _parseSvgIconClass(String pathToClass) async {
  final Map<String, String> propertyToPathMap;
  final Set<String> propertiesNames;

  final fileUnit = parseFile(
    path: pathToClass,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _DeclaredIconsCollector();
  fileUnit.visitChildren(visitor);
  propertiesNames = visitor.foundProperties;

  return propertiesNames;
}

/// We might return both `Set<String>` or `Map<String, String>` in this case.
///
/// What should we return?
///
/// If we only care about simple property usage, then it is okay
/// to use Set. But, for more detailed analysis (maybe {}.diff with defined)
/// we could use Map.
///
/// For now I will return Set, since there are lists in it
/// but might go for Map in the future (KISS).
///
/// OUTDATED: Should be map since if not - then impossible to delete file.
class _DeclaredIconsCollector extends RecursiveAstVisitor<void> {
  final Map<String, String> findings = {};
  final Set<String> foundProperties = {};
  int _counter = 1;

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // We only care about: static const properties.
    // Btw, there are both SvgData and List<SvgData>
    if (!node.isStatic || !node.fields.isConst) return;

    for (final variable in node.fields.variables) {
      // Field name.
      final name = variable.name.lexeme;
      foundProperties.add(name);

      // In order to find out the string, dive in init.
      // final init = variable.initializer;
      // // late values are not allowed.
      // if (init == null) continue;

      // if (true) {
      //   print('object, ${_counter++}, ${init.runtimeType}');
      // }

      // print('\n$init');
      // print(init.runtimeType);
      // print(init)
    }
    super.visitFieldDeclaration(node);
  }
}
