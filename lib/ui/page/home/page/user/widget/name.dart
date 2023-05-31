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
import '/ui/page/home/page/my_profile/widget/copyable.dart';
import '/ui/page/home/widget/padding.dart';
import '/ui/widget/text_field.dart';

/// [Widget] which returns a [User.name] copyable field.
class UserNameWidget extends StatelessWidget {
  const UserNameWidget({super.key, required this.user});

  /// Unique [User].
  final User user;

  @override
  Widget build(BuildContext context) {
    return BasicPadding(
      CopyableTextField(
        key: const Key('NameField'),
        state: TextFieldState(
          text: user.name?.val ?? user.num.val,
        ),
        label: 'label_name'.l10n,
        copy: user.name?.val ?? user.num.val,
      ),
    );
  }
}
