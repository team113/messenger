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
import 'package:get/get.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';

/// View of the call participants modal.
class ParticipantsView extends StatelessWidget {
  const ParticipantsView({
    required this.ongoingCall,
    this.callDuration,
    this.onSubmit,
    Key? key,
  }) : super(key: key);

  /// The [OngoingCall] that this modal is bound to.
  final Rx<OngoingCall> ongoingCall;

  /// Duration of the [ongoingCall].
  final Rx<Duration>? callDuration;

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
      ),
      builder: (ParticipantController c) {
        return Obx(() {
          if (c.chat.value == null) {
            return const Center(child: CircularProgressIndicator());
          }

          Widget child;

          switch (c.stage.value) {
            case ParticipantsFlowStage.search:
              child = SearchView(
                searchTypes: const [
                  Search.recent,
                  Search.contacts,
                  Search.users
                ],
                title: 'label_add_participants'.l10n,
                submitLabel: 'btn_add'.l10n,
                onBack: () =>
                    c.stage.value = ParticipantsFlowStage.participants,
                onSubmit: (ids) => c.submit(onSubmit!, ids),
                enabled: c.status.value.isEmpty,
                chat: c.chat,
              );
              break;

            case ParticipantsFlowStage.participants:
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
                  child: _addParticipant(context, c),
                ),
              ];

              child = Container(
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
              break;
          }

          return AnimatedSizeAndFade(
            key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: child,
          );
        });
      },
    );
  }

  /// Returns [Widget] with the information of the provided [chat].
  Widget _chat(BuildContext context, RxChat? chat) {
    return Obx(() {
      Style style = Theme.of(context).extension<Style>()!;

      var actualMembers =
          ongoingCall.value.members.keys.map((k) => k.userId).toSet();

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
          bool inCall = ongoingCall.value.members.keys
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

  /// Returns button to change stage to [ParticipantsFlowStage.search].
  Widget _addParticipant(
    BuildContext context,
    ParticipantController c,
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
        c.stage.value = ParticipantsFlowStage.search;
      },
      color: const Color(0xFF63B4FF),
    );
  }
}
