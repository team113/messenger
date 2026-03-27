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

/// Rounded rectangular button representing an [OngoingCall] happening.
class RectangularCallButton extends StatelessWidget {
  const RectangularCallButton({
    super.key,
    this.isActive = true,
    required this.at,
    this.onPressed,
  });

  /// Indicator whether this [RectangularCallButton] is active or not.
  final bool isActive;

  /// [DateTime] to display difference with within this button.
  final DateTime at;

  /// Callback, called when this [RectangularCallButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final Duration duration = DateTime.now().difference(at);
    final String text = duration.hhMmSs();

    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: style.colors.onPrimary, width: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        elevation: 0,
        type: MaterialType.button,
        borderRadius: BorderRadius.circular(20),
        color: isActive ? style.colors.danger : style.colors.primary,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.call_end : Icons.call,
                  size: 16,
                  color: style.colors.onPrimary,
                ),
                const SizedBox(width: 6),
                Text(text, style: style.fonts.normal.regular.onPrimary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
