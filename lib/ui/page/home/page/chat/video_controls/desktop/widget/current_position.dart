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

// ignore_for_file: implementation_imports

import 'package:chewie/src/helpers/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_meedu_videoplayer/meedu_player.dart';

import '/themes.dart';

/// Returns the [Text] of the current video position.
class CurrentPosition extends StatelessWidget {
  const CurrentPosition({super.key, required this.controller});

  ///
  final MeeduPlayerController controller;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return RxBuilder((_) {
      final position = controller.position.value;
      final duration = controller.duration.value;

      return Text(
        '${formatDuration(position)} / ${formatDuration(duration)}',
        style: fonts.headlineSmall!.copyWith(color: style.colors.onPrimary),
      );
    });
  }
}
