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
import '/themes.dart';
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/widget/text_field.dart';
import 'sharable.dart';

/// [CopyableTextField] representation of the provided [UserNum].
class UserNumCopyable extends StatelessWidget {
  const UserNumCopyable(this.num, {super.key, this.share = false, this.label});

  /// [UserNum] to display.
  final UserNum? num;

  /// Indicator whether [num] should use the [SharableTextField] instead of the
  /// [CopyableTextField].
  final bool share;

  /// Label to display.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    if (share) {
      return SharableTextField(
        text: num?.toString(),
        label: label ?? 'label_num'.l10n,
        share: 'Gapopa ID: $num',
        style: style.fonts.big.regular.onBackground,
      );
    }

    return CopyableTextField(
      state: TextFieldState(text: num?.toString(), editable: false),
      label: label ?? 'label_num'.l10n,
    );
  }
}
