import 'dart:io';

void main() {
  parseProjectSvgAssets('assets');
}

Future<Set<String>> parseSvgClass(String path) async {
  final Set<String> svgAssets;

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
