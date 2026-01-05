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
import '/ui/widget/text_field.dart';

/// Custom-styled [ReactiveTextField] with [Switch.adaptive].
class SwitchField extends StatelessWidget {
  const SwitchField({
    super.key,
    this.text,
    this.value = false,
    this.onChanged,
    this.background,
    this.label,
  });

  /// Text of the [ReactiveTextField].
  final String? text;

  /// Indicator whether this switch is on or off.
  final bool value;

  /// Callback, called when the user toggles the switch.
  final void Function(bool)? onChanged;

  /// Background [Color] of this [SwitchField].
  final Color? background;

  /// Label to display.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Stack(
      alignment: Alignment.centerRight,
      children: [
        IgnorePointer(
          child: ReactiveTextField(
            state: TextFieldState(text: text, editable: false),
            style: style.fonts.normal.regular.onBackground,
            label: label,
            fillColor: background ?? style.colors.onPrimary,
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 5, bottom: 2),
            child: Transform.scale(
              scale: 0.7,
              transformHitTests: false,
              child: Theme(
                data: ThemeData(platform: TargetPlatform.macOS),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Switch.adaptive(
                    activeTrackColor: style.colors.primary,
                    activeThumbColor: style.colors.onPrimary,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    value: value,
                    onChanged: onChanged,
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
