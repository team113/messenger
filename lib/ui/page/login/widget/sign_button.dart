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
import 'prefix_button.dart';

/// [PrefixButton] with an [icon] as a prefix.
class SignButton extends StatelessWidget {
  const SignButton({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.padding = EdgeInsets.zero,
    this.onPressed,
  });

  /// Title of this [SignButton].
  final String title;

  /// Subtitle of this [SignButton].
  final String? subtitle;

  /// Widget to display as a [PrefixButton.prefix].
  final Widget? icon;

  /// Additional padding to apply to the [icon].
  final EdgeInsets padding;

  /// Callback, called when this button is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: PrefixButton(
        title: title,
        subtitle: subtitle,
        style: onPressed == null
            ? style.fonts.medium.regular.secondary
            : style.fonts.medium.regular.onBackground,
        onPressed: onPressed,
        prefix: icon == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(left: 16).add(padding),
                child: icon,
              ),
      ),
    );
  }
}
