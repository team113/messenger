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

/// [Widget] which returns an [InkWell] circular button with an [icon].
class CircularButton extends StatelessWidget {
  const CircularButton({super.key, this.icon, this.onTap});

  /// [Widget] that will be displayed on this [CircularButton].
  final Widget? icon;

  /// Callback, called when the button is pressed.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.circle,
      color: Colors.white,
      shadowColor: const Color(0x55000000),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          decoration: const BoxDecoration(shape: BoxShape.circle),
          width: 42,
          height: 42,
          child: Center(child: icon),
        ),
      ),
    );
  }
}
