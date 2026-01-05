// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025-2026 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

// ignore_for_file: depend_on_referenced_packages

import 'dart:async';

import 'package:build/build.dart';
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

/// Creates a new [PubspecBuilder] with the provided [BuilderOptions].
Builder pubspecBuilder(BuilderOptions options) {
  return PubspecBuilder(options);
}

/// [Builder] generating a `lib/pubspec.g.dart` file containing the package's
/// name and version.
class PubspecBuilder implements Builder {
  const PubspecBuilder(this.builderOptions);

  /// Configuration of this [PubspecBuilder].
  final BuilderOptions builderOptions;

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$package$': ['lib/pubspec.g.dart'],
  };

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    final YamlMap pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());
    final outputId = AssetId(buildStep.inputId.package, 'lib/pubspec.g.dart');

    final StringBuffer buffer = StringBuffer(
      'class Pubspec {\n'
      '  static const String name = \'${pubspec['name']}\';\n'
      '  static const String version = \'${pubspec['version']}\';\n',
    );

    final ProcessResult git = await Process.run('git', [
      'describe',
      '--tags',
      '--abbrev=0',
      '--dirty',
      '--match',
      'v*',
    ]);
    final ProcessResult rev = await Process.run('git', [
      'rev-list',
      'HEAD',
      '--count',
    ]);

    if (git.exitCode == 0 && rev.exitCode == 0) {
      String ref = git.stdout.toString();
      String count = rev.stdout.toString();

      // Strip the first `v` of the tag.
      if (ref.startsWith('v')) {
        ref = ref.substring(1);
      }

      // Strip the trailing `\n`.
      if (ref.endsWith('\n')) {
        ref = ref.substring(0, ref.length - 1);
      }
      if (count.endsWith('\n')) {
        count = count.substring(0, count.length - 1);
      }

      buffer.write('  static const String ref = \'$ref+$count\';\n');

      // ignore: avoid_print
      print('[PubspecBuilder] `Pubspec.ref` field is set to be `$ref+$count`.');
    } else {
      // TODO: Throw `Exception` instead of proceeding once any tag is released.
      // throw Exception(
      //   '[PubspecBuilder] Unable to properly generate `pubspec.g.dart` summary: `git` executable exited with code ${git.exitCode}, \nstdout: ${git.stdout}\nstderr: ${git.stderr}',
      // );

      buffer.write('  static const String ref = version;\n');
    }

    buffer.write('}\n');

    await buildStep.writeAsString(outputId, buffer.toString());
  }
}
