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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/ui/widget/text_field.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/ui/widget/svg/svg.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/add_user_list_tile.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/outlined_rounded_button.dart';
import 'controller.dart';

/// View of the chat member addition modal.
class CreateGroupView extends StatelessWidget {
  const CreateGroupView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: CreateGroupController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        pop: Navigator.of(context).pop,
      ),
      builder: (CreateGroupController c) {
        return Obx(() {
          Widget _tile({
            RxUser? user,
            RxChatContact? contact,
            void Function()? onTap,
            bool selected = false,
          }) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: ContactTile(
                contact: contact,
                user: user,
                onTap: onTap,
                selected: selected,
                trailing: [
                  SizedBox(
                    width: 30,
                    height: 30,
                    child: AnimatedSwitcher(
                      duration: 200.milliseconds,
                      child: selected
                          ? const CircleAvatar(
                              backgroundColor: Color(0xFF63B4FF),
                              radius: 12,
                              child: Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              ),
                            )
                          : const CircleAvatar(
                              backgroundColor: Color(0xFFD7D7D7),
                              radius: 12,
                            ),
                    ),
                  ),
                ],
              ),
            );
          }

          Widget _chat({
            required RxChat chat,
            void Function()? onTap,
            bool selected = false,
          }) {
            Style style = Theme.of(context).extension<Style>()!;

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: SizedBox(
                height: 84,
                child: ContextMenuRegion(
                  key: Key('ContextMenuRegion_${chat.chat.value.id}'),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: style.cardRadius,
                      border: style.cardBorder,
                      color: Colors.transparent,
                    ),
                    child: Material(
                      type: MaterialType.card,
                      borderRadius: style.cardRadius,
                      color: selected
                          ? const Color(0xFFD7ECFF).withOpacity(0.8)
                          : style.cardColor.darken(0.05),
                      child: InkWell(
                        borderRadius: style.cardRadius,
                        onTap: onTap,
                        hoverColor: selected
                            ? const Color(0x00D7ECFF)
                            : const Color(0xFFD7ECFF).withOpacity(0.8),
                        child: Padding(
                          padding:
                              const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                          child: Row(
                            children: [
                              AvatarWidget.fromRxChat(chat, radius: 26),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  chat.title.value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                              ),
                              SizedBox(
                                width: 30,
                                height: 30,
                                child: AnimatedSwitcher(
                                  duration: 200.milliseconds,
                                  child: selected
                                      ? const CircleAvatar(
                                          backgroundColor: Color(0xFF63B4FF),
                                          radius: 12,
                                          child: Icon(
                                            Icons.check,
                                            color: Colors.white,
                                            size: 14,
                                          ),
                                        )
                                      : const CircleAvatar(
                                          backgroundColor: Color(0xFFD7D7D7),
                                          radius: 12,
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
              ),
            );
          }

          List<Widget> children = [
            Center(
              child: Text(
                'Create group'.l10n,
                style: thin?.copyWith(fontSize: 18),
              ),
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
                              'Chats',
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
                              'Contacts',
                              style: thin?.copyWith(
                                fontSize: 15,
                                color: c.selected.value == 1
                                    ? const Color(0xFF63B4FF)
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 20),
                        WidgetButton(
                          onPressed: () => c.jumpTo(2),
                          child: Obx(() {
                            return Text(
                              'Users',
                              style: thin?.copyWith(
                                fontSize: 15,
                                color: c.selected.value == 2
                                    ? const Color(0xFF63B4FF)
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Selected: ',
                          style: thin?.copyWith(fontSize: 15),
                        ),
                        Container(
                          constraints: const BoxConstraints(minWidth: 14),
                          child: Text(
                            '${c.selectedContacts.length + c.selectedUsers.length + c.selectedChats.length}',
                            style: thin?.copyWith(fontSize: 15),
                          ),
                        ),
                      ],
                    );
                  }),
                  const SizedBox(width: 10),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Obx(() {
                if (c.chats.isEmpty && c.contacts.isEmpty && c.users.isEmpty) {
                  if (c.searchStatus.value.isSuccess) {
                    return const Center(child: Text('Nothing was found'));
                  } else if (c.searchStatus.value.isEmpty) {
                    return const Center(
                      child: Text('Use search to find an user or a chat'),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                }

                return FlutterListView(
                  controller: c.controller,
                  // shrinkWrap: true,
                  delegate: FlutterListViewDelegate(
                    (context, i) {
                      dynamic e = c.getIndex(i);

                      if (e is RxUser) {
                        return Obx(() {
                          return _tile(
                            user: e,
                            selected: c.selectedUsers.contains(e),
                            onTap: () => c.selectUser(e),
                          );
                        });
                      } else if (e is RxChatContact) {
                        return Obx(() {
                          return _tile(
                            contact: e,
                            selected: c.selectedContacts.contains(e),
                            onTap: () => c.selectContact(e),
                          );
                        });
                      } else if (e is RxChat) {
                        return Obx(() {
                          return _chat(
                            chat: e,
                            selected: c.selectedChats.contains(e),
                            onTap: () => c.selectChat(e),
                          );
                        });
                      }

                      return Container();
                    },
                    childCount:
                        c.contacts.length + c.users.length + c.chats.length,
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Obx(() {
                      bool enabled = (c.selectedContacts.isNotEmpty ||
                              c.selectedUsers.isNotEmpty ||
                              c.selectedChats.isNotEmpty) &&
                          c.status.value.isEmpty;

                      return OutlinedRoundedButton(
                        key: const Key('AddDialogMembersButton'),
                        maxWidth: null,
                        title: Text(
                          'Create group',
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: TextStyle(
                            color: enabled ? Colors.white : Colors.black,
                          ),
                        ),
                        onPressed: enabled ? c.createGroup : null,
                        color: enabled
                            ? const Color(0xFF63B4FF)
                            : const Color(0xFFEEEEEE),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ];

          Widget child = Stack(
            children: [
              Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
                constraints: const BoxConstraints(maxHeight: 650),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    const SizedBox(height: 16),
                    ...children,
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Positioned.fill(
                child: Obx(() {
                  return AnimatedSwitcher(
                    duration: 300.milliseconds,
                    child: c.status.value.isLoading
                        ? Container(
                            color: const Color(0x33000000),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : const IgnorePointer(child: SizedBox()),
                  );
                }),
              ),
            ],
          );

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: child,
          );
        });
      },
    );
  }
}
