// Copyright © 2022-2023 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'dart:ui';

import 'package:flutter/material.dart';

/// Wrapper around a [child] with or without [BackdropFilter] based on a
/// [condition].
class ConditionalBackdropFilter extends StatelessWidget {
  ConditionalBackdropFilter({
    Key? key,
    required this.child,
    this.condition = true,
    ImageFilter? filter,
    this.borderRadius,
  }) : super(key: key) {
    this.filter = filter ??
        ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
          tileMode: TileMode.mirror,
        );
  }

  /// [Widget] to apply [BackdropFilter] to.
  final Widget child;

  /// Indicator whether [BackdropFilter] should be enabled or not.
  final bool condition;

  /// Image filter to apply to the existing painted content before painting the
  /// [child].
  ///
  /// Defaults to [ImageFilter.blur] if not specified.
  late final ImageFilter filter;

  /// Border radius to clip the [child].
  ///
  /// Clips the [child] by a [ClipRect] if not specified, or by a [ClipRRect]
  /// otherwise.
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (condition) {
      if (borderRadius != null) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: BackdropFilter(
            filter: filter,
            blendMode: BlendMode.src,
            child: child,
          ),
        );
      }

      return ClipRect(
        child: BackdropFilter(
          filter: filter,
          blendMode: BlendMode.src,
          child: child,
        ),
      );
    }

    return child;
  }
}
