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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/widget/widget_button.dart';

/// [WidgetButton] stylized as a rectangular shaped button meant to be used as
/// an unblock button.
class UnblockButton extends StatelessWidget {
  const UnblockButton(this.onPressed, {super.key});

  /// Callback, called when this [UnblockButton] is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      key: const Key('UnblockButton'),
      decoration: BoxDecoration(
        borderRadius: style.cardRadius,
        boxShadow: [
          CustomBoxShadow(
            blurRadius: 8,
            color: style.colors.onBackgroundOpacity13,
          ),
        ],
      ),
      child: WidgetButton(
        onPressed: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 56),
          decoration: BoxDecoration(
            borderRadius: style.cardRadius,
            color: style.cardColor,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'btn_unblock'.l10n,
                  textAlign: TextAlign.center,
                  style: style.bodyLarge.copyWith(color: style.colors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
