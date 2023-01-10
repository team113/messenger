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

class ListWrapper extends StatelessWidget {
  ListWrapper({
    super.key,
    required BuildContext context,
    required this.child,
    this.bottomPadding,
  }) : _mediaQuery = context.mediaQuery;

  final Widget child;

  final double? bottomPadding;

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
        child: Padding(
          padding: EdgeInsets.only(
            top: _mediaQuery.padding.top + 5,
            bottom: _mediaQuery.padding.bottom - CustomNavigationBar.height,
          ),
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
