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
import 'package:flutter/services.dart';

import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';

/// [AnimatedContainer] with optional subtitle.
class SubtitleContainer extends StatelessWidget {
  const SubtitleContainer({
    super.key,
    this.height,
    this.width,
    this.subtitle,
    this.child,
    this.inverted = false,
  });

  /// Indicator whether this [SubtitleContainer] should have its colors
  /// inverted.
  final bool inverted;

  /// Width of this [SubtitleContainer].
  final double? width;

  /// Height of this [SubtitleContainer].
  final double? height;

  /// [Widget] to put in the center of background.
  final Widget? child;

  /// Text for the [WidgetButton] displayed under the [AnimatedContainer].
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          width: width,
          height: height,
          padding: const EdgeInsets.all(16),
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: inverted ? const Color(0xFF1F3C5D) : Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 0, 4),
            child: WidgetButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: subtitle!));
                MessagePopup.success('Technical name is copied');
              },
              child: Text(subtitle!),
            ),
          ),
      ],
    );
  }
}
