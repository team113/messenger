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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/themes.dart';

/// Custom styled [CupertinoButton].
class StyledCupertinoButton extends StatelessWidget {
  const StyledCupertinoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color,
    this.enlarge = false,
    this.dense = false,
    this.tiny = false,
  });

  final bool enlarge;
  final bool dense;
  final bool tiny;

  /// Label to display.
  final String label;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).style;

    final TextStyle? thin = context.textTheme.bodySmall?.copyWith(
      fontSize: tiny
          ? 9
          : dense
              ? 13
              : enlarge
                  ? 17
                  : 15,
      color: color ?? style.colors.primary,
    );

    return WidgetButton(
      onPressed: onPressed,
      child: Text(label, style: thin),
      // child: Padding(
      //   padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      //   child: Text(label, style: thin),
      // ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      opaque: false,
      child: CupertinoButton(
        onPressed: onPressed,
        child: Text(label, style: thin),
      ),
    );
  }
}
