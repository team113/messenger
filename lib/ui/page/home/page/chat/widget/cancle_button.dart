// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svgs.dart';

/// [AnimatedButton] with close icon
class CancelButton extends StatelessWidget {
  const CancelButton({super.key, required this.onPressed});

  /// Callback, called when the button is pressed.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AnimatedButton(
      key: const Key('CancelSelecting'),
      onPressed: onPressed,
      child: Container(
        padding: const EdgeInsets.only(left: 10),
        height: double.infinity,
        child: const Padding(
          padding: EdgeInsets.fromLTRB(10, 0, 21, 0),
          child: SvgIcon(SvgIcons.closePrimary),
        ),
      ),
    );
  }
}
