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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/routes.dart';
import '/themes.dart';
import '/util/platform_utils.dart';
import 'navigation_bar.dart';

/// [Row] padded to be at the bottom of the screen expanding its [children].
class BottomPaddedRow extends StatelessWidget {
  const BottomPaddedRow({
    super.key,
    this.children = const [],
    this.height = CustomNavigationBar.height,
    this.spacer = _defaultSpacer,
  });

  /// [Widget]s to put in the [Row].
  final List<Widget> children;

  /// Height of this [BottomPaddedRow].
  final double? height;

  /// Builder building spacing between [children].
  final Widget Function(BuildContext) spacer;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final List<Widget> widgets = [];

    for (int i = 0; i < children.length; ++i) {
      widgets.add(Expanded(child: children[i]));

      if (i < children.length - 1) {
        widgets.add(spacer(context));
      }
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: style.colors.onPrimary,
        boxShadow: [
          CustomBoxShadow(
            blurRadius: 8,
            color: style.colors.onBackgroundOpacity13,
            blurStyle: BlurStyle.outer.workaround,
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        8,
        12,
        8,
        PlatformUtils.isMobile && !PlatformUtils.isWeb
            ? router.context!.mediaQuery.padding.bottom + 7
            : 12,
      ),
      child: Row(children: widgets),
    );
  }

  /// Builds a [SizedBox].
  static Widget _defaultSpacer(BuildContext _) => SizedBox(width: 10);
}
