// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
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
  });

  /// [OngoingCall] this modal is bound to.
  final Rx<OngoingCall> call;

  /// Duration of the [call].
  final Rx<Duration> duration;

  /// Displays a [ParticipantView] wrapped in a [ModalPopup].
  static Future<T?> show<T>(
    BuildContext context, {
    required Rx<OngoingCall> call,
    required Rx<Duration> duration,
  }) {
    final style = Theme.of(context).style;

    return ModalPopup.show(
      context: context,
      background: style.colors.background,
      mobilePadding: const EdgeInsets.only(bottom: 0),
      desktopPadding: const EdgeInsets.fromLTRB(0, 10, 0, 0),
      child: ParticipantView(call: call, duration: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: ParticipantController(
        call,
        Get.find(),
        Get.find(),
        pop: context.popModal,
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
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                      child: SearchView(
                        categories: const [
                          SearchCategory.recent,
                          SearchCategory.contact,
                          SearchCategory.user,
                        ],
                        title: 'label_add_participants'.l10n,
                        onBack: () =>
                            c.stage.value = ParticipantsFlowStage.participants,
                        submit: 'btn_add'.l10n,
                        onSubmit: c.addMembers,
                        enabled: c.status.value.isEmpty,
                        chat: c.chat.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                );
              });
              break;

            case ParticipantsFlowStage.participants:
              final Set<UserId> ids = call.value.members.keys
                  .where((e) => e.deviceId != null)
                  .map((k) => k.userId)
                  .toSet();

              child = Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                constraints: const BoxConstraints(maxHeight: 650),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ModalPopupHeader(
                      text: 'label_participants_of'.l10nfmt({
                        'a': ids.length,
                        'b': c.chat.value?.members.length ?? 1,
                      }),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Scrollbar(
                        controller: c.scrollController,
                        child: ListView(
                          controller: c.scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          children: c.chat.value!.members.values.map((user) {
                            bool inCall = false;
                            bool isRedialed = false;

                            CallMember? member =
                                call.value.members.values.firstWhereOrNull(
                              (e) => e.id.userId == user.id,
                            );

                            if (member != null) {
                              inCall = true;
                              isRedialed = member.isDialing.isTrue;
                            }

                            return MemberTile(
                              user: user,
                              me: user.id == c.me,
                              inCall: user.id == c.me ? null : inCall,
                              onTap: () {
                                // TODO: Open the [Routes.user] page.
                              },
                              // TODO: Wait for backend to support removing
                              //       active call notification.
                              onCall: inCall
                                  ? isRedialed
                                      ? null
                                      : () => c.removeChatCallMember(user.id)
                                  : () => c.redialChatCallMember(user.id),
                              onKick: () => c.removeChatMember(user.id),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: OutlinedRoundedButton(
                        maxWidth: double.infinity,
                        title: Text(
                          'btn_add_participants'.l10n,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: style.fonts.medium.regular.onPrimary,
                        ),
                        onPressed: () {
                          c.status.value = RxStatus.empty();
                          c.stage.value = ParticipantsFlowStage.search;
                        },
                        color: style.colors.primary,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
              break;
          }

          return AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: KeyedSubtree(
              key: Key('${c.stage.value.name.capitalizeFirst}Stage'),
              child: child,
            ),
          );
        });
      },
    );
  }
}
