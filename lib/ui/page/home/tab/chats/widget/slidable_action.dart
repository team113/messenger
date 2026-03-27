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
import 'package:flutter_slidable/flutter_slidable.dart';

import '/themes.dart';

/// [SlidableAction] appearing with fade in animation.
class FadingSlidableAction extends StatelessWidget {
  const FadingSlidableAction({
    super.key,
    required this.icon,
    required this.text,
    this.danger = false,
    this.onPressed,
  });

  /// [Widget] to display as the leading icon of this action.
  final Widget icon;

  /// Text of this action.
  final String text;

  /// Indictor whether this [FadingSlidableAction] should have danger color.
  final bool danger;

  /// Callback, called when this [FadingSlidableAction] is invoked.
  final void Function(BuildContext context)? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Expanded(
      child: SizedBox.expand(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 3, 3, 3),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return OutlinedButton(
                onPressed: () {
                  onPressed?.call(context);
                  Slidable.of(context)?.close();
                },
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.zero,
                  backgroundColor: danger
                      ? style.colors.danger
                      : style.colors.primary,
                  foregroundColor: style.colors.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: style.cardRadius),
                  side: BorderSide.none,
                ),
                child: Opacity(
                  opacity: constraints.maxWidth > 50
                      ? 1
                      : constraints.maxWidth > 25
                      ? (constraints.maxWidth - 25) / 25
                      : 0,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      icon,
                      const SizedBox(height: 8),
                      Text(text, maxLines: 1),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
