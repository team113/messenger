// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import '/domain/model/contact.dart';
import '/ui/page/home/widget/avatar.dart';

/// [ListTile] with an information of a [ChatContact].
class AddContactListTile extends StatelessWidget {
  const AddContactListTile(this.selected, this.contact, this.onTap, {Key? key})
      : super(key: key);

  /// Indicator whether this [contact] is selected.
  final bool selected;

  /// [ChatContact] this [AddContactListTile] is about.
  final Rx<ChatContact> contact;

  /// Callback, called when this [ListTile] is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);

    return ListTile(
      leading: AnimatedSwitcher(
        duration: const Duration(milliseconds: 100),
        child: selected
            ? const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.check, color: Colors.white),
              )
            : AvatarWidget.fromContact(contact.value),
      ),
      selected: selected,
      selectedTileColor: const Color(0x11000000),
      title: Text(contact.value.name.val, style: font17),
      onTap: onTap,
    );
  }
}
