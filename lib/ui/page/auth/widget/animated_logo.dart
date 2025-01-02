// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';

/// Animated logo, displaying the [SvgImage] based on the provided [index].
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({super.key, this.index = 0});

  /// Index of logo animation.
  ///
  /// Should be in 0..9 range inclusive.
  final int index;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Load the whole [SvgImage]s beforehand to reduce possible frame drops.
        ...List.generate(10, (i) => SvgIcons.head[i])
            .map((e) => Offstage(child: SvgIcon(e))),

        // Animation itself.
        SvgImage.asset(
          'assets/images/logo/head_$index.svg',
          height: 166,
          fit: BoxFit.contain,
          placeholderBuilder: (context) {
            return const Center(child: CustomProgressIndicator());
          },
        ),
      ],
    );
  }
}
