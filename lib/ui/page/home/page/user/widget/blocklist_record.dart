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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/info_tile.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/svg/svg.dart';

/// Visual representation of the provided [BlocklistRecord].
class BlocklistRecordWidget extends StatelessWidget {
  const BlocklistRecordWidget(this.record, {super.key, this.onUnblock});

  /// [BlocklistRecord] to display.
  final BlocklistRecord record;

  /// Callback, called when an unblock button is pressed.
  final void Function()? onUnblock;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Paddings.basic(
          InfoTile(
            title: 'label_block_date'.l10n,
            content: record.at.val.toLocal().yMdHm,
          ),
        ),
        if (record.reason != null) ...[
          const SizedBox(height: 8),
          Paddings.basic(
            InfoTile(
              title: 'label_block_reason'.l10n,
              content: record.reason!.val,
            ),
          ),
        ],
        if (onUnblock != null) ...[
          const SizedBox(height: 16),
          SelectionContainer.disabled(
            child: ActionButton(
              key: const Key('Unblock'),
              text: 'btn_unblock'.l10n,
              onPressed: onUnblock,
              trailing: const SvgIcon(SvgIcons.unblock),
            ),
          ),
        ],
      ],
    );
  }
}
