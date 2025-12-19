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

import 'package:web/web.dart' as web;

import 'package:flutter/material.dart';

import '/util/platform_utils.dart';
import '/util/web/web_utils.dart';

/// [SafeArea] accounting possible bottom insets on iOS devices in PWA mode.
class CustomSafeArea extends StatelessWidget {
  const CustomSafeArea({
    super.key,
    this.top = true,
    this.right = true,
    this.left = true,
    this.bottom = true,
    required this.child,
  });

  /// Indicator whether to avoid system intrusions at the top of the screen.
  final bool top;

  /// Indicator whether to avoid system intrusions at the right of the screen.
  final bool right;

  /// Indicator whether to avoid system intrusions at the left of the screen.
  final bool left;

  /// Indicator whether to avoid system intrusions at the bottom of the screen.
  final bool bottom;

  /// [Widget] to wrap with [SafeArea].
  final Widget child;

  /// Indicates whether this device is considered to be running as a PWA on iOS.
  static bool get isPwa {
    return WebUtils.isPwa &&
        web.window.navigator.userAgent.contains(RegExp(r'iPhone'));
  }

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.isIOS) {
      return SafeArea(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: child,
      );
    }

    final EdgeInsets padding = EdgeInsets.fromViewPadding(
      View.of(context).viewPadding,
      View.of(context).devicePixelRatio,
    );

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        padding: padding.copyWith(bottom: isPwa ? 25 : padding.bottom),
      ),
      child: SafeArea(
        top: top,
        left: left,
        right: right,
        bottom: bottom,
        child: child,
      ),
    );
  }
}
