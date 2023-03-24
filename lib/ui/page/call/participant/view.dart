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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/model/user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import 'controller.dart';

/// [OngoingCall.members] enumeration and administration view.
///
/// Intended to be displayed with the [show] method.
class ParticipantView extends StatelessWidget {
  const ParticipantView({
    Key? key,
    required this.call,
    required this.duration,
  }) : super(key: key);

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
    return ModalPopup.show(
      context: context,
      mobilePadding: const EdgeInsets.all(0),
      child: ParticipantView(call: call, duration: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle? thin =
        Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.black);

    return GetBuilder(
      init: ParticipantController(
        call,
        Get.find(),
        Get.find(),
        pop: Navigator.of(context).pop,
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
                return SearchView(
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
                      header: Center(
                        child: Text(
                          'label_participants_of'.l10nfmt({
                            'a': ids.length,
                            'b': c.chat.value?.members.length ?? 1,
                          }),
                          style: thin?.copyWith(fontSize: 18),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Scrollbar(
                        controller: c.scrollController,
                        child: ListView(
                          controller: c.scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          children: c.chat.value!.members.values.map((e) {
                            return _user(context, c, e);
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
                          style: const TextStyle(color: Colors.white),
                        ),
                        onPressed: () {
                          c.status.value = RxStatus.empty();
                          c.stage.value = ParticipantsFlowStage.search;
                        },
                        color: Theme.of(context).colorScheme.secondary,
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

  /// Returns a visual representation of the provided [user].
  Widget _user(BuildContext context, ParticipantController c, RxUser user) {
    return Obx(() {
      bool inCall = false;
      bool isRedialed = false;

      CallMember? member = call.value.members.values
          .firstWhereOrNull((e) => e.id.userId == user.id);

      if (member != null) {
        inCall = true;
        isRedialed = member.isRedialing.isTrue;
      }

      return ContactTile(
        user: user,
        dense: true,
        onTap: () {
          // TODO: Open the [Routes.user] page.
        },
        darken: 0.05,
        trailing: [
          if (user.id != c.me)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Material(
                  key: Key(inCall ? 'inCall' : 'NotInCall'),
                  color: inCall
                      ? isRedialed
                          ? Colors.grey
                          : Colors.red
                      : Theme.of(context).colorScheme.secondary,
                  type: MaterialType.circle,
                  child: InkWell(
                    onTap: inCall
                        ? isRedialed
                            ? null
                            : () => c.removeChatCallMember(user.id)
                        : () => c.redialChatCallMember(user.id),
                    borderRadius: BorderRadius.circular(60),
                    child: SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                        child: inCall && !isRedialed
                            ? SvgLoader.asset('assets/icons/call_end.svg')
                            : SvgLoader.asset(
                                'assets/icons/audio_call_start.svg',
                                width: 13,
                                height: 13,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          WidgetButton(
            onPressed: () async {
              final bool? result = await MessagePopup.alert(
                user.id == c.me
                    ? 'label_leave_group'.l10n
                    : 'label_remove_member'.l10n,
                description: [
                  if (c.me == user.id)
                    TextSpan(text: 'alert_you_will_leave_group'.l10n)
                  else ...[
                    TextSpan(text: 'alert_user_will_be_removed1'.l10n),
                    TextSpan(
                      text:
                          user.user.value.name?.val ?? user.user.value.num.val,
                      style: const TextStyle(color: Colors.black),
                    ),
                    TextSpan(text: 'alert_user_will_be_removed2'.l10n),
                  ],
                ],
              );

              if (result == true) {
                await c.removeChatMember(user.id);
              }
            },
            child: user.id == c.me
                ? Text(
                    'btn_leave'.l10n,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 15,
                    ),
                  )
                : SvgLoader.asset(
                    'assets/icons/delete.svg',
                    height: 14 * 1.5,
                  ),
          ),
          const SizedBox(width: 6),
        ],
      );
    });
  }
}
