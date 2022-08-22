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

import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
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
      ),
      builder: (ContactsTabController c) => Scaffold(
        // backgroundColor: Colors.white,
        // backgroundColor: const Color(0xFFF5F8FA),
        appBar: AppBar(
          // backgroundColor: const Color(0xFFF9FBFB),
          title: Text(
            'label_contacts'.l10n,
            style: Theme.of(context).textTheme.caption?.copyWith(
                  color: Colors.black,
                  fontWeight: FontWeight.w300,
                  fontSize: 18,
                ),
          ),
          leading: IconButton(
            splashColor: Colors.transparent,
            hoverColor: Colors.transparent,
            highlightColor: Colors.transparent,
            onPressed: () {},
            icon: SvgLoader.asset('assets/icons/search.svg', width: 17.77),
          ),
          // bottom: PreferredSize(
          //   preferredSize: const Size.fromHeight(0.5),
          //   child: Container(
          //     color: const Color(0xFFE0E0E0),
          //     height: 0.5,
          //   ),
          // ),
        ),
        extendBodyBehindAppBar: false,
        extendBody: false,
        body: Obx(() {
          if (!c.contactsReady.value) {
            return UserSearchBar(
              onUserTap: (user) => router.user(user.id),
              // TODO: Show an `add` icon only if user is not in contacts already.
              //       E.g. by looking if `MyUser.contacts` field is empty or not.
              trailingIcon: const Icon(Icons.person_add),
              onTrailingTap: c.addToContacts,
              body: const Center(child: CircularProgressIndicator()),
            );
          }

          if (c.favorites.isEmpty && c.contacts.isEmpty) {
            return UserSearchBar(
              onUserTap: (user) => router.user(user.id),
              // TODO: Show an `add` icon only if user is not in contacts already.
              //       E.g. by looking if `MyUser.contacts` field is empty or not.
              trailingIcon: const Icon(Icons.person_add),
              onTrailingTap: c.addToContacts,
              body: Center(child: Text('label_no_contacts'.l10n)),
            );
          }

          var metrics = MediaQuery.of(context);
          return UserSearchBar(
            onUserTap: (user) => router.user(user.id),
            // TODO: Show an `add` icon only if user is not in contacts already.
            //       E.g. by looking if `MyUser.contacts` field is empty or not.
            trailingIcon: const Icon(Icons.person_add),
            onTrailingTap: c.addToContacts,
            body: Padding(
              padding: const EdgeInsets.only(top: 10, bottom: 10),
              child: ContextMenuInterceptor(
                child: ListView(
                  padding: const EdgeInsets.only(
                    left: 10,
                    right: 10,
                  ),
                  controller: ScrollController(),
                  children: [
                    if (c.favorites.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        child: Text('label_favorite_contacts'.l10n),
                      ),
                      ...c.favorites.entries
                          .map((e) => _contact(context, e.value, c))
                    ],
                    if (c.favorites.isNotEmpty && c.contacts.isNotEmpty)
                      ...divider,
                    ...c.contacts.entries
                        .map((e) => _contact(context, e.value, c)),
                    const SizedBox(height: 60),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  /// Returns a [ListTile] with [contact]'s information.
  Widget _contact(
    BuildContext context,
    RxChatContact contact,
    ContactsTabController c,
  ) {
    if (c.contactToChangeNameOf.value == contact.contact.value.id) {
      return Container(
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
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: ContactTile(
        contact: contact,
        darken: 0,
        onTap: contact.contact.value.users.isNotEmpty
            // TODO: Open [Routes.contact] page when it's implemented.
            ? () => router.user(contact.contact.value.users.first.id)
            : null,
        actions: [
          ContextMenuButton(
            label: 'btn_change_contact_name'.l10n,
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
        trailing: [
          if (contact.contact.value.users.isNotEmpty) ...[
            IconButton(
              onPressed: () =>
                  c.startAudioCall(contact.contact.value.users.first),
              icon: Icon(
                Icons.call,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            IconButton(
              onPressed: () =>
                  c.startVideoCall(contact.contact.value.users.first),
              icon: Icon(
                Icons.video_call,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ]
        ],
      ),
    );

    return ContextMenuRegion(
      preventContextMenu: false,
      actions: [
        ContextMenuButton(
          label: 'btn_change_contact_name'.l10n,
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
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: contact.contact.value.users.isNotEmpty
                    // TODO: Open [Routes.contact] page when it's implemented.
                    ? () => router.user(contact.contact.value.users.first.id)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                  child: Row(
                    children: [
                      AvatarWidget.fromRxContact(contact, radius: 25),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              contact.contact.value.name.val,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context).textTheme.headline5,
                            ),
                          ],
                        ),
                      ),
                      if (contact.contact.value.users.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => c.startAudioCall(
                                  contact.contact.value.users.first),
                              icon: Icon(
                                Icons.call,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            IconButton(
                              onPressed: () => c.startVideoCall(
                                  contact.contact.value.users.first),
                              icon: Icon(
                                Icons.video_call,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            )
                          ],
                        )
                    ],
                  ),
                ),
              ),
            ),
      /*ListTile(
                key: Key(contact.contact.value.id.val),
                leading: Obx(
                  () => Badge(
                    showBadge: contact.user.value?.user.value.online == true,
                    badgeContent: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      padding: const EdgeInsets.all(5),
                    ),
                    padding: const EdgeInsets.all(2),
                    badgeColor: Colors.white,
                    animationType: BadgeAnimationType.scale,
                    position: BadgePosition.bottomEnd(bottom: 0, end: 0),
                    elevation: 0,
                    child: AvatarWidget.fromContact(
                      contact.contact.value,
                      avatar: contact.user.value?.user.value.avatar,
                    ),
                  ),
                ),
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
              ),*/
    );
  }
}
