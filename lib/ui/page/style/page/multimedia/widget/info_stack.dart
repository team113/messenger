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

/// TODO(zhorenty): docs and name
class InfoStackWidget extends StatelessWidget {
  const InfoStackWidget({
    super.key,
    this.height,
    this.width,
    this.padding,
    this.child,
    this.inverted = false,
  });

  /// Indicator whether this [InfoStackWidget] should have its colors
  /// inverted.
  final bool inverted;

  /// Height of this [InfoStackWidget].
  final double? height;

  /// Width of this [InfoStackWidget].
  final double? width;

  /// Padding of a [child].
  final EdgeInsetsGeometry? padding;

  /// Widget of this [InfoStackWidget].
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: height,
      width: width,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: inverted ? const Color(0xFF1F3C5D) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: padding,
      child: child,
    );
  }
}
