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
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';

import '/domain/model/contact.dart';
import '/domain/repository/user.dart';
import '/routes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/user_search_bar/view.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';

/// View of the `HomeTab.contacts` tab.
class ContactsTabView extends StatelessWidget {
  const ContactsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> divider = [
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        color: const Color(0xFFE0E0E0),
        height: 0.5,
      ),
      const SizedBox(height: 10),
    ];

    return GetBuilder(
      key: const Key('ContactsTab'),
      init: ContactsTabController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (ContactsTabController c) => Scaffold(
        appBar: AppBar(
          title: Text('label_contacts'.tr),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0.5),
            child: Container(
              color: const Color(0xFFE0E0E0),
              height: 0.5,
            ),
          ),
        ),
        body: Obx(
          () => UserSearchBar(
            onUserTap: (user) => router.user(user.id),
            // TODO: Show an `add` icon only if user is not in contacts already.
            //       E.g. by looking if `MyUser.contacts` field is empty or not.
            trailingIcon: const Icon(Icons.person_add),
            onTrailingTap: c.addToContacts,
            body: c.contactsReady.value
                ? c.favorites.isEmpty && c.contacts.isEmpty
                    ? Center(child: Text('label_no_contacts'.tr))
                    : ContextMenuInterceptor(
                        child: ListView(
                          controller: ScrollController(),
                          children: [
                            if (c.favorites.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                child: Text('label_favorite_contacts'.tr),
                              ),
                              ...c.favorites.entries
                                  .map((e) => _contact(e.value.value, c))
                            ],
                            if (c.favorites.isNotEmpty && c.contacts.isNotEmpty)
                              ...divider,
                            ...c.contacts.entries
                                .map((e) => _contact(e.value.value, c))
                          ],
                        ),
                      )
                : const Center(child: CircularProgressIndicator()),
          ),
        ),
      ),
    );
  }

  /// Returns a [ListTile] with [contact]'s information.
  Widget _contact(ChatContact contact, ContactsTabController c) =>
      ContextMenuRegion(
        preventContextMenu: false,
        menu: ContextMenu(
          actions: [
            ContextMenuButton(
              label: 'btn_change_contact_name'.tr,
              onPressed: () {
                c.contactToChangeNameOf.value = contact.id;
                c.contactName.clear();
                c.contactName.unchecked = contact.name.val;
                SchedulerBinding.instance.addPostFrameCallback(
                    (_) => c.contactName.focus.requestFocus());
              },
            ),
            ContextMenuButton(
              label: 'btn_delete_from_contacts'.tr,
              onPressed: () => c.deleteFromContacts(contact),
            ),
          ],
        ),
        child: c.contactToChangeNameOf.value == contact.id
            ? Container(
                key: Key(contact.id.val),
                padding: const EdgeInsets.all(3),
                child: Row(
                  children: [
                    IconButton(
                      key: const Key('CancelSaveNewContactName'),
                      onPressed: () => c.contactToChangeNameOf.value = null,
                      icon: const Icon(Icons.close),
                    ),
                    Expanded(
                      child: ReactiveTextField(
                        dense: true,
                        key: const Key('NewContactNameInput'),
                        state: c.contactName,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              )
            : ListTile(
                key: Key(contact.id.val),
                leading: contact.users.isNotEmpty
                    ? FutureBuilder<RxUser?>(
                        future: c.getUser(contact.users.first.id),
                        builder: (_, u) => u.hasData
                            ? Obx(
                                () => AvatarWidget.fromContact(
                                  contact,
                                  avatar: u.data?.user.value.avatar,
                                ),
                              )
                            : AvatarWidget.fromContact(contact),
                      )
                    : AvatarWidget.fromContact(contact),
                title: Text(contact.name.val),
                trailing: contact.users.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () =>
                                c.startAudioCall(contact.users.first),
                            icon: const Icon(Icons.call),
                          ),
                          IconButton(
                            onPressed: () =>
                                c.startVideoCall(contact.users.first),
                            icon: const Icon(Icons.video_call),
                          )
                        ],
                      )
                    : null,
                onTap: contact.users.isNotEmpty
                    // TODO: Open [Routes.contact] page when it's implemented.
                    ? () => router.user(contact.users.first.id)
                    : null,
              ),
      );
}
