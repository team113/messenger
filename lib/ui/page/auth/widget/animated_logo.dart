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
import 'package:rive/rive.dart' hide LinearGradient;

import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';

/// Logo with animation.
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    required this.riveAsset,
    this.onInit,
    required this.svgAsset,
  });

  /// Path of the [RiveAnimation] asset.
  final String riveAsset;

  /// Callback fired when [RiveAnimation] has initialized.
  final void Function(Artboard)? onInit;

  /// Path of the [SvgLoader] asset.
  final String svgAsset;

  @override
  Widget build(BuildContext context) {
    /// Type of logo that will be displayed on the screen.
    ///
    /// If the maximum height of [constraints] is greater than or equal to [height],
    /// then a container with the [RiveAnimation.asset] animation is displayed.
    /// If the maximum [height] of the restrictions is less than the [height],
    /// then the SVG widget is displayed, loaded via [SvgLoader.asset].
    Widget child;

    /// Maximum [height] of the [AnimatedLogo] that can be displayed on the screen.
    const double height = 250;

    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxHeight >= height) {
        child = RiveAnimation.asset(
          riveAsset,
          onInit: onInit,
        );
      } else {
        child = SvgLoader.asset(
          svgAsset,
          height: 140,
          placeholderBuilder: (context) {
            return LayoutBuilder(builder: (context, constraints) {
              return SizedBox(
                height: constraints.maxHeight > 250
                    ? height
                    : constraints.maxHeight <= 140
                        ? 140
                        : height,
                child: const Center(child: CustomProgressIndicator()),
              );
            });
          },
        );
      }

      return ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 350),
        child: AnimatedSize(
          curve: Curves.ease,
          duration: const Duration(milliseconds: 200),
          child: SizedBox(
            height: constraints.maxHeight >= height ? height : 140,
            child: child,
          ),
        ),
      );
    });
  }
}
