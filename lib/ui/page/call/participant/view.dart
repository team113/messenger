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

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/ui/widget/animated_size_and_fade.dart';
import 'package:messenger/ui/widget/widget_button.dart';

import '/domain/model/ongoing_call.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/widget/chat_item.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/modal_popup.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
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
        Theme.of(context).textTheme.bodyText1?.copyWith(color: Colors.black);

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
            return const Center(child: CircularProgressIndicator());
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
              final Set<UserId> actualMembers =
                  call.value.members.keys.map((k) => k.userId).toSet();

              List<Widget> children = [
                ModalPopupHeader(
                  header: Center(
                    child: Text(
                      'label_participants_of'.l10nfmt({
                        'a': actualMembers.length,
                        'b': c.chat.value?.members.length ?? 1,
                      }),
                      style: thin?.copyWith(fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView(
                    controller: ScrollController(),
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
                  child: OutlinedRoundedButton(
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
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ];

              child = Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                constraints: const BoxConstraints(maxHeight: 650),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    ...children,
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
    return ContextMenuRegion(
      actions: [
        ContextMenuButton(
          label: user.id != c.me ? 'btn_remove'.l10n : 'btn_leave'.l10n,
          onPressed: () => c.removeChatMember(user.id),
          trailing: SvgLoader.asset(
            'assets/icons/delete_small.svg',
            width: 17.75,
            height: 17,
          ),
        ),
      ],
      moveDownwards: false,
      child: ContactTile(
        user: user,
        onTap: () {
          // TODO: Open the [Routes.user] page.
        },
        darken: 0.05,
        trailing: [
          Obx(() {
            bool inCall = call.value.members.keys
                .where((e) => e.userId == user.id)
                .isNotEmpty;

            if (!inCall) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: Theme.of(context).colorScheme.secondary,
                  type: MaterialType.circle,
                  child: InkWell(
                    onTap: () => c.redialChatCallMember(user.id),
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

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: WidgetButton(
                key: const Key('Drop'),
                onPressed: () {},
                child: Container(
                  height: 30,
                  width: 30,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: SvgLoader.asset(
                      'assets/icons/call_end.svg',
                      width: 30,
                      height: 30,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
