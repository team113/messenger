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

import '/themes.dart';
import '/ui/widget/svg/svg.dart';
import 'prefix_button.dart';

/// [PrefixButton] with an [asset] as a prefix and a [title].
class SignButton extends StatelessWidget {
  const SignButton({
    super.key,
    required this.title,
    this.asset = '',
    this.assetWidth = 20,
    this.assetHeight = 20,
    this.padding = EdgeInsets.zero,
    this.onPressed,
  });

  /// Title of this [SignButton].
  final String title;

  /// Asset to display as a `prefix`.
  final String asset;

  /// Width of the [asset].
  final double assetWidth;

  ///  Height of the [asset].
  final double assetHeight;

  /// Padding to apply to the `prefix`.
  final EdgeInsets padding;

  /// Callback to call when this button is pressed.
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: PrefixButton(
        title: title,
        style: style.fonts.titleLarge,
        onPressed: onPressed ?? () {},
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16).add(padding),
          child: SvgImage.asset(
            'assets/icons/$asset.svg',
            width: assetWidth,
            height: assetHeight,
          ),
        ),
      ),
    );
  }
}
