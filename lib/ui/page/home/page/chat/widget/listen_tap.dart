// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

class ListenTap extends StatelessWidget {
  const ListenTap({
    super.key,
    this.isTap,
    required this.child,
  });

  /// Indicator whether tap on [child].
  final Rx<bool>? isTap;

  /// [Widget] for taps.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => isTap?.value = true,
      onPointerUp: (_) => isTap?.value = false,
      onPointerCancel: (_) => isTap?.value = false,
      child: child,
    );
  }
}
