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

import 'dart:async';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:get/get.dart';

import '/domain/model/chat.dart';
import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
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
import 'search_controller.dart';

typedef SubmitCallback = FutureOr<void> Function(List<UserId>);

/// View of the call participants modal modal.
class ParticipantView extends StatelessWidget {
  const ParticipantView({
    required this.searchTypes,
    required this.title,
    this.submitLabel,
    this.ongoingCall,
    this.callDuration,
    this.chatId,
    this.selectable = true,
    this.onItemTap,
    this.onSubmit,
    Key? key,
  }) : super(key: key);

  /// Crates [ParticipantView] for an [OngoingCall].
  factory ParticipantView.call(
    Rx<OngoingCall> call,
    Rx<Duration> duration,
    SubmitCallback onSubmit, {
    Key? key,
  }) {
    return ParticipantView(
      key: key,
      ongoingCall: call,
      chatId: call.value.chatId,
      callDuration: duration,
      searchTypes: const [Search.recent, Search.contacts, Search.users],
      onSubmit: onSubmit,
      title: 'label_add_participants'.l10n,
      submitLabel: 'btn_add'.l10n,
    );
  }

  /// The [OngoingCall] that this modal is bound to.
  final Rx<OngoingCall>? ongoingCall;

  /// Duration of the [ongoingCall].
  final Rx<Duration>? callDuration;

  /// [Search] types this modal doing.
  final List<Search> searchTypes;

  /// ID of the [Chat] this modal is bound to.
  final Rx<ChatId>? chatId;

  /// Indicator whether searched items is selectable.
  final bool selectable;

  /// Title showed on search stage.
  final String title;

  /// Label showed on the submit button.
  final String? submitLabel;

  /// Callback, called when an searched item is tapped.
  final void Function(dynamic)? onItemTap;

  /// Callback, called when the submit button tapped.
  final SubmitCallback? onSubmit;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    final TextStyle? thin =
        theme.textTheme.bodyText1?.copyWith(color: Colors.black);

    return GetBuilder(
      init: ParticipantController(
        Navigator.of(context).pop,
        ongoingCall,
        Get.find(),
        chatId: chatId,
      ),
      builder: (ParticipantController c) {
        return GetBuilder(
          init: SearchController(
            Get.find(),
            Get.find(),
            Get.find(),
            chatId: chatId,
            searchTypes: searchTypes,
          ),
          builder: (SearchController s) {
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
                      if (selectable)
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
                case SearchFlowStage.search:
                  List<Widget> children = [
                    Center(
                      child: Text(
                        title,
                        style: thin?.copyWith(fontSize: 18),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(
                        child: ReactiveTextField(
                          state: s.search,
                          label: 'label_search'.l10n,
                          style: thin,
                          onChanged: () => s.query.value = s.search.text,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    SizedBox(
                      height: 17,
                      child: Row(
                        children: [
                          const SizedBox(width: 10),
                          Expanded(
                            child: Builder(builder: (context) {
                              List<Widget> widgets = [];

                              if (searchTypes.contains(Search.recent)) {
                                widgets.add(_type(s, Search.recent, thin));
                              }

                              if (searchTypes.contains(Search.contacts)) {
                                if (widgets.isNotEmpty) {
                                  widgets.add(const SizedBox(width: 20));
                                }
                                widgets.add(_type(s, Search.contacts, thin));
                              }

                              if (searchTypes.contains(Search.users)) {
                                if (widgets.isNotEmpty) {
                                  widgets.add(const SizedBox(width: 20));
                                }
                                widgets.add(_type(s, Search.users, thin));
                              }

                              return ListView(
                                scrollDirection: Axis.horizontal,
                                shrinkWrap: true,
                                children: widgets,
                              );
                            }),
                          ),
                          Obx(() {
                            return Text(
                              'label_selected'.l10nfmt({
                                'count': s.selectedContacts.length +
                                    s.selectedUsers.length
                              }),
                              style: thin?.copyWith(fontSize: 15),
                            );
                          }),
                          const SizedBox(width: 10),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Obx(() {
                        if (s.recent.isEmpty &&
                            s.contacts.isEmpty &&
                            s.users.isEmpty) {
                          if (s.searchStatus.value.isSuccess) {
                            return Center(
                                child: Text('label_nothing_found'.l10n));
                          } else if (s.searchStatus.value.isEmpty) {
                            return Center(
                              child: Text('label_use_search'.l10n),
                            );
                          }

                          return const Center(
                              child: CircularProgressIndicator());
                        }

                        return FlutterListView(
                          controller: s.controller,
                          delegate: FlutterListViewDelegate(
                            (context, i) {
                              dynamic e = s.getIndex(i);

                              if (e is RxUser) {
                                return Column(
                                  children: [
                                    if (i > 0) const SizedBox(height: 7),
                                    Obx(() {
                                      return tile(
                                        user: e,
                                        selected: s.selectedUsers.contains(e),
                                        onTap: () => selectable
                                            ? s.selectUser(e)
                                            : onItemTap?.call(e),
                                      );
                                    }),
                                  ],
                                );
                              } else if (e is RxChatContact) {
                                return Column(
                                  children: [
                                    if (i > 0) const SizedBox(height: 7),
                                    Obx(() {
                                      return tile(
                                        contact: e,
                                        selected:
                                            s.selectedContacts.contains(e),
                                        onTap: () => selectable
                                            ? s.selectContact(e)
                                            : onItemTap?.call(e),
                                      );
                                    }),
                                  ],
                                );
                              }

                              return Container();
                            },
                            childCount: s.contacts.length +
                                s.users.length +
                                s.recent.length,
                          ),
                        );
                      }),
                    ),
                    if (onSubmit != null && submitLabel != null) ...[
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            if (ongoingCall != null) ...[
                              Expanded(
                                child: OutlinedRoundedButton(
                                  key: const Key('BackButton'),
                                  maxWidth: null,
                                  title: Text(
                                    'btn_back'.l10n,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () => c.stage.value =
                                      SearchFlowStage.participants,
                                  color: const Color(0xFF63B4FF),
                                ),
                              ),
                              const SizedBox(width: 10),
                            ],
                            Expanded(
                              child: Obx(() {
                                bool enabled = (s.selectedContacts.isNotEmpty ||
                                        s.selectedUsers.isNotEmpty) &&
                                    c.status.value.isEmpty;

                                return OutlinedRoundedButton(
                                  key: const Key('SearchSubmitButton'),
                                  maxWidth: null,
                                  title: Text(
                                    submitLabel!,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: TextStyle(
                                      color:
                                          enabled ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  onPressed: () => enabled
                                      ? c.submit(onSubmit!, s.selected())
                                      : null,
                                  color: enabled
                                      ? const Color(0xFF63B4FF)
                                      : const Color(0xFFEEEEEE),
                                );
                              }),
                            ),
                          ],
                        ),
                      )
                    ],
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

                case SearchFlowStage.participants:
                  List<Widget> children = [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _chat(context, c.chat.value),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: Text(
                        'label_participants'.l10n,
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
                            child: _user(c, e),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: _addParticipant(context, c, s),
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
      },
    );
  }

  /// Returns button to jump to the provided [Search] type search results.
  Widget _type(SearchController s, Search type, TextStyle? textStyle) {
    return WidgetButton(
      onPressed: () => s.jumpTo(type),
      child: Obx(() {
        return Text(
          type.name.capitalizeFirst!,
          style: textStyle?.copyWith(
            fontSize: 15,
            color:
                s.selectedSearch.value == type ? const Color(0xFF63B4FF) : null,
          ),
        );
      }),
    );
  }

  /// Returns [Widget] with the information of the provided [chat].
  Widget _chat(BuildContext context, RxChat? chat) {
    return Obx(() {
      Style style = Theme.of(context).extension<Style>()!;

      var actualMembers =
          ongoingCall!.value.members.keys.map((k) => k.userId).toSet();

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
                                  chat?.title.value ?? '',
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
                                  '${actualMembers.length} of ${chat?.members.length}',
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
                                  callDuration!.value.hhMmSs(),
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

  /// Returns [Widget] with the information of the provided [user].
  Widget _user(ParticipantController c, RxUser user) {
    return ContactTile(
      user: user,
      onTap: () {},
      trailing: [
        Obx(() {
          bool inCall = user.id == c.me ||
              ongoingCall!.value.members.keys
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

  /// Returns button to change stage to [SearchFlowStage.search].
  Widget _addParticipant(
    BuildContext context,
    ParticipantController c,
    SearchController s,
  ) {
    return OutlinedRoundedButton(
      maxWidth: null,
      title: Text(
        'btn_add_participants'.l10n,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: const TextStyle(color: Colors.white),
      ),
      onPressed: () {
        c.status.value = RxStatus.empty();
        s.selectedContacts.clear();
        s.selectedUsers.clear();
        s.searchResults.value = null;
        s.searchStatus.value = RxStatus.empty();
        s.query.value = null;
        s.search.clear();
        s.populate();
        c.stage.value = SearchFlowStage.search;
      },
      color: const Color(0xFF63B4FF),
    );
  }
}
