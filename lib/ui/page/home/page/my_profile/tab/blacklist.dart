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

import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/my_profile/blacklist/view.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/paddings.dart';

/// Custom-styled FieldButton with [blacklist]ed users.
class BlacklistField extends StatelessWidget {
  const BlacklistField(this.blacklist, {super.key});

  /// [List] of blacklisted users.
  final List blacklist;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Column(
      children: [
        Paddings.dense(
          FieldButton(
            text: 'label_users_count'.l10nfmt({'count': blacklist.length}),
            onPressed:
                blacklist.isEmpty ? null : () => BlacklistView.show(context),
            style: fonts.titleMedium!.copyWith(
              color: blacklist.isEmpty
                  ? style.colors.onBackground
                  : style.colors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
