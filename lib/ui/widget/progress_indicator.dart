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
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:messenger/themes.dart';

class CustomProgressIndicator extends StatelessWidget {
  const CustomProgressIndicator({
    super.key,
    this.color,
    this.backgroundColor,
    this.valueColor,
    this.strokeWidth = 2.0,
    this.value,
  });

  final double? value;
  final Color? backgroundColor;
  final Color? color;
  final Animation<Color?>? valueColor;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    // if (value != null) {
    return CircularProgressIndicator(
      value: value,
      color: color ?? Theme.of(context).colorScheme.secondary,
      backgroundColor: backgroundColor,
      valueColor: valueColor,
      strokeWidth: strokeWidth,
    );
    // }

    // return LoadingAnimationWidget.flickr(
    //   leftDotColor: Theme.of(context).colorScheme.secondary,
    //   rightDotColor: Theme.of(context).colorScheme.secondary,
    //   size: 54,
    // );

    // return LoadingAnimationWidget.threeRotatingDots(
    //   color: Theme.of(context).colorScheme.secondary,
    //   size: 40,
    // );
  }
}
