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

import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

/// Styled [AnimatedContainer] with [WidgetButton].
class StyledContainer extends StatelessWidget {
  const StyledContainer({
    super.key,
    this.height,
    this.width,
    this.text,
    this.padding,
    this.child,
    this.inverted = false,
  });

  /// Indicator whether this [StyledContainer] should have its colors
  /// inverted.
  final bool inverted;

  /// Text for the [WidgetButton] displayed under the [AnimatedContainer].
  final String? text;

  /// Height of this [StyledContainer].
  final double? height;

  /// Width of this [StyledContainer].
  final double? width;

  /// Padding of a [child].
  final EdgeInsetsGeometry? padding;

  /// Widget of this [StyledContainer].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          height: height,
          width: width,
          padding: padding,
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: inverted ? const Color(0xFF1F3C5D) : const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        if (text != null)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: WidgetButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: text!));
                MessagePopup.success('Technical name is copied');
              },
              child: Text(text!),
            ),
          )
      ],
    );
  }
}
