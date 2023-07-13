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

import '/themes.dart';

/// Header-styled [Text].
class Header extends StatelessWidget {
  const Header({super.key, this.label});

  /// Label of this [Header].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: fonts.displayLarge!.copyWith(color: const Color(0xFF1F3C5D)),
          ),
      ],
    );
  }
}

/// Small header-styled [Text].
class SmallHeader extends StatelessWidget {
  const SmallHeader({super.key, this.label});

  /// Label of this [SmallHeader].
  final String? label;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        const SizedBox(height: 50),
        if (label != null)
          Text(
            label!,
            style:
                fonts.headlineLarge!.copyWith(color: const Color(0xFF1F3C5D)),
          ),
      ],
    );
  }
}
