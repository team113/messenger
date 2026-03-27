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

import 'dart:convert';
import 'dart:io';

/// Converts the provided `.csv` [File] to a three `.ftl` files: `en_US`,
/// `ru_RU` and `es_ES`.
void main(List<String> arguments) async {
  String command = '';
  String input = 'translations.csv';
  String output = '';

  for (int i = 0; i < arguments.length; ++i) {
    final String argument = arguments[i];

    if (argument == '--help' || argument == '-h') {
      help();
      return;
    } else if (argument.startsWith('--input=')) {
      input = argument.substring('--input='.length);
    } else if (argument.startsWith('--output=')) {
      output = argument.substring('--output='.length);
    } else if (argument == '-i' ||
        argument == '--input' ||
        argument == '-o' ||
        argument == '--output') {
      command = argument;
    } else {
      if (command == '-i' || command == '--input') {
        input = argument;
        command = '';
      } else if (command == '-o' || command == '--output') {
        output = argument;
        command = '';
      } else {
        stderr.writeln('Unknown argument: `$argument`');
        exit(64); // EX_USAGE
      }
    }
  }

  if (input.startsWith('"') && input.endsWith('"')) {
    input = input.substring(1, input.length - 1);
  }

  final File inputFile = File(input);
  final String content = await inputFile.readAsString();

  final List<List<String>> rows = parseCsv(content);

  final StringBuffer en = StringBuffer();
  final StringBuffer ru = StringBuffer();
  final StringBuffer es = StringBuffer();

  for (final row in rows) {
    if (row.length < 5) continue;

    final String key = row[1].trim();
    final String enText = row[2];
    final String ruText = row[3];
    final String esText = row[4];

    writeFtlEntry(en, key, enText);
    writeFtlEntry(ru, key, ruText);
    writeFtlEntry(es, key, esText);
  }

  await File('${output}en_US.ftl').writeAsString(en.toString());
  await File('${output}ru_RU.ftl').writeAsString(ru.toString());
  await File('${output}es-ES.ftl').writeAsString(es.toString());

  stdout.writeln('FTL files generated!');
}

/// Adds a formatted `.ftl` [key]-[value] pair to the provided [buffer].
void writeFtlEntry(StringBuffer buffer, String key, String value) {
  final List<String> lines = const LineSplitter().convert(value);

  if (lines.length == 1) {
    buffer.writeln('$key = ${lines[0]}');
  } else {
    buffer.writeln('$key =');
    for (final line in lines) {
      buffer.writeln('    $line');
    }
  }
}

/// Parses CSV files and handles quoted newlines and commas.
List<List<String>> parseCsv(String input) {
  final List<List<String>> rows = <List<String>>[];
  final List<String> fields = <String>[];
  final StringBuffer sb = StringBuffer();

  bool inQuotes = false;
  int i = 0;

  while (i < input.length) {
    final char = input[i];

    if (inQuotes) {
      if (char == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = false;
        }
      } else {
        sb.write(char);
      }
    } else {
      if (char == '"') {
        inQuotes = true;
      } else if (char == ',') {
        fields.add(sb.toString());
        sb.clear();
      } else if (char == '\n' || char == '\r') {
        // Handle \r\n and \n line endings.
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') i++;
        fields.add(sb.toString());
        sb.clear();
        if (fields.any((f) => f.trim().isNotEmpty)) {
          rows.add(List.from(fields));
        }
        fields.clear();
      } else {
        sb.write(char);
      }
    }

    i++;
  }

  // Add last row.
  if (sb.isNotEmpty || fields.isNotEmpty) {
    fields.add(sb.toString());
    if (fields.any((f) => f.trim().isNotEmpty)) {
      rows.add(fields);
    }
  }

  return rows;
}

/// Prints help to [stdout].
void help() {
  stdout.writeln(
    'Converts .CSV files to .FTL (Fluent) files.\n'
    '\n'
    '.CSV file must have a format of:\n'
    'localization_key,english_translation,russian_translation,spanish_translation\n'
    '\n'
    '.CSV files may have spaces, newlines, etc.\n'
    '\n'
    'Usage example: dart csv_to_ftl.dart [arguments]\n'
    '\n'
    'Options:\n'
    '  -i, --input   Specify .csv input file.\n'
    '  -o, --output  Specify directory to output .ftl files to.',
  );
}
