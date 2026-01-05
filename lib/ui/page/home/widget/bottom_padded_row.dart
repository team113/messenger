// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import '/themes.dart';
import 'navigation_bar.dart';

/// [Row] padded to be at the bottom of the screen expanding its [children].
class BottomPaddedRow extends StatelessWidget {
  const BottomPaddedRow({
    super.key,
    this.children = const [],
    this.spacer = _defaultSpacer,
  });

  /// [Widget]s to put in the [Row].
  final List<Widget> children;

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
      height: CustomNavigationBar.height,
      padding: EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Column(
        children: [
          SizedBox(
            height: 56 - 18 - 6,
            child: Row(children: widgets),
          ),
          Spacer(),
        ],
      ),
    );
  }

  /// Builds a [SizedBox].
  static Widget _defaultSpacer(BuildContext _) => SizedBox(width: 10);
}
