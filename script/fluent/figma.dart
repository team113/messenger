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

/// Command-line utility splitting `.csv` files into separate `.ftl` labels.
///
/// Expected format is `Key,Type,English,Russian,Spanish` for CSV.
Future<void> main(List<String> args) async {
  final List<String> rows = await parse(File('input.csv'));
  final Map<String, Map<String, String>> languages = {
    'en': {},
    'ru': {},
    'es': {},
  };

  for (var row in rows) {
    final values = parseRow(row);

    // Key,Type,English,Russian,Spanish
    languages['en']?[values[0]] = values[2];
    languages['ru']?[values[0]] = values[3];
    languages['es']?[values[0]] = values[4];
  }

  for (var language in languages.entries) {
    final StringBuffer buffer = StringBuffer();
    final List<MapEntry<String, String>> entries = language.value.entries
        .toList();
    entries.sort((a, b) {
      return a.key.compareTo(b.key);
    });

    for (var entry in entries) {
      buffer.write('${entry.key} =');

      final List<String> split = entry.value.split('\n');
      if (split.length == 1) {
        buffer.write(' ${split.first}\n');
      } else {
        buffer.write(' ${split.first}\n');
        for (int i = 1; i < split.length; ++i) {
          String value = split[i];

          if (value.startsWith('. ')) {
            value = '{"."} ${value.substring(2)}';
          }

          if (value == '.') {
            value = '{"."}';
          }

          if (!value.startsWith(' ')) {
            value = '    $value';
          }

          buffer.writeln(value);
        }
      }
    }

    final File output = File('${language.key}.ftl');
    await output.writeAsString(buffer.toString());
  }
}

/// Splits the contents of [input] to a [List] of values for each row.
Future<List<String>> parse(File input) async {
  final List<String> result = [];
  final List<String> lines = await input.readAsLines();

  final buffer = StringBuffer();
  var insideQuotes = false;

  for (var line in lines) {
    final quoteCount = '"'.allMatches(line).length;

    if (buffer.isNotEmpty) buffer.writeln();
    buffer.write(line);

    if (quoteCount.isOdd) {
      insideQuotes = !insideQuotes;
    }

    if (!insideQuotes) {
      result.add(buffer.toString());
      buffer.clear();
    }
  }

  if (buffer.isNotEmpty) {
    result.add(buffer.toString());
  }

  return result;
}

/// Parses the provided [row] and returns the [List] of values.
///
/// Expected row format is: `Key,Type,English,Russian,Spanish`.
List<String> parseRow(String row) {
  final result = <String>[];
  final buffer = StringBuffer();
  var insideQuotes = false;

  for (var i = 0; i < row.length; i++) {
    final char = row[i];

    if (char == '"') {
      final isEscapedQuote = i + 1 < row.length && row[i + 1] == '"';
      if (isEscapedQuote) {
        buffer.write('"');
        i++;
      } else {
        insideQuotes = !insideQuotes;
      }
    } else if (char == ',' && !insideQuotes) {
      result.add(buffer.toString());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }

  result.add(buffer.toString());

  return result.map((v) => v.trim()).toList();
}
