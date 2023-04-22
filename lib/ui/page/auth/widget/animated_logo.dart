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
import 'package:get/get.dart';
import 'package:rive/rive.dart' hide LinearGradient;

import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';

/// Logo with animation.
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    this.constraints = const BoxConstraints(maxHeight: 350),
    this.height = 250,
    this.logoKey,
    required this.riveAsset,
    this.onInit,
    required this.svgAsset,
    this.svgAssetHeight = 140,
    this.curve = Curves.ease,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  /// Maximum width and height constraints of the [AnimatedLogo].
  final BoxConstraints constraints;

  /// Maximum [height] of the [AnimatedLogo] that can be displayed on the screen.
  final double height;

  /// [ValueKey] object that uniquely identifies the [Container]
  /// that contains the [RiveAnimation] asset.
  final ValueKey? logoKey;

  /// Path of the [RiveAnimation] asset.
  final String riveAsset;

  /// Callback fired when [RiveAnimation] has initialized.
  final void Function(Artboard)? onInit;

  /// Path of the [SvgLoader] asset.
  final String svgAsset;

  /// Height of the [SvgLoader] asset.
  final double svgAssetHeight;

  /// Type of [Curve] when changing the size of the [SizedBox] to match the size of the [AnimatedLogo].
  final Curve curve;

  /// [Duration] when changing the size of the [SizedBox] to match the size of the [AnimatedLogo].
  final Duration animationDuration;

  @override
  Widget build(BuildContext context) {
    /// Type of logo that will be displayed on the screen.
    ///
    /// If the maximum height of [constraints] is greater than or equal to [height],
    /// then a container with the [RiveAnimation.asset] animation is displayed.
    /// If the maximum [height] of the restrictions is less than the [height],
    /// then the SVG widget is displayed, loaded via [SvgLoader.asset].
    final Widget child;

    if (constraints.maxHeight >= height) {
      child = Container(
        key: ValueKey(logoKey),
        child: RiveAnimation.asset(
          riveAsset,
          onInit: onInit,
        ),
      );
    } else {
      child = Obx(() {
        return SvgLoader.asset(
          svgAsset,
          height: svgAssetHeight,
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
      });
    }

    return LayoutBuilder(builder: (context, constraints) {
      return ConstrainedBox(
        constraints: constraints,
        child: AnimatedSize(
          curve: curve,
          duration: animationDuration,
          child: SizedBox(
            height: constraints.maxHeight >= height ? height : 140,
            child: child,
          ),
        ),
      );
    });
  }
}
