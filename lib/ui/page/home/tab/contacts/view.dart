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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/user_search_bar/view.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
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
      ),
      builder: (ContactsTabController c) => Scaffold(
        appBar: AppBar(
          title: Text('label_contacts'.l10n),
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
                              ...c.favorites.map((e) => _contact(context, e, c))
                            ],
                            if (c.favorites.isNotEmpty && c.contacts.isNotEmpty)
                              ...divider,
                            ...c.contacts.entries
                                .map((e) => _contact(context, e.value, c))
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
  Widget _contact(
    BuildContext context,
    RxChatContact contact,
    ContactsTabController c,
  ) {
    bool favorite = c.favorites.contains(contact);

    final bool selected = router.routes
            .lastWhereOrNull((e) => e.startsWith(Routes.user))
            ?.startsWith('${Routes.user}/${contact.user.value?.id}') ==
        true;

    return Padding(
      key: Key('Contact_${contact.id}'),
      padding: const EdgeInsets.only(left: 10, right: 10),
      child: ContactTile(
        contact: contact,
        folded: favorite,
        selected: selected,
        onTap: contact.contact.value.users.isNotEmpty
            // TODO: Open [Routes.contact] page when it's implemented.
            ? () => router.user(contact.user.value!.id)
            : null,
        actions: [
          favorite
              ? ContextMenuButton(
                  key: const Key('UnfavoriteContactButton'),
                  label: 'btn_delete_from_favorites'.l10n,
                  onPressed: () =>
                      c.unfavoriteContact(contact.contact.value.id),
                )
              : ContextMenuButton(
                  key: const Key('FavoriteContactButton'),
                  label: 'btn_add_to_favorites'.l10n,
                  onPressed: () => c.favoriteContact(contact.contact.value.id),
                ),
          ContextMenuButton(
            label: 'btn_delete_from_contacts'.l10n,
            onPressed: () => c.deleteFromContacts(contact.contact.value),
          ),
        ],
        subtitle: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Obx(() {
              final subtitle = contact.user.value?.user.value.getStatus();
              if (subtitle != null) {
                return Text(
                  subtitle,
                  style: const TextStyle(color: Color(0xFF888888)),
                );
              }
              return Container();
            }),
          ),
        ],
      ),
    );
  }
}
