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
class ParticipantView extends StatelessWidget {
  const ParticipantView(this._call, this._duration, {Key? key})
      : super(key: key);

  /// The [OngoingCall] that this settings are bound to.
  final Rx<OngoingCall> _call;

  final Rx<Duration> _duration;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: ParticipantController(
        Navigator.of(context).pop,
        _call,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (ParticipantController c) {
        return Obx(() {
          if (c.chat.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          Widget child;

          switch (c.stage.value) {
            case ParticipantsFlowStage.adding:
              child = Obx(() {
                final Iterable<RxChat> recent = c.chats.values
                    .where((e) => e.chat.value.isDialog)
                    .take(1)
                    .where((e) {
                  if (c.query.value != null) {
                    return e.members.values
                            .firstWhereOrNull((m) => m.id != c.me)
                            ?.user
                            .value
                            .name
                            ?.val
                            .contains(c.query.value!) ==
                        true;
                  }

                  return true;
                });

                final Iterable<RxChatContact> contacts =
                    c.contacts.values.where((e) {
                  if (recent
                      .where((c) =>
                          c.members.values.firstWhereOrNull(
                              (m) => m.id == e.user.value?.id) !=
                          null)
                      .isNotEmpty) {
                    return false;
                  }

                  if (c.query.value != null) {
                    return e.contact.value.name.val.contains(c.query.value!);
                  }

                  return true;
                });

                Iterable<RxUser?> users;
                if (c.searchResults.isNotEmpty) {
                  users = c.searchResults.where((e) {
                    if (recent
                        .where((c) =>
                            c.members.values.firstWhereOrNull(
                                (m) => m.id == e.user.value.id) !=
                            null)
                        .isNotEmpty) {
                      return false;
                    }

                    return true;
                  });
                } else {
                  users = c.chats.values.where((e) {
                    if (e.chat.value.isDialog) {
                      RxUser? user = e.members.values
                          .firstWhereOrNull((e) => e.id != c.me);

                      if (recent
                          .where((c) =>
                              c.members.values.firstWhereOrNull(
                                  (m) => m.id == user?.user.value.id) !=
                              null)
                          .isNotEmpty) {
                        return false;
                      }

                      if (c.query.value != null) {
                        return user?.user.value.name?.val
                                .contains(c.query.value!) ==
                            true;
                      }

                      return true;
                    }

                    return false;
                  }).map((e) {
                    return e.members.values
                        .firstWhereOrNull((m) => m.id != c.me);
                  });
                }

                users = users.where((e) =>
                    contacts.where((m) => m.user.value?.id == e?.id).isEmpty);

                Widget _divider(String text) {
                  // return Container(
                  //   padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
                  //   decoration: BoxDecoration(
                  //     // borderRadius: BorderRadius.circular(10),
                  //     // color: Colors.white,
                  //     color: const Color(0xFFF8F8F8),
                  //   ),
                  //   width: double.infinity,
                  //   child: Text(
                  //     text,
                  //     style: const TextStyle(color: Color(0xFF888888)),
                  //   ),
                  // );

                  return Container();

                  return SizedBox(height: 20);

                  return Row(
                    children: [
                      Container(
                        width: 10,
                        height: 1,
                        color: const Color(0xFF888888),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        text,
                        style: thin?.copyWith(fontSize: 13),
                      ),
                      // const SizedBox(width: 5),
                      // Container(
                      //   width: 10,
                      //   height: 1,
                      //   color: const Color(0xFF888888),
                      // ),
                      // Expanded(
                      //   child: Container(
                      //     height: 1,
                      //     color: const Color(0xFF888888),
                      //   ),
                      // ),
                    ],
                  );
                }

                List<Widget> children = [
                  Center(
                    child: Text(
                      'Add participant'.l10n,
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: ReactiveTextField(
                      state: c.search,
                      label: 'Search',
                      style: thin,
                      // prefixIcon: Transform.translate(
                      //   offset: const Offset(3, 1),
                      //   child: const Icon(
                      //     Icons.search,
                      //     color: Color(0xFF63B4FF),
                      //     size: 20,
                      //   ),
                      // ),
                      // prefixIconColor: const Color(0xFF63B4FF),
                      onChanged: () => c.query.value = c.search.text,
                    ),
                  ),
                  // ReactiveTextField(
                  //   padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
                  //   state: c.search,
                  //   dense: true,
                  //   hint: 'Search...',
                  //   prefixIcon: const Icon(
                  //     Icons.search,
                  //     color: Color(0xFF63B4FF),
                  //   ),
                  //   prefixIconColor: const Color(0xFF63B4FF),
                  //   onChanged: () => c.query.value = c.search.text,
                  // ),
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
                                child: Text(
                                  'Recent',
                                  style: thin?.copyWith(
                                    fontSize: 15,
                                    color: const Color(0xFF63B4FF),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              WidgetButton(
                                child: Text(
                                  'Contacts',
                                  style: thin?.copyWith(fontSize: 15),
                                ),
                              ),
                              const SizedBox(width: 20),
                              WidgetButton(
                                child: Text(
                                  'Users',
                                  style: thin?.copyWith(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          'Selected: ${c.selectedContacts.length + c.selectedUsers.length + c.selectedChats.length}',
                          style: thin?.copyWith(fontSize: 15),
                        ),
                        const SizedBox(width: 10),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Flexible(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        if (recent.isNotEmpty) ...[
                          // _divider('Recent'),
                          ...recent.map((e) {
                            bool selected = c.selectedChats.contains(e);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: ContactTile(
                                user: e.members.values
                                    .firstWhereOrNull((e) => e.id != c.me),
                                onTap: () => c.selectChat(e),
                                selected: selected,
                                trailing: [
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: AnimatedSwitcher(
                                      duration: 200.milliseconds,
                                      child: selected
                                          ? const CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFF63B4FF),
                                              radius: 12,
                                              child: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            )
                                          : const CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFFD7D7D7),
                                              radius: 12,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                        if (contacts.isNotEmpty) _divider('Contacts'),
                        ...contacts.map(
                          (e) {
                            bool selected = c.selectedContacts.contains(e);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              child: ContactTile(
                                contact: e,
                                onTap: () => c.selectContact(e),
                                selected: selected,
                                trailing: [
                                  SizedBox(
                                    width: 30,
                                    height: 30,
                                    child: AnimatedSwitcher(
                                      duration: 200.milliseconds,
                                      child: selected
                                          ? const CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFF63B4FF),
                                              radius: 12,
                                              child: Icon(
                                                Icons.check,
                                                color: Colors.white,
                                                size: 14,
                                              ),
                                            )
                                          : const CircleAvatar(
                                              backgroundColor:
                                                  Color(0xFFD7D7D7),
                                              radius: 12,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        if (users.isNotEmpty || c.selectedUsers.isNotEmpty)
                          _divider('Users'),
                        ...[
                          ...c.selectedUsers.where(
                            (p) => users.where((e) => e?.id == p.id).isEmpty,
                          ),
                          ...users,
                        ].map((e) {
                          if (e == null) {
                            return Container();
                          }

                          bool selected = c.selectedUsers.contains(e);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: ContactTile(
                              user: e,
                              onTap: () => c.selectUser(e),
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
                        }),
                        if (recent.isEmpty &&
                            contacts.isEmpty &&
                            users.isEmpty &&
                            c.searchStatus.value.isSuccess)
                          const SizedBox(
                            height: 60,
                            child: Text('Nothing was found'),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedRoundedButton(
                          key: const Key('BackButton'),
                          maxWidth: null,
                          title: Text(
                            'Back',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: Colors.white),
                          ),
                          onPressed: () => c.stage.value = null,
                          color: const Color(0xFF63B4FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() {
                          return OutlinedRoundedButton(
                            key: const Key('AddDialogMembersButton'),
                            maxWidth: null,
                            title: Text(
                              'Add',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: Theme.of(context)
                                  .textTheme
                                  .headline5
                                  ?.copyWith(color: Colors.white),
                            ),
                            onPressed: (c.selectedContacts.isNotEmpty ||
                                        c.selectedChats.isNotEmpty ||
                                        c.selectedUsers.isNotEmpty) &&
                                    c.status.value.isEmpty
                                ? c.addMembers
                                : null,
                            color: (c.selectedContacts.isNotEmpty ||
                                        c.selectedChats.isNotEmpty ||
                                        c.selectedUsers.isNotEmpty) &&
                                    c.status.value.isEmpty
                                ? const Color(0xFF63B4FF)
                                : const Color(0xFFEEEEEE),
                          );
                        }),
                      ),
                    ],
                  ),
                ];

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // const SizedBox(height: 25),
                      const SizedBox(height: 10),
                      ...children,
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              });
              break;

            case ParticipantsFlowStage.addedSuccess:
              List<Widget> children = [
                const Center(child: Text('Success')),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => c.stage.value = null,
                    child: const Text('Close'),
                  ),
                ),
              ];

              child = ListView(
                key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                physics: const ClampingScrollPhysics(),
                children: [
                  const SizedBox(height: 25),
                  ...children,
                  const SizedBox(height: 25),
                ],
              );
              break;

            default:
              List<Widget> children = [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _chat(context, c),
                ),
                const SizedBox(height: 25),
                // const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Participants'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 18),
                Flexible(
                  child: ListView(
                    physics: const ScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    children: c.chat.value!.members.values.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: _user(context, c, e),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 18),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _addParticipant(context, c),
                ),
              ];

              child = Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 25),
                    ...children,
                    const SizedBox(height: 25),
                  ],
                ),
              );
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: child,
          );
        });
      },
    );
  }

  Widget _chat(BuildContext context, ParticipantController c) {
    return Obx(() {
      Style style = Theme.of(context).extension<Style>()!;
      RxChat chat = c.chat.value!;

      var actualMembers = _call.value.members.keys.map((k) => k.userId).toSet();

      return ContextMenuRegion(
        key: Key('ContextMenuRegion_${chat.chat.value.id}'),
        preventContextMenu: false,
        actions: [
          // ContextMenuButton(
          //   key: const Key('ButtonHideChat'),
          //   label: 'btn_hide_chat'.l10n,
          //   onPressed: () => c.hideChat(chat.id),
          // ),
          // if (chat.isGroup)
          //   ContextMenuButton(
          //     key: const Key('ButtonLeaveChat'),
          //     label: 'btn_leave_chat'.l10n,
          //     onPressed: () => c.leaveChat(chat.id),
          //   ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              color: Colors.transparent,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: style.cardRadius,
              color: style.cardColor.darken(0.05),
              child: InkWell(
                borderRadius: style.cardRadius,
                // onTap: () => router.chat(chat.id),
                onTap: () {},
                hoverColor: const Color(0xFFD7ECFF).withOpacity(0.8),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                  child: Row(
                    children: [
                      AvatarWidget.fromRxChat(chat, radius: 30),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    chat.title.value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style:
                                        Theme.of(context).textTheme.headline5,
                                  ),
                                ),
                                // const SizedBox(height: 10),
                                // Text(
                                //   _duration.value.hhMmSs(),
                                //   style: Theme.of(context).textTheme.subtitle2,
                                // ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 3),
                              child: Row(
                                children: [
                                  Text(
                                    '${actualMembers.length + 1} of ${c.chat.value?.members.length}',
                                    style:
                                        Theme.of(context).textTheme.subtitle2,
                                  ),
                                  const Spacer(),
                                  Text(
                                    _duration.value.hhMmSs(),
                                    style:
                                        Theme.of(context).textTheme.subtitle2,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ),
                            ),
                          ],
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
    });
  }

  Widget _user(BuildContext context, ParticipantController c, RxUser user) {
    return ContactTile(
      user: user,
      onTap: () {},
      trailing: [
        Obx(() {
          bool inCall = user.id == c.me ||
              _call.value.members.keys
                  .where((e) => e.userId == user.id)
                  .isNotEmpty;

          if (!inCall) {
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: const Color(0xFF63B4FF),
                  type: MaterialType.circle,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(60),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: SvgLoader.asset(
                          'assets/icons/audio_call_start.svg',
                          width: 13,
                          height: 13,
                        ),
                      ),
                    ),
                  ),
                ));

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: WidgetButton(
                onPressed: () {},
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF63B4FF),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgLoader.asset(
                      'assets/icons/audio_call_start.svg',
                      width: 13,
                      height: 13,
                    ),
                  ),
                ),
              ),
            );

            // return Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 6),
            //   child: ElevatedButton(
            //     onPressed: () {},
            //     child: Row(
            //       mainAxisSize: MainAxisSize.min,
            //       children: [
            //         const Icon(
            //           Icons.call,
            //           size: 21,
            //           color: Colors.white,
            //         ),
            //         const SizedBox(width: 5),
            //         Flexible(
            //           child: Text(
            //             'Call'.l10n,
            //             maxLines: 1,
            //             overflow: TextOverflow.ellipsis,
            //           ),
            //         ),
            //       ],
            //     ),
            //   ),
            // );
          }

          return Container();
        }),
      ],
    );
  }

  Widget _addParticipant(BuildContext context, ParticipantController c) {
    return OutlinedRoundedButton(
      maxWidth: null,
      title: Text(
        'Add participant',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: Theme.of(context)
            .textTheme
            .headline5
            ?.copyWith(color: Colors.white),
      ),
      onPressed: () {
        c.status.value = RxStatus.empty();
        c.selectedContacts.clear();
        c.selectedUsers.clear();
        c.stage.value = ParticipantsFlowStage.adding;
      },
      color: const Color(0xFF63B4FF),
    );
  }
}
