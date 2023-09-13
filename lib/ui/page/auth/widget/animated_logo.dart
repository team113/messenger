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

/// Animated logo, displaying the provided [riveAsset], when higher than 250
/// pixels, or otherwise the specified [svgAsset].
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo({
    super.key,
    this.riveAsset = 'assets/images/logo/logo.riv',
    this.onInit,
  });

  /// Path to an asset to put into the [RiveAnimation].
  final String riveAsset;

  /// Callback, called when underlying [RiveAnimation] has been initialized.
  final void Function(Artboard)? onInit;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 350),
      child: AnimatedSize(
        curve: Curves.ease,
        duration: const Duration(milliseconds: 200),
        child: SizedBox(
          height: 166,
          child: RiveAnimation.asset(
            riveAsset,
            onInit: onInit,
          ),
        ),
      ),
    );
  }
}
