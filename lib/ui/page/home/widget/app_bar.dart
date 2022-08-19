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

abstract class CustomAppBar {
  static PreferredSizeWidget from({
    Key? key,
    required BuildContext context,
    Widget? title,
    List<Widget>? leading,
    List<Widget>? actions,
    EdgeInsets? padding,
    bool automaticallyImplyLeading = false,
  }) {
    Style style = Theme.of(context).extension<Style>()!;
    bool isMobile = false; //context.isMobile;

    return PreferredSize(
      preferredSize: Size(double.infinity, isMobile ? 56 : 56 + 8 - 4),
      child: Padding(
        padding:
            isMobile ? EdgeInsets.zero : const EdgeInsets.fromLTRB(8, 4, 8, 0),
        child: Container(
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
            borderRadius: isMobile ? BorderRadius.zero : style.cardRadius,
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
              // ClipRRect(
              //   borderRadius: isMobile ? BorderRadius.zero : style.cardRadius,
              //   child: AppBar(
              //     backgroundColor: style.cardColor,
              //     title: title,
              //     leading: leading,
              //     actions: actions,
              //     automaticallyImplyLeading: automaticallyImplyLeading,
              //   ),
              // ),
            ),
          ),
        ),
      ),
    );
  }
}
