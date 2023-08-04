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
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';
import '/l10n/l10n.dart';

/// Text of the current position and duration of a [MeeduVideoPlayer].
class CurrentPosition extends StatelessWidget {
  const CurrentPosition({super.key, required this.controller});

  /// [MeeduPlayerController] controlling the [MeeduVideoPlayer] functionality.
  final MeeduPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return RxBuilder((_) {
      final String position = controller.position.value.hhMmSs();
      final String duration = controller.duration.value.hhMmSs();

      return Text(
        'label_a_slash_b'.l10nfmt({'a': position, 'b': duration}),
        style: fonts.labelMedium!.copyWith(color: style.colors.onPrimary),
      );
    });
  }
}
