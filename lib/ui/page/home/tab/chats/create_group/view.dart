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

import '/l10n/l10n.dart';
import '/ui/page/home/page/chat/widget/add_contact_list_tile.dart';
import '/ui/page/home/page/chat/widget/add_user_list_tile.dart';
import '/ui/page/home/widget/user_search_bar/view.dart';
import 'controller.dart';

/// View of the group creation overlay.
class CreateGroupView extends StatelessWidget {
  const CreateGroupView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);
    TextStyle font13 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(
            color: Colors.black, fontSize: 13);

    Widget divider = Container(
      margin: const EdgeInsets.symmetric(horizontal: 9),
      color: const Color(0x99000000),
      height: 1,
      width: double.infinity,
    );

    return MediaQuery.removeViewInsets(
      removeLeft: true,
      removeTop: true,
      removeRight: true,
      removeBottom: true,
      context: context,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 600,
            maxHeight: 500,
          ),
          child: Material(
            color: const Color(0xFFFFFFFF),
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            type: MaterialType.card,
            child: GetBuilder(
              init: CreateGroupController(
                Navigator.of(context).pop,
                Get.find(),
                Get.find(),
              ),
              builder: (CreateGroupController c) => Obx(
                () => c.status.value.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          const SizedBox(height: 5),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 5, 0),
                            child: Row(
                              children: [
                                Text('label_create_group'.td, style: font17),
                                const Spacer(),
                                IconButton(
                                  hoverColor: Colors.transparent,
                                  highlightColor: Colors.transparent,
                                  splashColor: Colors.transparent,
                                  onPressed: Navigator.of(context).pop,
                                  icon: const Icon(Icons.close, size: 20),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 5),
                          divider,
                          Expanded(
                            child: UserSearchBar(
                              onUserTap: c.selectUser,
                              body: Column(
                                children: [
                                  Expanded(
                                    child: ListView(
                                      children: [
                                        ...c.selectedUsers.map(
                                          (e) => AddUserListTile(
                                            e,
                                            () => c.unselectUser(e),
                                          ),
                                        ),
                                        ...c.contacts.entries
                                            .where((e) => e.value.contact.value
                                                .users.isNotEmpty)
                                            .map(
                                          (e) {
                                            bool selected = c.selectedContacts
                                                .contains(e.value);
                                            return AddContactListTile(
                                              selected,
                                              e.value,
                                              () => c.selectContact(e.value),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                  divider,
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: TextField(
                                      onChanged: (s) => c.groupChatName = s,
                                      decoration: InputDecoration(
                                        labelText: 'label_name'.td,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                    ),
                                  ),
                                  divider,
                                  const SizedBox(height: 5),
                                  Padding(
                                    padding:
                                        const EdgeInsets.fromLTRB(18, 0, 5, 0),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 8),
                                          child: Text(
                                            '${'label_create_group_selected'.td}'
                                            ' ${c.selectedContacts.length + c.selectedUsers.length} '
                                            '${'label_create_group_users'.td}',
                                            style: font13,
                                          ),
                                        ),
                                        c.status.value.isError
                                            ? Expanded(
                                                child: Center(
                                                  child: Text(
                                                    c.status.value
                                                            .errorMessage ??
                                                        'err_unknown'.td,
                                                    style: font13.copyWith(
                                                        color: Colors.red),
                                                  ),
                                                ),
                                              )
                                            : const Spacer(),
                                        TextButton(
                                          onPressed:
                                              c.selectedContacts.isEmpty &&
                                                      c.selectedUsers.isEmpty
                                                  ? null
                                                  : c.createGroup,
                                          child: Text(
                                            'btn_create_group'.td,
                                            style: c.selectedContacts.isEmpty &&
                                                    c.selectedUsers.isEmpty
                                                ? font17.copyWith(
                                                    color: Colors.grey)
                                                : font17,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
