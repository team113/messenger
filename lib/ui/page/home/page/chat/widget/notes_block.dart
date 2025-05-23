// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import '/ui/widget/line_divider.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/block.dart';

/// [Block] describing [Chat]-monolog usage examples.
class NotesBlock extends StatelessWidget {
  const NotesBlock({super.key, this.info = false});

  /// Builds the [NotesBlock] with [info] mode.
  const NotesBlock.info({super.key}) : info = true;

  /// Indicator whether the title of this [NotesBlock] should reflect it being
  /// an information.
  final bool info;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      crossAxisAlignment: CrossAxisAlignment.start,
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      title: info ? 'label_info'.l10n : 'label_chat_monolog'.l10n,

      titleStyle: style.fonts.large.regular.onBackground,
      children: [
        Center(
          child: Text(
            'label_chat_monolog'.l10n,
            style: style.fonts.small.regular.secondary,
          ),
        ),
        const SizedBox(height: 12),
        LineDivider('label_notes_divider'.l10n),
        const SizedBox(height: 12),
        Text(
          'label_chat_monolog_features'.l10n,
          style: style.fonts.small.regular.secondary,
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
