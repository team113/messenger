import 'dart:io';

import 'package:analyzer/dart/analysis/features.dart' show FeatureSet;
import 'package:analyzer/dart/analysis/utilities.dart' show parseFile;

import 'ftl_labels_collector.dart';
import 'source_ftl_label_parser.dart';

void main() async {
  // PARSE SOURCE FTL FILE TO COLLECT LABELS.
  final Set<String> sourceFtlLabels;
  try {
    final sourceFtlFilePath =
        "/Users/ivanchabanov/prog/money/temp/labels_checker/lib/en-US.ftl";
    sourceFtlLabels = await parseFtlFile(sourceFtlFilePath);
  } catch (e) {
    stderr.writeln('Failed to parse .ftl labels: $e');
    exit(1);
  }

  // GET FILES TO ANALYZE.
  final dirPath = "/Users/ivanchabanov/prog/money/temp/messenger/lib";
  final directory = Directory(dirPath);
  final dartFiles = await directory
      .list(recursive: true)
      .where((file) => file is File && file.path.endsWith('.dart'))
      .toList();
  
  if (dartFiles.isEmpty) {
    stderr.writeln('Failed to collect project files');
    exit(1);
  }

  // PARSE OTHER FILES TO COLLECT USED LABELS.
  final Set<String> collectedFtlLabels = <String>{};

  for (final file in dartFiles) {
    final fileUnit = parseFile(
      path: file.path,
      featureSet: FeatureSet.latestLanguageVersion(),
    ).unit;

    // Parse file's tree.
    final newVisitor = FtlLabelsCollector();
    fileUnit.visitChildren(newVisitor);

    // Parse gotten labels.
    final caughtLabels = newVisitor.getAllLabels();
    collectedFtlLabels.addAll(caughtLabels);
  }

  print(sourceFtlLabels.difference(collectedFtlLabels).length);
}
