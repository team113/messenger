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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';

/// Copyable text field that puts a data into the clipboard on trailing click.
class CopyableTextField extends StatelessWidget {
  const CopyableTextField({
    super.key,
    required this.state,
    this.icon,
    this.label,
    this.style,
    this.leading,
  });

  /// Reactive state of this [CopyableTextField].
  final TextFieldState state;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional leading [Widget].
  final Widget? leading;

  /// Optional label of this [CopyableTextField].
  final String? label;

  /// [TextStyle] of this [CopyableTextField].
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 25),
            child: Icon(icon, color: style.colors.secondary),
          ),
        Expanded(
          child: ReactiveTextField(
            prefix: leading,
            state: state,
            onSuffixPressed: state.text.isNotEmpty ? _copy : null,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: const SvgIcon(SvgIcons.copy),
            ),
            label: label,
            style: this.style,
          ),
        ),
      ],
    );
  }

  /// Puts a [TextFieldState.text] into the clipboard and shows a snackbar.
  void _copy() {
    PlatformUtils.copy(text: state.text);
    MessagePopup.success('label_copied'.l10n);
  }
}
