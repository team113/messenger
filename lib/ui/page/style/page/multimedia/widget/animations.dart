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
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:rive/rive.dart';

import '/ui/page/auth/widget/animated_logo.dart';
import '/ui/page/home/widget/animated_typing.dart';
import '/ui/page/style/controller.dart';
import '/ui/widget/progress_indicator.dart';
import '/themes.dart';
import 'styled_container.dart';

/// [Column] with [Container]s which represents application animations.
class AnimationsColumn extends StatelessWidget {
  const AnimationsColumn({
    super.key,
    this.inverted = false,
    this.dense = false,
  });

  /// Indicator whether this [AnimationsColumn] should have its colors
  /// inverted.
  final bool inverted;

  /// Indicator whether this [AnimationsColumn] should be compact, meaning
  /// minimal [Padding]s.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return GetBuilder(
        init: StyleController(),
        builder: (StyleController c) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 0 : 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: DefaultTextStyle(
                style: fonts.headlineSmall!.copyWith(
                  color: const Color(0xFF1F3C5D),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StyledContainer(
                      inverted: inverted,
                      width: 160,
                      text: 'AnimatedLogo',
                      padding: const EdgeInsets.all(16),
                      child: Obx(
                        () => AnimatedLogo(
                          svgAsset:
                              'assets/images/logo/head000${c.logoFrame.value}.svg',
                          onInit: (a) => _setBlink(c, a),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StyledContainer(
                      inverted: inverted,
                      text: 'SpinKitDoubleBounce',
                      width: 80,
                      padding: const EdgeInsets.all(8),
                      child: SpinKitDoubleBounce(
                        color: style.colors.secondaryHighlightDark,
                        size: 100 / 1.5,
                        duration: const Duration(milliseconds: 4500),
                      ),
                    ),
                    const SizedBox(height: 16),
                    StyledContainer(
                      inverted: inverted,
                      text: 'AnimatedTyping',
                      width: 82,
                      padding: const EdgeInsets.all(32),
                      child: const AnimatedTyping(),
                    ),
                    const SizedBox(height: 16),
                    StyledContainer(
                      inverted: inverted,
                      text: 'CustomProgressIndicator',
                      padding: const EdgeInsets.all(20),
                      child: const CustomProgressIndicator(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        });
  }

  /// Sets the [StyleController.blink] from the provided [Artboard] and invokes
  /// a [StyleController.animate] to animate it.
  Future<void> _setBlink(StyleController c, Artboard a) async {
    final StateMachineController machine =
        StateMachineController(a.stateMachines.first);
    a.addController(machine);

    c.blink = machine.findInput<bool>('blink') as SMITrigger?;

    await Future.delayed(const Duration(milliseconds: 500), c.animate);
  }
}
