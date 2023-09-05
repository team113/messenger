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
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

import '/ui/widget/outlined_rounded_button.dart';

/// Small rounded [OutlinedRoundedButton] with a single [icon].
class StyleCard extends StatelessWidget {
  const StyleCard({
    super.key,
    this.icon,
    this.onPressed,
    this.inverted = false,
    this.asset,
    this.assetWidth,
    this.assetHeight,
  });

  /// [IconData] to display.
  final IconData? icon;

  /// Indicator whether this [StyleCard] should have its colors inverted.
  final bool inverted;

  /// Callback, called when this [StyleCard] is pressed.
  final void Function()? onPressed;

  final String? asset;
  final double? assetWidth;
  final double? assetHeight;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    // [AnimatedOpacity] boilerplate.
    Widget tab({
      required Widget child,
      required void Function() onPressed,
      bool selected = false,
    }) {
      return AnimatedScale(
        duration: const Duration(milliseconds: 150),
        curve: Curves.bounceInOut,
        scale: selected ? 1.1 : 1,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: selected ? 1 : 0.7,
          child: AnimatedButton(onPressed: onPressed, child: child),
        ),
      );
    }

    return tab(
      selected: inverted,
      onPressed: onPressed ?? () {},
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: asset == null
            ? Icon(icon, color: style.colors.primary, size: 30)
            : SvgImage.asset(
                'assets/icons/$asset.svg',
                width: assetWidth,
                height: assetHeight,
              ),
      ),
    );

    // return Padding(
    //   padding: const EdgeInsets.all(6),
    //   child: SizedBox(
    //     width: 60,
    //     height: 40,
    //     child: OutlinedRoundedButton(
    //       color: inverted ? style.colors.primary : style.colors.onPrimary,
    //       onPressed: onPressed,
    //       title: Icon(
    //         icon,
    //         color: inverted ? style.colors.onPrimary : style.colors.primary,
    //       ),
    //     ),
    //   ),
    // );
  }
}
