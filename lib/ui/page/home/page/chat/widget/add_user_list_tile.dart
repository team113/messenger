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
import 'package:messenger/themes.dart';

import '/domain/model/user.dart';

/// [ListTile] with an information of an [User].
class AddUserListTile extends StatelessWidget {
  const AddUserListTile(this.user, this.onTap, {Key? key}) : super(key: key);

  /// [User] this [AddUserListTile] is about.
  final User user;

  /// Callback, called when this [ListTile] is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(
            color: Theme.of(context).extension<Style>()!.onBackground);

    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(Icons.check, color: Colors.white),
      ),
      selected: true,
      selectedTileColor:
          Theme.of(context).extension<Style>()!.transparentOpacity94,
      title: Text(user.name?.val ?? user.num.val, style: font17),
      onTap: onTap,
    );
  }
}
