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

import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/fluent/extension.dart';
import '/ui/page/home/page/chat/widget/add_contact_list_tile.dart';
import '/ui/page/home/page/chat/widget/add_user_list_tile.dart';
import '/ui/page/home/widget/user_search_bar/view.dart';
import 'controller.dart';

/// View of the dialog member addition modal.
class AddDialogMemberView extends StatelessWidget {
  const AddDialogMemberView(this.chatId, this._currentCall, {Key? key})
      : super(key: key);

  /// ID of the [Chat] this page is about.
  final ChatId chatId;

  /// Current [OngoingCall].
  final Rx<OngoingCall> _currentCall;

  /// [Container] representing a divider for content.
  static final Widget _divider = Container(
    margin: const EdgeInsets.symmetric(horizontal: 9),
    color: const Color(0x99000000),
    height: 1,
    width: double.infinity,
  );

  @override
  Widget build(BuildContext context) {
    TextStyle font17 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(color: Colors.black);
    TextStyle font13 = context.theme.outlinedButtonTheme.style!.textStyle!
        .resolve({MaterialState.disabled})!.copyWith(
            color: Colors.black, fontSize: 13);

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
          child: Scaffold(
            backgroundColor: Colors.transparent,
            body: Material(
              color: const Color(0xFFFFFFFF),
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              type: MaterialType.card,
              child: GetBuilder(
                init: AddDialogMemberController(
                  Navigator.of(context).pop,
                  chatId,
                  _currentCall,
                  Get.find(),
                  Get.find(),
                  Get.find(),
                ),
                builder: (AddDialogMemberController c) => Obx(
                  () => c.status.value.isLoading || c.chat.value == null
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            const SizedBox(height: 5),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 5, 0),
                              child: Row(
                                children: [
                                  Text(
                                    'label_add_chat_member'.td(),
                                    style: font17,
                                  ),
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
                            _divider,
                            _userSearchBar(c, font17, font13),
                            const SizedBox(height: 5),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns an [Expanded] with an [UserSearchBar] in it.
  Expanded _userSearchBar(
    AddDialogMemberController c,
    TextStyle font17,
    TextStyle font13,
  ) {
    return Expanded(
      child: UserSearchBar(
        onUserTap: c.selectUser,
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  ...c.selectedUsers.map(
                    (e) => AddUserListTile(e, () => c.unselectUser(e)),
                  ),
                  ...c.contacts.entries
                      .where((e) => e.value.contact.value.users.isNotEmpty)
                      .where((e) =>
                          c.chat.value!.value.members.firstWhereOrNull((m) =>
                              e.value.contact.value.users
                                  .firstWhereOrNull((u) => u.id == m.user.id) !=
                              null) ==
                          null)
                      .map(
                    (e) {
                      bool selected = c.selectedContacts.contains(e.value);
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
            _divider,
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 5, 0),
              child: Row(
                children: [
                  Flexible(
                    fit: FlexFit.tight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '${'label_create_group_selected'.td()}'
                        ' ${c.selectedContacts.length + c.selectedUsers.length} '
                        '${'label_create_group_users'.td()}',
                        style: font13,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  c.status.value.isError
                      ? Expanded(
                          child: Center(
                            child: Text(
                              c.status.value.errorMessage ?? 'err_unknown'.td(),
                              style: font13.copyWith(color: Colors.red),
                            ),
                          ),
                        )
                      : const Spacer(),
                  TextButton(
                    key: const Key('AddDialogMembersButton'),
                    onPressed:
                        c.selectedContacts.isEmpty && c.selectedUsers.isEmpty
                            ? null
                            : c.transformDialogCallIntoGroupCall,
                    child: Text(
                      'btn_add_participant'.td(),
                      style:
                          c.selectedContacts.isEmpty && c.selectedUsers.isEmpty
                              ? font17.copyWith(color: Colors.grey)
                              : font17,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
