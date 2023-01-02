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

/// Custom stylized and decorated [AppBar].
class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    Key? key,
    this.title,
    this.leading = const [],
    this.actions = const [],
    this.padding,
    this.background,
    this.border,
  }) : super(key: key);

  /// Primary centered [Widget] of this [CustomAppBar].
  final Widget? title;

  /// [Widget]s displayed in a row before the [title].
  final List<Widget> leading;

  /// [Widget]s displayed in a row after the [title].
  final List<Widget> actions;

  /// Padding to apply to the contents.
  final EdgeInsets? padding;

  final Border? border;
  final Color? background;

  @override
  Size get preferredSize => const Size(double.infinity, 60);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final double top = MediaQuery.of(context).padding.top;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (top != 0)
          Container(
            height: top,
            width: double.infinity,
            color: Colors.white,
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                borderRadius: style.cardRadius,
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
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    borderRadius: style.cardRadius,
                    border: border ?? style.cardBorder,
                    color: background ?? style.cardColor,
                  ),
                  padding: padding,
                  child: Row(
                    children: [
                      ...leading,
                      Expanded(
                        child: DefaultTextStyle.merge(
                          style: Theme.of(context).appBarTheme.titleTextStyle,
                          child:
                              Center(child: title ?? const SizedBox.shrink()),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
