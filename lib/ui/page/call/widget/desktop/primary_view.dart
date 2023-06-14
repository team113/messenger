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

import '../animated_delayed_scale.dart';
import '../conditional_backdrop.dart';
import '../reorderable_fit.dart';
import '/routes.dart';
import '/themes.dart';

/// [ReorderableFit] of the primary participants.
class PrimaryView extends StatelessWidget {
  const PrimaryView({
    super.key,
    required this.child,
    required this.test,
    this.condition = true,
  });

  ///
  final Widget child;

  ///
  final bool test;

  ///
  final bool? condition;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(router.context!).extension<Style>()!;

    return Stack(
      children: [
        child,
        IgnorePointer(
          child: AnimatedSwitcher(
            duration: 200.milliseconds,
            child: test
                ? Container(
                    color: style.colors.onBackgroundOpacity27,
                    child: Center(
                      child: AnimatedDelayedScale(
                        duration: const Duration(milliseconds: 300),
                        beginScale: 1,
                        endScale: 1.06,
                        child: ConditionalBackdropFilter(
                          condition: condition!,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: condition!
                                  ? style.colors.onBackgroundOpacity27
                                  : style.colors.onBackgroundOpacity50,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Icon(
                                Icons.add_rounded,
                                size: 50,
                                color: style.colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
