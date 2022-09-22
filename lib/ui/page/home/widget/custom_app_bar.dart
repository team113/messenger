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

import 'dart:ui';

import 'package:flutter/material.dart';

import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';

/// Custom beautiful app bar.
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    Key? key,
    this.title,
    this.leading,
    this.actions,
    this.padding,
  }) : super(key: key);

  /// Primary widget displayed in the app bar.
  final Widget? title;

  /// Widgets to display before the toolbar's [title].
  final List<Widget>? leading;

  /// Widgets to display in a row after the [title] widget.
  final List<Widget>? actions;

  /// [EdgeInsets] in app bar.
  final EdgeInsets? padding;

  @override
  Size get preferredSize => const Size(double.infinity, 60);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          border: style.cardBorder,
          boxShadow: const [
            CustomBoxShadow(
              blurRadius: 8,
              color: Color(0x22000000),
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
        child: ConditionalBackdropFilter(
          condition: style.cardBlur > 0,
          filter: ImageFilter.blur(
            sigmaX: style.cardBlur,
            sigmaY: style.cardBlur,
          ),
          borderRadius: style.cardRadius,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              color: style.cardColor,
            ),
            padding: padding,
            child: Row(
              children: [
                if (leading != null) ...leading!,
                Expanded(
                  child: DefaultTextStyle.merge(
                    style: Theme.of(context).appBarTheme.titleTextStyle,
                    child: Center(child: title ?? const SizedBox.shrink()),
                  ),
                ),
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
