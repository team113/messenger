import 'dart:async';

import 'package:build/build.dart';
import 'package:universal_io/io.dart';
import 'package:yaml/yaml.dart';

/// Returns the [PubspecBuilder].
Builder pubspecBuilder(BuilderOptions options) {
  return PubspecBuilder(options);
}

/// [Builder] generating a `lib/pubspec.g.dart` file containg the package's name
/// and version.
class PubspecBuilder implements Builder {
  PubspecBuilder(this.builderOptions);

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
