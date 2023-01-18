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
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/routes.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/home/widget/contact_tile.dart';
import 'controller.dart';

/// View of the chat member addition modal.
class SearchContactView extends StatelessWidget {
  const SearchContactView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: SearchContactController(Get.find(), Get.find(), Get.find()),
      builder: (SearchContactController c) {
        Widget tile({
          RxUser? user,
          RxChatContact? contact,
          void Function()? onTap,
        }) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ContactTile(contact: contact, user: user, onTap: onTap),
          );
        }

        List<Widget> children = [
          Center(
            child:
                Text('Add contact'.l10n, style: thin?.copyWith(fontSize: 18)),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Center(
              child: ReactiveTextField(
                state: c.search,
                label: 'Search',
                style: thin,
                onChanged: () => c.query.value = c.search.text,
              ),
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            height: 15,
            child: Row(
              children: [
                const SizedBox(width: 10),
                Expanded(
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    shrinkWrap: true,
                    children: [
                      WidgetButton(
                        onPressed: () => c.jumpTo(0),
                        child: Obx(() {
                          return Text(
                            'Contacts',
                            style: thin?.copyWith(
                              fontSize: 15,
                              color: c.selected.value == 0
                                  ? const Color(0xFF63B4FF)
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(width: 20),
                      WidgetButton(
                        onPressed: () => c.jumpTo(1),
                        child: Obx(() {
                          return Text(
                            'Users',
                            style: thin?.copyWith(
                              fontSize: 15,
                              color: c.selected.value == 1
                                  ? const Color(0xFF63B4FF)
                                  : null,
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                // Obx(() {
                //   return Row(
                //     mainAxisSize: MainAxisSize.min,
                //     children: [
                //       Text(
                //         'Selected: ',
                //         style: thin?.copyWith(fontSize: 15),
                //       ),
                //       Container(
                //         constraints: const BoxConstraints(minWidth: 14),
                //         child: Text(
                //           '${c.selectedContacts.length + c.selectedUsers.length}',
                //           style: thin?.copyWith(fontSize: 15),
                //         ),
                //       ),
                //     ],
                //   );
                // }),
                const SizedBox(width: 10),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: Obx(() {
              if (c.contacts.isEmpty && c.users.isEmpty) {
                if (c.searchStatus.value.isSuccess) {
                  return const Center(child: Text('Nothing was found'));
                } else if (c.searchStatus.value.isEmpty) {
                  return const Center(
                    child: Text('Use search to find a contact'),
                  );
                }

                return const Center(child: CustomProgressIndicator());
              }

              return FlutterListView(
                controller: c.controller,
                delegate: FlutterListViewDelegate(
                  (context, i) {
                    dynamic e = c.getIndex(i);

                    if (e is RxUser) {
                      return tile(
                        user: e,
                        onTap: () {
                          router.user(e.id);
                          Navigator.of(context).pop();
                        },
                      );
                    } else if (e is RxChatContact) {
                      return tile(
                        contact: e,
                        onTap: () {
                          if (e.user.value != null) {
                            router.user(e.user.value!.id);
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    }

                    return Container();
                  },
                  childCount: c.contacts.length + c.users.length,
                ),
              );
            }),
          ),
        ];

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 2),
          constraints: const BoxConstraints(maxHeight: 650),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              const SizedBox(height: 16),
              ...children,
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }
}
