import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/src/dart/ast/ast.dart';

void main() {
  final svgIconsPath =
      r'/Users/ivanchabanov/prog/money/temp/messenger/lib/ui/widget/svg/svgs.dart';
  parseSvgClass(svgIconsPath);
}

Future<Map<String, String>> parseSvgClass(String path) async {
  final Map<String, String> svgAssets;

  final fileUnit = parseFile(
    path: path,
    featureSet: FeatureSet.latestLanguageVersion(),
  ).unit;

  final visitor = _DeclaredIconsCollector();
  fileUnit.visitChildren(visitor);
  svgAssets = visitor.findings;

  return svgAssets;
}

Future<Set<String>> parseProjectSvgAssets(String path) async {
  final Set<String> svgAssets;

  svgAssets = await Directory(path)
      .list(recursive: true)
      .where((file) => file is File && file.path.endsWith('.svg'))
      .map((file) => file.path)
      .toSet();

  return svgAssets;
}

class _DeclaredIconsCollector extends RecursiveAstVisitor<void> {
  final Map<String, String> findings = {};

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    // We only care about: static const SvgData <name> = SvgData(...)
    if (!node.isStatic || !node.fields.isConst) return;

    final fieldType = node.fields.type?.type;

    print('$node, $fieldType');
    super.visitFieldDeclaration(node);
  }
}
