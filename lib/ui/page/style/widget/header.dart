// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

/// [Text] serving a header.
class Header extends StatelessWidget {
  const Header(this.label, {super.key});

  /// Label to display.
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          style: style.fonts.largest.bold.onBackground.copyWith(
            color: const Color(0xFF1F3C5D),
          ),
        ),
      ),
    );
  }
}

/// [Text] serving a sub-header.
class SubHeader extends StatelessWidget {
  const SubHeader(this.label, {super.key});

  /// Label to display.
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
        child: Text(
          label,
          style: style.fonts.big.regular.onBackground.copyWith(
            color: const Color(0xFF1F3C5D),
          ),
          textAlign: TextAlign.start,
        ),
      ),
    );
  }
}
