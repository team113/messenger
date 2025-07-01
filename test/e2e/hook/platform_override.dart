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
      print('[${DateTime.now()}] PlatformUtils now: ${PlatformUtils.runtimeType}');
      PlatformUtils = _FakePlatformUtils(
        isWeb: false,
        isMobile: false,
        isDesktop: true,
      );
      print('[${DateTime.now()}] PlatformUtils now: ${PlatformUtils.runtimeType}');
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
      print('[${DateTime.now()}] PlatformUtils now: ${PlatformUtils.runtimeType}');
    }
    return super.onAfterScenario(config, scenario, tags);
  }
}
