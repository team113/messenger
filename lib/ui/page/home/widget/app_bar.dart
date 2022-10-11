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

/// Decorated [PreferredSize] [Widget] with provided [leading] and [actions].
abstract class CustomAppBar {
  static PreferredSizeWidget from({
    Key? key,
    required BuildContext context,
    Widget? title,
    List<Widget>? leading,
    List<Widget>? actions,
    EdgeInsets? padding,
  }) {
    Style style = Theme.of(context).extension<Style>()!;

    return PreferredSize(
      key: key,
      preferredSize: const Size(double.infinity, 60),
      child: Padding(
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
                  if (leading != null) ...leading,
                  Expanded(
                    child: DefaultTextStyle.merge(
                      style: Theme.of(context).appBarTheme.titleTextStyle,
                      child: Center(child: title ?? Container()),
                    ),
                  ),
                  if (actions != null) ...actions,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
