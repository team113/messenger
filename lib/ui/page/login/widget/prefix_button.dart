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

import '/ui/page/home/widget/field_button.dart';

/// [FieldButton] stylized with the provided [prefix] widget.
class PrefixButton extends StatelessWidget {
  const PrefixButton({
    super.key,
    this.text = '',
    this.onPressed,
    this.style,
    this.prefix,
  });

  /// [text] of this [PrefixButton].
  final String text;

  /// [TextStyle] of the [text].
  final TextStyle? style;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  /// [Widget] to display as a prefix.
  final Widget? prefix;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        FieldButton(
          text: text,
          maxLines: null,
          style: style,
          onPressed: onPressed,
          textAlign: TextAlign.center,
        ),
        if (prefix != null) IgnorePointer(child: prefix!),
      ],
    );
  }
}
