import 'dart:convert';
import 'dart:io';

const int _copyrightLinesLen = 17;

Future<Set<String>> parseFtlFile(String path) async {
  // Labels of .ftl file.
  final labels = <String>{};

  final file = File(path);
  if (!await file.exists()) {
    stderr.writeln('Error: file not found on path: $path');
    exit(1);
  }

  try {
    // Read lines async.
    final Stream<String> rawLinesStream = file
        .openRead()
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    // Skip COPYRIGHT.
    final linesStream = rawLinesStream.skip(_copyrightLinesLen);

    // Process the lines.
    await for (final String line in linesStream) {
      final index = line.indexOf(' =');
      if (index == -1) continue;

      final label = line.substring(0, index);
      labels.add(label);
    }
  } on FileSystemException catch (e) {
    stderr.writeln('I/O error: ${e.message}');
  } catch (e) {
    stderr.writeln('Unexpected error: $e');
  }

  return labels;
}
