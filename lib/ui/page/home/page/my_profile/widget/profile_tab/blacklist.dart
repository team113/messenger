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
import 'package:get/get.dart';

import '../dense.dart';
import '/domain/model/my_user.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/my_profile/blacklist/view.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';

/// [Widget] which returns the contents of a [ProfileTab.blacklist] section.
class ProfileBlockedUsers extends StatelessWidget {
  const ProfileBlockedUsers(this.blacklist, {super.key});

  /// Reactive [List] of [User]s blacklisted by an authenticated [MyUser].
  final RxList<RxUser> blacklist;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Dense(
          FieldButton(
            text: 'label_blocked_count'.l10nfmt({'count': blacklist.length}),
            onPressed:
                blacklist.isEmpty ? null : () => BlacklistView.show(context),
            style: TextStyle(
                color: blacklist.isEmpty
                    ? Colors.black
                    : Theme.of(context).colorScheme.secondary),
          ),
        ),
      ],
    );
  }
}
