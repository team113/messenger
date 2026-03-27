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

/// Current position and duration of the provided [controller].
class CurrentPosition extends StatelessWidget {
  const CurrentPosition({
    super.key,
    this.duration = Duration.zero,
    this.position = Duration.zero,
  });

  /// Current relative position.
  final Duration position;

  /// Whole [Duration] to display [position] relative to.
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final String position = this.position.hhMmSs();
    final String duration = this.duration.hhMmSs();

    return Text(
      'label_a_slash_b'.l10nfmt({'a': position, 'b': duration}),
      style: style.fonts.small.regular.onPrimary,
    );
  }
}
