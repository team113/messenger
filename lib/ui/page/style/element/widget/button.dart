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

import '../../../auth/widget/cupertino_button.dart';
import '/themes.dart';

class ButtonsWidget extends StatelessWidget {
  const ButtonsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final (_, fonts) = Theme.of(context).styles;

    return Container(
      height: 300,
      width: MediaQuery.sizeOf(context).width,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9E9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Wrap(
        children: [
          Column(
            children: [
              Text(
                'Варианты оформления кнопок',
                style: fonts.headlineLarge!.copyWith(
                  color: const Color(0xFF1F3C5D),
                ),
              ),
              StyledCupertinoButton(label: 'US, English'),
            ],
          ),
        ],
      ),
    );
  }
}
