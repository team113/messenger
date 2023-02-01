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
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';

/// Copyable text field that puts a [copy] of data into the clipboard on click
/// or on context menu action.
class CopyableTextField extends StatelessWidget {
  const CopyableTextField({
    Key? key,
    required this.state,
    this.copy,
    this.icon,
    this.label,
    this.style,
    this.leading,
  }) : super(key: key);

  /// Reactive state of this [CopyableTextField].
  final TextFieldState state;

  /// Data to put into the clipboard.
  final String? copy;

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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null)
          Padding(
            padding: const EdgeInsets.only(left: 10, right: 25),
            child: Icon(
              icon,
              color: context.theme.colorScheme.primary,
            ),
          ),
        Expanded(
          child: ContextMenuRegion(
            enabled: (copy ?? state.text).isNotEmpty,
            actions: [
              ContextMenuButton(
                label: 'label_copy'.l10n,
                onPressed: () => _copy(context),
              ),
            ],
            child: InkWell(
              borderRadius: BorderRadius.circular(25),
              onTap: (copy ?? state.text).isEmpty ? null : () => _copy(context),
              child: IgnorePointer(
                child: ReactiveTextField(
                  prefix: leading,
                  state: state,
                  trailing: Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child: SvgLoader.asset(
                        'assets/icons/copy.svg',
                        height: 15,
                      ),
                    ),
                  ),
                  label: label,
                  style: style,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Puts a [copy] of data into the clipboard and shows a snackbar.
  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: copy ?? state.text));
    MessagePopup.success('label_copied'.l10n);
  }
}
