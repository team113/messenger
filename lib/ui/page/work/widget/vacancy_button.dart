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

import '/routes.dart';
import '/ui/widget/menu_button.dart';
import '/ui/widget/svg/svg.dart';

/// [MenuButton] displaying the provided [work].
class VacancyWorkButton extends StatelessWidget {
  const VacancyWorkButton(
    this.work, {
    super.key,
    this.onPressed = _defaultOnPressed,
  });

  final void Function(WorkTab work)? onPressed;

  /// [WorkTab] to display.
  final WorkTab work;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool selected =
          router.routes.lastOrNull == '${Routes.work}/${work.name}';

      return MenuButton(
        title: switch (work) {
          WorkTab.backend => 'Backend Developer',
          WorkTab.frontend => 'Frontend Developer',
          WorkTab.freelance => 'Freelance',
        },
        subtitle: switch (work) {
          WorkTab.backend => 'Rust',
          WorkTab.frontend => 'Flutter',
          WorkTab.freelance => 'Flutter',
        },
        leading: switch (work) {
          WorkTab.backend => SvgImage.asset(
              'assets/icons/rust${selected ? '_white' : ''}.svg',
              width: 32,
              height: 32,
            ),
          WorkTab.frontend => SvgImage.asset(
              'assets/icons/frontend${selected ? '_white' : ''}.svg',
              width: 25.87,
              height: 32,
            ),
          WorkTab.freelance => SvgImage.asset(
              'assets/icons/freelance${selected ? '_white' : ''}.svg',
              width: 32,
              height: 32,
            ),
        },
        inverted: selected,
        onPressed: onPressed == null ? null : () => onPressed?.call(work),
      );
    });
  }

  static void _defaultOnPressed(WorkTab work) => router.work(work);
}
