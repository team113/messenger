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

import '/l10n/l10n.dart';
import '/themes.dart';

/// Rounded [Container] indicating the rewinding for the provided [seconds]
/// forward or backward.
class RewindIndicator extends StatelessWidget {
  const RewindIndicator({
    super.key,
    this.seconds = 1,
    this.opacity = 1,
    this.forward = true,
  });

  /// Seconds of rewind to display.
  final int seconds;

  /// Opacity of this [RewindIndicator].
  final double opacity;

  /// Indicator whether this [RewindIndicator] should display a forward rewind,
  /// or backward otherwise.
  final bool forward;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 200),
      child: Container(
        width: 100,
        height: 70,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(35),
          color: style.colors.onBackgroundOpacity27,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                forward ? Icons.fast_forward : Icons.fast_rewind,
                color: style.colors.onPrimary,
              ),
              Text(
                'label_count_seconds'.l10nfmt({'count': seconds}),
                style: style.fonts.normal.regular.onPrimary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
