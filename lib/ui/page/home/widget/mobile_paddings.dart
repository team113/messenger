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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/util/platform_utils.dart';
import 'app_bar.dart';
import 'navigation_bar.dart';

/// Widget used to add paddings on mobile phones to display [ListView] widgets
/// correctly.
class MobilePaddings extends StatelessWidget {
  MobilePaddings({
    super.key,
    required BuildContext context,
    required this.child,
    this.bottomPadding,
    this.borderRadius,
  }) : _mediaQuery = context.mediaQuery;

  /// Child of this widget.
  final Widget child;

  /// Specified bottom padding.
  final double? bottomPadding;

  /// [BorderRadiusGeometry] of this widget.
  final BorderRadiusGeometry? borderRadius;

  /// [MediaQueryData] of parent widget.
  late final MediaQueryData _mediaQuery;

  @override
  Widget build(BuildContext context) {
    if (PlatformUtils.isMobile && !PlatformUtils.isWeb) {
      return MediaQuery(
        data: _mediaQuery.copyWith(
          padding: _mediaQuery.padding.copyWith(
            top: CustomAppBar.height,
            bottom: bottomPadding ?? CustomNavigationBar.height + 5,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(40),
          ),
          margin: EdgeInsets.only(
            top: _mediaQuery.padding.top + 5,
            bottom: _mediaQuery.padding.bottom - CustomNavigationBar.height,
          ),
          clipBehavior: Clip.hardEdge,
          child: child,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: child,
      );
    }
  }
}
