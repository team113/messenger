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

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:window_manager/window_manager.dart';

import '/routes.dart';
import 'web/web_utils.dart';

// TODO: Remove when jonataslaw/getx#1936 is fixed:
//       https://github.com/jonataslaw/getx/issues/1936
/// [GetPlatform] adapter that fixes incorrect [GetPlatform.isMacOS] detection.
class PlatformUtils {
  /// Indicates whether application is running in a web browser.
  static bool get isWeb => GetPlatform.isWeb;

  /// Indicates whether device's OS is macOS.
  static bool get isMacOS => WebUtils.isMacOS || GetPlatform.isMacOS;

  /// Indicates whether device's OS is Windows.
  static bool get isWindows => GetPlatform.isWindows;

  /// Indicates whether device's OS is Linux.
  static bool get isLinux => GetPlatform.isLinux;

  /// Indicates whether device's OS is Android.
  static bool get isAndroid => GetPlatform.isAndroid;

  /// Indicates whether device's OS is iOS.
  static bool get isIOS => GetPlatform.isIOS;

  /// Indicates whether device is running on a mobile OS.
  static bool get isMobile => GetPlatform.isIOS || GetPlatform.isAndroid;

  /// Indicates whether device is running on a desktop OS.
  static bool get isDesktop =>
      PlatformUtils.isMacOS || GetPlatform.isWindows || GetPlatform.isLinux;

  static bool get isPopup {
    if(isWeb) {
      return WebUtils.isPopup;
    } else {
      return router.windowId != null;
    }
  }

  /// Returns a stream broadcasting fullscreen changes.
  static Stream<bool> get onFullscreenChange {
    if (isWeb) {
      return WebUtils.onFullscreenChange;
    } else if (isDesktop) {
      StreamController<bool>? controller;

      var windowListener = _WindowListener(
        onEnterFullscreen: () => controller!.add(true),
        onLeaveFullscreen: () => controller!.add(false),
      );

      controller = StreamController<bool>(
        onListen: () => WindowManager.instance.addListener(windowListener),
        onCancel: () => WindowManager.instance.removeListener(windowListener),
      );

      return controller.stream;
    }

    // TODO: Implement for [isMobile] using the
    //       [SystemChrome.setSystemUIChangeCallback].
    return const Stream.empty();
  }

  /// Enters fullscreen mode.
  static Future<void> enterFullscreen() async {
    if (isWeb) {
      WebUtils.toggleFullscreen(true);
    } else if (isDesktop) {
      await WindowManager.instance.setFullScreen(true);
    } else if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
          overlays: []);
    }
  }

  /// Exits fullscreen mode.
  static Future<void> exitFullscreen() async {
    if (isWeb) {
      WebUtils.toggleFullscreen(false);
    } else if (isDesktop) {
      await WindowManager.instance.setFullScreen(false);

      // TODO: Remove when leanflutter/window_manager#131 is fixed:
      //       https://github.com/leanflutter/window_manager/issues/131
      Size size = await WindowManager.instance.getSize();
      await WindowManager.instance.setSize(Size(size.width + 1, size.height));
    } else if (isMobile) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual,
        overlays: SystemUiOverlay.values,
      );
    }
  }
}

/// Determining whether a [BuildContext] is mobile or not.
extension MobileExtensionOnContext on BuildContext {
  /// Returns `true` if [MediaQuery]'s width is less than `600p` on desktop and
  /// [MediaQuery]'s shortest side is less than `600p` on mobile.
  bool get isMobile => PlatformUtils.isDesktop
      ? MediaQuery.of(this).size.width < 600
      : MediaQuery.of(this).size.shortestSide < 600;
}

/// Listener interface for receiving window events.
class _WindowListener extends WindowListener {
  _WindowListener({
    required this.onLeaveFullscreen,
    required this.onEnterFullscreen,
  });

  /// Callback, called when the window exits fullscreen.
  final VoidCallback onLeaveFullscreen;

  /// Callback, called when the window enters fullscreen.
  final VoidCallback onEnterFullscreen;

  @override
  void onWindowEnterFullScreen() => onEnterFullscreen();

  @override
  void onWindowLeaveFullScreen() => onLeaveFullscreen();
}
