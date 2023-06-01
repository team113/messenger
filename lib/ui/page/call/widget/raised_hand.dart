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

/// [Widget] which returns a raised hand icon with animation.
class RaisedHand extends StatelessWidget {
  const RaisedHand(this.raised, {super.key});

  /// Indicator whether a hand is raised or not.
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: raised ? 1 : 0,
      child: CircleAvatar(
        radius: 45,
        backgroundColor: style.colors.secondaryOpacity87,
        child: SvgImage.asset('assets/icons/hand_up.svg', width: 90),
      ),
    );
  }
}
