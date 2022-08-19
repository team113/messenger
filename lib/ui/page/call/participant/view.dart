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
      ),
      builder: (ParticipantController c) {
        return Obx(() {
          if (c.chat.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          Widget child;

          switch (c.stage.value) {
            case ParticipantsFlowStage.adding:
              List<Widget> children = [
                _chat(context, c),
                const SizedBox(height: 6),
                Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ...c.selectedUsers.map(
                        (e) => AddUserListTile(e, () => c.unselectUser(e)),
                      ),
                      ...c.contacts.entries
                          .where((e) => e.value.contact.value.users.isNotEmpty)
                          .where((e) =>
                              c.chat.value!.members.values.firstWhereOrNull(
                                  (m) =>
                                      e.value.contact.value.users
                                          .firstWhereOrNull(
                                              (u) => u.id == m.id) !=
                                      null) ==
                              null)
                          .map(
                        (e) {
                          bool selected = c.selectedContacts.contains(e.value);
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: ContactTile(
                              contact: e.value,
                              onTap: () => c.selectContact(e.value),
                              selected: selected,
                              trailing: [
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: selected
                                        ? const CircleAvatar(
                                            backgroundColor: Color(0xBB165084),
                                            radius: 12,
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          )
                                        : Container(),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedRoundedButton(
                        key: const Key('BackButton'),
                        maxWidth: null,
                        title: Text(
                          'Cancel',
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
                            'Add participants',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: Theme.of(context)
                                .textTheme
                                .headline5
                                ?.copyWith(color: Colors.white),
                          ),
                          onPressed: (c.selectedContacts.isNotEmpty ||
                                      c.selectedUsers.isNotEmpty) &&
                                  c.status.value.isEmpty
                              ? c.addMembers
                              : null,
                          color: (c.selectedContacts.isNotEmpty ||
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

              child = ListView(
                key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                physics: const ClampingScrollPhysics(),
                children: [
                  const SizedBox(height: 12),
                  ...children,
                  const SizedBox(height: 25 + 12),
                ],
              );
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
                  const SizedBox(height: 12),
                  ...children,
                  const SizedBox(height: 25 + 12),
                ],
              );
              break;

            default:
              List<Widget> children = [
                _chat(context, c),
                const SizedBox(height: 25),
                const SizedBox(height: 14),
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
                    children: c.chat.value!.members.values.map((e) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        child: _user(context, c, e),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 25),
                _addParticipant(context, c),
              ];

              child = Container(
                margin: const EdgeInsets.all(8),
                key: Key('${c.stage.value?.name.capitalizeFirst}Stage'),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 12),
                    ...children,
                    const SizedBox(height: 25 + 12),
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
      trailing: [
        Obx(() {
          bool inCall = user.id == c.me ||
              _call.value.members.keys
                  .where((e) => e.userId == user.id)
                  .isNotEmpty;

          if (!inCall) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: WidgetButton(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                      // color: Color(0xFF63B4FF),
                      // shape: BoxShape.circle,
                      ),
                  child: Center(
                    child: SvgLoader.asset(
                      'assets/icons/chat_audio_call.svg',
                      width: 21,
                      height: 21,
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
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          child: WidgetButton(
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                  // color: Color(0xFF63B4FF),
                  // shape: BoxShape.circle,
                  ),
              child: Center(
                child: Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: const Color(0xFFFF6060),
                ),
                // child: SvgLoader.asset(
                //   'assets/icons/delete.svg',
                //   width: 27.21 * 0.4,
                //   height: 26 * 0.4,
                // ),
              ),
            ),
          ),
        ),
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
