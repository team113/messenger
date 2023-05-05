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

/// [Column] consisting of the [child] with the provided [description].
class Description extends StatelessWidget {
  const Description({
    Key? key,
    required this.child,
    required this.description,
  }) : super(key: key);

  /// [Widget] that will be displayed along with the description.
  final Widget child;

  /// [Widget] that displays a description for the child widget.
  final Widget description;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 6),
        DefaultTextStyle(
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          child: description,
        ),
      ],
    );
  }
}
