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

import '../animated_delayed_scale.dart';
import '../conditional_backdrop.dart';
import '/themes.dart';

/// Drag target indicator.
class DropBox extends StatelessWidget {
  const DropBox({
    super.key,
    this.withBlur = true,
    this.size = 50,
    this.padding = const EdgeInsets.all(16),
  });

  /// Indicator whether background should be blurred.
  final bool withBlur;

  /// Size of the icon.
  final double size;

  /// Padding around of the icon.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      color: style.colors.onBackgroundOpacity27,
      child: Center(
        child: AnimatedDelayedScale(
          duration: const Duration(milliseconds: 300),
          beginScale: 1,
          endScale: 1.06,
          child: ConditionalBackdropFilter(
            condition: withBlur,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: withBlur
                    ? style.colors.onBackgroundOpacity27
                    : style.colors.onBackgroundOpacity50,
              ),
              child: Padding(
                padding: padding,
                child: Icon(
                  Icons.add_rounded,
                  size: size,
                  color: style.colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
