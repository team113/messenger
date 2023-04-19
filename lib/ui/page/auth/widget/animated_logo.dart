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

import '../controller.dart';
import '/config.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';

/// Displaying an animated logo.
class AnimatedLogo extends StatelessWidget {
  const AnimatedLogo(this.c, {super.key});

  /// Responsible for calling the method that promotes logo animation.
  final AuthController c;

  @override
  Widget build(BuildContext context) {
    final Widget child;
    const double height = 250;
    const BoxConstraints constraints = BoxConstraints(maxHeight: 350);

    if (constraints.maxHeight >= height) {
      child = Container(
        key: const ValueKey('logo'),
        child: RiveAnimation.asset(
          'assets/images/logo/logo.riv',
          onInit: (a) {
            if (!Config.disableInfiniteAnimations) {
              final StateMachineController? machine =
                  StateMachineController.fromArtboard(a, 'Machine');
              a.addController(machine!);
              c.blink = machine.findInput<bool>('blink') as SMITrigger?;
              Future.delayed(
                const Duration(milliseconds: 500),
                c.animate,
              );
            }
          },
        ),
      );
    } else {
      child = Obx(() {
        return SvgImage.asset(
          'assets/images/logo/head000${c.logoFrame.value}.svg',
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
      });
    }

    return LayoutBuilder(builder: (context, constraints) {
      return ConstrainedBox(
        constraints: constraints,
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
