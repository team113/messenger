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

import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/user_search_bar/view.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
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
        appBar: CustomAppBar(
          title: Text('label_contacts'.l10n),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 12, right: 14, top: 2),
              child: WidgetButton(
                onPressed: c.toggleSorting,
                child: SizedBox(
                  width: 29.69,
                  height: 21,
                  child: Obx(() {
                    return SvgLoader.asset(
                      'assets/icons/sort_${c.sortByName ? 'abc' : 'time'}.svg',
                      width: 30,
                      height: 21,
                    );
                  }),
                ),
              ),
            ),
          ],
          leading: [
            Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: WidgetButton(
                child: SvgLoader.asset(
                  'assets/icons/search.svg',
                  width: 17.77,
                ),
              ),
            ),
          ],
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
                    ? Center(child: Text('label_no_contacts'.l10n))
                    : ContextMenuInterceptor(
                        child: ListView(
                          controller: ScrollController(),
                          children: [
                            if (c.favorites.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 8),
                                child: Text('label_favorite_contacts'.l10n),
                              ),
                              ...c.favorites.entries
                                  .map((e) => _contact(e.value, c))
                            ],
                            if (c.favorites.isNotEmpty && c.contacts.isNotEmpty)
                              ...divider,
                            ...c.contacts.map((e) => _contact(e, c))
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
  Widget _contact(RxChatContact contact, ContactsTabController c) =>
      ContextMenuRegion(
        preventContextMenu: false,
        actions: [
          ContextMenuButton(
            label: 'btn_rename'.l10n,
            onPressed: () {
              c.contactToChangeNameOf.value = contact.contact.value.id;
              c.contactName.clear();
              c.contactName.unchecked = contact.contact.value.name.val;
              SchedulerBinding.instance.addPostFrameCallback(
                  (_) => c.contactName.focus.requestFocus());
            },
          ),
          ContextMenuButton(
            label: 'btn_delete_from_contacts'.l10n,
            onPressed: () => c.deleteFromContacts(contact.contact.value),
          ),
        ],
        child: c.contactToChangeNameOf.value == contact.contact.value.id
            ? Container(
                key: Key(contact.contact.value.id.val),
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
                key: Key(contact.contact.value.id.val),
                leading: AvatarWidget.fromRxContact(contact),
                title: Text(contact.contact.value.name.val),
                trailing: contact.contact.value.users.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => c.startAudioCall(
                                contact.contact.value.users.first),
                            icon: const Icon(Icons.call),
                          ),
                          IconButton(
                            onPressed: () => c.startVideoCall(
                                contact.contact.value.users.first),
                            icon: const Icon(Icons.video_call),
                          )
                        ],
                      )
                    : null,
                onTap: contact.contact.value.users.isNotEmpty
                    // TODO: Open [Routes.contact] page when it's implemented.
                    ? () => router.user(contact.contact.value.users.first.id)
                    : null,
              ),
      );
}
