import 'package:gherkin/gherkin.dart';
import 'package:messenger/util/platform_utils.dart';

import '../mock/platform_utils.dart';

/// Mocked [PlatformUtilsImpl] to use platform as Desktop.
class _FakePlatformUtils extends PlatformUtilsMock {
  _FakePlatformUtils({
    required this.isWeb,
    required this.isDesktop,
    required this.isMobile,
  });

  @override
  final bool isWeb;
  @override
  final bool isDesktop;
  @override
  final bool isMobile;
}

/// [Hook] overriding platform by tags for test.
class PlatformOverrideHook extends Hook {
  @override
  int get priority => 2;

  /// [Tag] corresponding to Desktop.
  static const _desktopTag = '@desktop';

  /// Real [PlatformUtilsImpl] that are going to be put after tests.
  late PlatformUtilsImpl _saved;

  /// Indicates whether tags contain our tag or not.
  bool _hasDesktopTag(Iterable<Tag> tags) =>
      tags.any((tag) => tag.name == _desktopTag);

  @override
  Future<void> onBeforeScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) async {
    if (_hasDesktopTag(tags)) {
      _saved = PlatformUtils;
      PlatformUtils = _FakePlatformUtils(
        isWeb: false,
        isMobile: false,
        isDesktop: true,
      );
    }
    return super.onBeforeScenario(config, scenario, tags);
  }

  @override
  Future<void> onAfterScenario(
    TestConfiguration config,
    String scenario,
    Iterable<Tag> tags,
  ) {
    if (_hasDesktopTag(tags)) {
      PlatformUtils = _saved;
    }
    return super.onAfterScenario(config, scenario, tags);
  }
}
