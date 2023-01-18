// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC,
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

import 'package:flutter/material.dart';

import '/routes.dart';
import '/util/platform_utils.dart';
import 'app_bar.dart';
import 'navigation_bar.dart';

/// [Widget] adding [MediaQueryData.padding] and clipping to its [child]
/// accounting [CustomAppBar.height] and [CustomNavigationBar.height].
///
/// Padding and clipping are only applied on mobile non-Web platforms.
class SafeScrollbar extends StatelessWidget {
  const SafeScrollbar({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.borderRadius,
    this.controller,
  });

  /// Indicator whether to avoid system intrusions on the top side of the
  /// screen.
  final bool top;

  /// Indicator whether to avoid system intrusions on the bottom side of the
  /// screen.
  final bool bottom;

  /// [BorderRadius] to clip the [child] with.
  final BorderRadius? borderRadius;

  /// Optional [ScrollController], used in a [Scrollbar].
  ///
  /// If `null`, then no [Scrollbar] is applied.
  final ScrollController? controller;

  /// [Widget] to add padding and clipping to.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!PlatformUtils.isMobile || PlatformUtils.isWeb) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: child,
      );
    }

    final EdgeInsets padding = EdgeInsets.fromWindowPadding(
      window.viewPadding,
      window.devicePixelRatio,
    );

    return MediaQuery(
      data: MediaQuery.of(router.context!).copyWith(
        padding: padding.copyWith(
          top: top ? CustomAppBar.height : 0,
          bottom: bottom ? CustomNavigationBar.height + 5 : 0,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: borderRadius ?? BorderRadius.circular(40),
        ),
        margin: EdgeInsets.only(
          top: top ? padding.top + 5 : 0,
          bottom: bottom ? padding.bottom + 5 : 0,
        ),
        clipBehavior: Clip.hardEdge,
        child: controller == null
            ? child
            : Scrollbar(controller: controller, child: child),
      ),
    );
  }
}
