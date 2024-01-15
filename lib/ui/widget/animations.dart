// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';

/// [AnimatedSwitcher] with an elastic [ScaleTransition] of its [child].
class ElasticAnimatedSwitcher extends StatelessWidget {
  const ElasticAnimatedSwitcher({super.key, required this.child});

  /// Current child widget to display.
  ///
  /// If there was a previous child, then it will be elastically faded out,
  /// while the new one is faded in.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSizeAndFade(
      fadeDuration: const Duration(milliseconds: 1350),
      sizeDuration: const Duration(milliseconds: 1350),
      sizeCurve: Curves.elasticInOut,
      fadeInCurve: Curves.elasticInOut,
      fadeOutCurve: Curves.elasticInOut,
      child: child,
    );
  }
}
