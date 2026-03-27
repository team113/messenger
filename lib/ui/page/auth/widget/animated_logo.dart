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

import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';

/// Animated logo, displaying the [SvgImage] based on the provided [index].
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({super.key, this.index = 0, this.onEyePressed});

  /// Index of logo animation.
  ///
  /// Should be in 0..9 range inclusive.
  final int index;

  /// Callback, called when an eye of the logo is pressed.
  final void Function()? onEyePressed;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Load the whole [SvgImage]s beforehand to reduce possible frame drops.
        ...List.generate(
          10,
          (i) => 'assets/images/logo/head_$i.svg',
        ).map((e) => Offstage(child: SvgImage.asset(e))),

        // Animation itself.
        SvgImage.asset(
          'assets/images/logo/head_$index.svg',
          height: 166,
          fit: BoxFit.contain,
          placeholderBuilder: (context) {
            return const Center(child: CustomProgressIndicator());
          },
        ),

        if (onEyePressed != null)
          Positioned(
            left: 45,
            top: 64,
            child: GestureDetector(
              onDoubleTap: onEyePressed,
              child: Container(
                color: Colors.transparent,
                width: 30,
                height: 36,
              ),
            ),
          ),
      ],
    );
  }
}
