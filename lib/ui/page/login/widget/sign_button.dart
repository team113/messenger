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
import 'package:messenger/themes.dart';

import '/ui/widget/svg/svg.dart';
import 'prefix_button.dart';

///
class SignButton extends StatelessWidget {
  const SignButton({
    super.key,
    required this.text,
    this.leading,
    this.asset = '',
    this.assetWidth = 20,
    this.assetHeight = 20,
    this.padding = EdgeInsets.zero,
    this.onPressed,
    this.dense = false,
  });

  ///
  final String text;

  ///
  final bool dense;

  ///
  final Widget? leading;

  ///
  final String asset;

  ///
  final double assetWidth;

  ///
  final double assetHeight;

  ///
  final EdgeInsets padding;

  ///
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Center(
      child: PrefixButton(
        text: text,
        style: dense ? style.fonts.labelMediumPrimary : style.fonts.titleLarge,
        onPressed: onPressed ?? () {},
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 0).add(padding),
          child: leading ??
              SvgImage.asset(
                'assets/icons/$asset.svg',
                width: assetWidth,
                height: assetHeight,
              ),
        ),
      ),
    );
  }
}
