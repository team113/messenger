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

import 'dart:ui';

import 'package:gherkin/gherkin.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:messenger/util/web/web.dart';

import '../mock/platform_utils.dart';
import '../mock/window_manager_stub.dart';

/// Mocked [PlatformUtilsImpl] to use platform as Desktop on Web.
///
/// * Forces desktop code path (`isDesktop == true`)
/// * Never calls plugins such as `WindowManager`
class _FakeDesktopPlatformUtils extends PlatformUtilsMock {
  @override
  bool get isWeb => false;
  @override
  bool get isDesktop => true;

  /// Returns Web version of isFocused.
  @override
  Future<bool> get isFocused async => WebUtils.isFocused;

  /// Returns Web version of focusChanged.
  @override
  Stream<bool> get onFocusChanged => WebUtils.onFocusChanged;

  /// Returns Web version of onFullscreenChange.
  @override
  Stream<bool> get onFullscreenChange => WebUtils.onFullscreenChange;

  /// Calls Web version of enterFullscreen
  @override
  Future<void> enterFullscreen() async {
    WebUtils.toggleFullscreen(true);
  }

  // Calls Web version of exitFullscreen
  @override
  Future<void> exitFullscreen() async {
    WebUtils.toggleFullscreen(false);
  }

  /// Returns empty stream to not trigger [WindowManager].
  @override
  Stream<Offset> get onMoved => const Stream.empty();
}

/// [Hook] overriding platform for test.
///
/// Uses tags to identify platform.
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
      registerWindowManagerStub();
      _saved = PlatformUtilsMock();
      print('[${DateTime.now()}] 1. onBefore: PlatformUtils now: ${PlatformUtils.runtimeType}');
      PlatformUtils = _FakeDesktopPlatformUtils();
      print('[${DateTime.now()}] 2. onBefore: PlatformUtils now: ${PlatformUtils.runtimeType}');
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
      print(
        '[${DateTime.now()}] 1. onAfterScenario: PlatformUtils now: ${PlatformUtils.runtimeType}',
      );
      PlatformUtils = _saved;
      print(
        '[${DateTime.now()}] 2. onAfterScenario: PlatformUtils now: ${PlatformUtils.runtimeType}',
      );
    }
    return super.onAfterScenario(config, scenario, tags);
  }
}
