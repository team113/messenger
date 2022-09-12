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
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import 'controller.dart';

/// View of the chat members addition modal.
class ParticipantsView extends StatelessWidget {
  const ParticipantsView(this._call, this._duration, {Key? key})
      : super(key: key);

  /// The [OngoingCall] that this modal are bound to.
  final Rx<OngoingCall> _call;

  /// Duration of the [_call].
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

          Widget tile({
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

          Widget child;

          switch (c.stage.value) {
            case ParticipantsFlowStage.adding:
              List<Widget> children = [
                Center(
                  child: Text(
                    'Add participant'.l10n,
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
                                  'Recent',
                                  style: thin?.copyWith(
                                    fontSize: 15,
                                    color: c.selected.value ==
                                            SearchResultPart.recent
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
                                    color: c.selected.value ==
                                            SearchResultPart.contacts
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
                                    color: c.selected.value ==
                                            SearchResultPart.users
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
                                '${c.selectedContacts.length + c.selectedUsers.length}',
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
                    if (c.recent.isEmpty &&
                        c.contacts.isEmpty &&
                        c.users.isEmpty) {
                      if (c.searchStatus.value.isSuccess) {
                        return const Center(child: Text('Nothing was found'));
                      } else if (c.searchStatus.value.isEmpty) {
                        return const Center(
                          child: Text('Use search to find an user'),
                        );
                      }

                      return const Center(child: CircularProgressIndicator());
                    }

                    return FlutterListView(
                      controller: c.controller,
                      delegate: FlutterListViewDelegate(
                        (context, i) {
                          dynamic e = c.getIndex(i);

                          if (e is RxUser) {
                            return Obx(() {
                              return tile(
                                user: e,
                                selected: c.selectedUsers.contains(e),
                                onTap: () => c.selectUser(e),
                              );
                            });
                          } else if (e is RxChatContact) {
                            return Obx(() {
                              return tile(
                                contact: e,
                                selected: c.selectedContacts.contains(e),
                                onTap: () => c.selectContact(e),
                              );
                            });
                          }

                          return Container();
                        },
                        childCount: c.contacts.length +
                            c.users.length +
                            c.recent.length,
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
                        child: OutlinedRoundedButton(
                          key: const Key('BackButton'),
                          maxWidth: null,
                          title: const Text(
                            'Back',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(color: Colors.white),
                          ),
                          onPressed: () => c.stage.value =
                              ParticipantsFlowStage.participants,
                          color: const Color(0xFF63B4FF),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Obx(() {
                          bool enabled = (c.selectedContacts.isNotEmpty ||
                                  c.selectedUsers.isNotEmpty) &&
                              c.status.value.isEmpty;

                          return OutlinedRoundedButton(
                            key: const Key('AddDialogMembersButton'),
                            maxWidth: null,
                            title: Text(
                              'Add',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              style: TextStyle(
                                color: enabled ? Colors.white : Colors.black,
                              ),
                            ),
                            onPressed: enabled ? c.addMembers : null,
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

              child = Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
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
              break;

            case ParticipantsFlowStage.participants:
              List<Widget> children = [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: _chat(context, c),
                ),
                const SizedBox(height: 25),
                Center(
                  child: Text(
                    'Participants'.l10n,
                    style: thin?.copyWith(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView(
                    physics: const ScrollPhysics(),
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
                key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
                constraints: const BoxConstraints(maxHeight: 650),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 16),
                    ...children,
                    const SizedBox(height: 16),
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

      return Padding(
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
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 3),
                            child: Row(
                              children: [
                                Text(
                                  '${actualMembers.length + 1} of ${c.chat.value?.members.length}',
                                  style: Theme.of(context).textTheme.subtitle2,
                                ),
                                Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  width: 1,
                                  height: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      ?.color,
                                ),
                                Text(
                                  _duration.value.hhMmSs(),
                                  style: Theme.of(context).textTheme.subtitle2,
                                ),
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
              ),
            );
          }
          return Container();
        }),
      ],
    );
  }

  Widget _addParticipant(BuildContext context, ParticipantController c) {
    return OutlinedRoundedButton(
      maxWidth: null,
      title: const Text(
        'Add participant',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: TextStyle(color: Colors.white),
      ),
      onPressed: () {
        c.status.value = RxStatus.empty();
        c.selectedContacts.clear();
        c.selectedUsers.clear();
        c.searchResults.value = null;
        c.searchStatus.value = RxStatus.empty();
        c.query.value = null;
        c.search.clear();
        c.populate();
        c.stage.value = ParticipantsFlowStage.adding;
      },
      color: const Color(0xFF63B4FF),
    );
  }
}
