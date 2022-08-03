// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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
    YamlMap pubspec = loadYaml(File('pubspec.yaml').readAsStringSync());

    final outputId = AssetId(buildStep.inputId.package, 'lib/pubspec.g.dart');
    await buildStep.writeAsString(
      outputId,
      'class Pubspec {\n'
      '\tstatic const name = \'${pubspec['name']}\';\n'
      '\tstatic const version = \'${pubspec['version']}\';\n'
      '}\n',
    );
  }
}
