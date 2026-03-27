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

import '/domain/model/ongoing_call.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/widget/animated_dots.dart';

/// Caption and subtitle texts used to display [ChatCall.author] and
/// [OngoingCall] state.
class CallTitle extends StatelessWidget {
  const CallTitle({super.key, this.title, this.state, this.withDots = false});

  /// Title of this [CallTitle].
  final String? title;

  /// Optional state text.
  final String? state;

  /// Indicator whether [AnimatedDots] should be displayed near the [state] or
  /// not.
  ///
  /// Only meaningful if [state] is non-`null`.
  final bool withDots;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final List<Shadow> shadows = [
      Shadow(blurRadius: 6, color: style.colors.onBackground),
      Shadow(blurRadius: 6, color: style.colors.onBackground),
    ];

    return DefaultTextStyle.merge(
      maxLines: 1,
      softWrap: true,
      overflow: TextOverflow.ellipsis,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title ?? ('dot'.l10n * 3),
            style: style.fonts.largest.bold.onPrimary.copyWith(
              shadows: shadows,
            ),
          ),
          if (state != null) const SizedBox(height: 10),
          if (state != null)
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (withDots) const SizedBox(width: 13),
                Text(
                  state!,
                  style: style.fonts.big.regular.onPrimary.copyWith(
                    shadows: shadows,
                  ),
                ),
                if (withDots) const AnimatedDots(),
              ],
            ),
        ],
      ),
    );
  }
}
