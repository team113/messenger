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
import 'package:rive/rive.dart';

import '/ui/page/auth/widget/animated_logo.dart';
import '/ui/page/style/controller.dart';
import '/config.dart';
import '/themes.dart';

class AnimationStyleWidget extends StatelessWidget {
  const AnimationStyleWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final (style, _) = Theme.of(context).styles;

    return GetBuilder(
        init: StyleController(),
        builder: (StyleController c) {
          return Row(
            children: [
              Tooltip(
                message: 'Full-length animated Logo',
                child: Container(
                  height: 300,
                  width: 200,
                  decoration: BoxDecoration(
                    color: style.colors.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Obx(
                    () => Padding(
                      padding: const EdgeInsets.all(15),
                      child: AnimatedLogo(
                        key: const ValueKey('Logo'),
                        svgAsset:
                            'assets/images/logo/head000${c.logoFrame.value}.svg',
                        onInit: Config.disableInfiniteAnimations
                            ? null
                            : (a) => _setBlink(c, a),
                      ),
                    ),
                  ),
                ),
              ),
            ],
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
