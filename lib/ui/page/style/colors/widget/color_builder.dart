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

/// [Wrap] with animated background.
class AnimatedWrap extends StatelessWidget {
  const AnimatedWrap(
    this.inverted, {
    super.key,
    this.children = const <Widget>[],
  });

  /// Indicator whether this [AnimatedWrap] should have its colors inverted.
  final bool inverted;

  /// Widgets to put inside a [Wrap].
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      width: MediaQuery.sizeOf(context).width,
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: inverted ? const Color(0xFF142839) : const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 16,
          runSpacing: 16,
          children: children,
        ),
      ),
    );
  }
}
