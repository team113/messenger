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

/// [AnimatedSwitcher] with exception-safe layout builder.
///
/// Intended to be used instead of the [AnimatedSwitcher].
class SafeAnimatedSwitcher extends StatelessWidget {
  const SafeAnimatedSwitcher({super.key, required this.duration, this.child});

  /// [Duration] of the switching animation.
  final Duration duration;

  /// Current [Widget] to display.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: duration,
      layoutBuilder: (current, previous) => Stack(
        alignment: Alignment.center,
        children: [
          if (previous.isNotEmpty) previous.first,
          if (current != null) current,
        ],
      ),
      child: child,
    );
  }
}
