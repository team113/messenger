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
import '/ui/widget/svg/svg.dart';

/// A close button.
class CloseButton extends StatelessWidget {
  const CloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Container(
      width: 16,
      height: 16,
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      child: Container(
        key: const Key('Close'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: style.cardColor,
        ),
        alignment: Alignment.center,
        child: const SvgImage.asset(
          'assets/icons/close_primary.svg',
          width: 8,
          height: 8,
        ),
      ),
    );
  }
}
