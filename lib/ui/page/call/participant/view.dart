// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// [OngoingCall.members] enumeration and administration view.
///
/// Intended to be displayed with the [show] method.
class ParticipantView extends StatelessWidget {
  const ParticipantView({
    super.key,
    required this.call,
    required this.duration,
    this.initial = ParticipantsFlowStage.participants,
  });

  /// [OngoingCall] this modal is bound to.
  final Rx<OngoingCall> call;

  /// Duration of the [call].
  final Rx<Duration> duration;

  /// Initial [ParticipantsFlowStage] of this [ParticipantView].
  final ParticipantsFlowStage initial;

  /// Displays a [ParticipantView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Rx<OngoingCall> call,
    required Rx<Duration> duration,
    ParticipantsFlowStage initial = ParticipantsFlowStage.participants,
  }) {
    final style = Theme.of(context).style;

    return ModalPopup.show(
      context: context,
      background: style.colors.background,
      mobilePadding: const EdgeInsets.only(bottom: 16),
      child: ParticipantView(call: call, duration: duration, initial: initial),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: ParticipantController(
        call,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        pop: context.popModal,
        initial: initial,
      ),
      builder: (ParticipantController c) {
        return Obx(() {
          if (c.chat.value == null) {
            return const Center(child: CustomProgressIndicator());
          }

          final Widget child;

          switch (c.stage.value) {
            case ParticipantsFlowStage.search:
              child = Obx(() {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ModalPopupHeader(
                      text: 'label_add_participants'.l10n,
                      onBack: initial == ParticipantsFlowStage.participants
                          ? () => c.stage.value =
                                ParticipantsFlowStage.participants
                          : null,
                    ),
                    Flexible(
                      child: SearchView(
                        categories: const [
                          SearchCategory.recent,
                          SearchCategory.contact,
                          SearchCategory.user,
                        ],
                        submit: 'btn_add'.l10n,
                        onSubmit: c.addMembers,
                        enabled: c.status.value.isEmpty,
                        chat: c.chat.value,
                      ),
                    ),
                  ],
                );
              });
              break;

            case ParticipantsFlowStage.participants:
              child = Obx(() {
                final List<RxUser> members = [];

                for (var u in c.chat.value!.members.values.where(
                  (e) => e.user.id != c.me,
                )) {
                  members.add(u.user);
                }

                final Set<UserId> ids = call.value.members.keys
                    .where((e) => e.deviceId != null)
                    .map((k) => k.userId)
                    .toSet();

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  constraints: const BoxConstraints(maxHeight: 650),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ModalPopupHeader(
                        text: 'label_participants_of'.l10nfmt({
                          'a': ids.length,
                          'b': c.chat.value?.chat.value.membersCount ?? 1,
                        }),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Scrollbar(
                          controller: c.scrollController,
                          child: ListView.builder(
                            shrinkWrap: true,
                            controller: c.scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: members.length + 1,
                            itemBuilder: (_, i) {
                              i--;

                              Widget child;

                              if (i == -1) {
                                child = MemberTile(myUser: c.myUser.value);
                              } else {
                                final RxUser user = members[i];

                                bool inCall = false;
                                bool isRedialed = false;

                                CallMember? member = call.value.members.values
                                    .firstWhereOrNull(
                                      (e) => e.id.userId == user.id,
                                    );

                                if (member != null) {
                                  inCall = true;
                                  isRedialed = member.isDialing.isTrue;
                                }

                                child = MemberTile(
                                  user: user,
                                  inCall: user.id == c.me ? null : inCall,
                                  onTap: () {
                                    // TODO: Open the [Routes.user] page.
                                  },

                                  // TODO: Wait for backend to support removing
                                  //       active call notification.
                                  onCall: inCall
                                      ? isRedialed
                                            ? null
                                            : () => c.removeChatCallMember(
                                                user.id,
                                              )
                                      : () => c.redialChatCallMember(user.id),
                                  onKick: () => c.removeChatMember(user.id),
                                );
                              }

                              if (i == members.length - 1 &&
                                  c.chat.value!.members.hasNext.isTrue) {
                                child = Column(
                                  children: [
                                    child,
                                    const CustomProgressIndicator(),
                                  ],
                                );
                              }

                              return child;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: PrimaryButton(
                          onPressed: c.isSupport
                              ? null
                              : () {
                                  c.status.value = RxStatus.empty();
                                  c.stage.value = ParticipantsFlowStage.search;
                                },
                          title: 'btn_add_participants'.l10n,
                        ),
                      ),
                    ],
                  ),
                );
              });
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: Key('${c.stage.value.name.capitalized}Stage'),
              child: child,
            ),
          );
        });
      },
    );
  }
}
