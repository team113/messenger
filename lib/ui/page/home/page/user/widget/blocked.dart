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

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/padding.dart';
import '/ui/widget/text_field.dart';

/// [Widget] which returns the blacklisted information of this [User].
class BlockedWidget extends StatelessWidget {
  const BlockedWidget({super.key, this.isBlacklisted});

  /// Indicates whether [User] is blacklisted.
  final BlacklistRecord? isBlacklisted;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isBlacklisted?.at != null)
          BasicPadding(
            ReactiveTextField(
              state: TextFieldState(text: isBlacklisted!.at.toString()),
              label: 'label_date'.l10n,
              enabled: false,
            ),
          ),
        if (isBlacklisted?.reason != null)
          BasicPadding(
            ReactiveTextField(
              state: TextFieldState(text: isBlacklisted!.reason?.val),
              label: 'label_reason'.l10n,
              enabled: false,
            ),
          ),
      ],
    );
  }
}
