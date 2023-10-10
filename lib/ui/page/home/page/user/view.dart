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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/num.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/page/home/widget/unblock_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import 'controller.dart';
import 'widget/blocklist_record.dart';
import 'widget/name.dart';
import 'widget/presence.dart';
import 'widget/status.dart';

/// View of the [Routes.user] page.
class UserView extends StatelessWidget {
  const UserView(this.id, {super.key});

  /// ID of the [User] this [UserView] represents.
  final UserId id;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: UserController(id, Get.find(), Get.find(), Get.find(), Get.find()),
      tag: id.val,
      global: !Get.isRegistered<UserController>(tag: id.val),
      builder: (UserController c) {
        return Obx(() {
          if (!c.status.value.isSuccess) {
            return Scaffold(
              appBar: const CustomAppBar(
                padding: EdgeInsets.only(left: 4, right: 20),
                leading: [StyledBackButton()],
              ),
              body: Center(
                child: c.status.value.isEmpty
                    ? Text('err_unknown_user'.l10n)
                    : const CustomProgressIndicator(),
              ),
            );
          }

          return LayoutBuilder(builder: (context, constraints) {
            return Scaffold(
              appBar: CustomAppBar(
                title: Row(
                  children: [
                    Material(
                      elevation: 6,
                      type: MaterialType.circle,
                      shadowColor: style.colors.onBackgroundOpacity27,
                      color: style.colors.onPrimary,
                      child: Center(
                        child: AvatarWidget.fromRxUser(c.user, radius: 17),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: Obx(() {
                          final String? status = c.user?.user.value
                              .getStatus(c.user?.lastSeen.value);

                          final UserTextStatus? text =
                              c.user?.user.value.status;
                          final StringBuffer buffer = StringBuffer();

                          if (status != null || text != null) {
                            buffer.write(text ?? '');

                            if (status != null && text != null) {
                              buffer.write('space_vertical_space'.l10n);
                            }

                            buffer.write(status ?? '');
                          }

                          final String subtitle = buffer.toString();

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${c.user?.user.value.name?.val ?? c.user?.user.value.num}'),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  style: style.fonts.bodySmallSecondary,
                                )
                            ],
                          );
                        }),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                ),
                padding: const EdgeInsets.only(left: 4, right: 20),
                leading: const [StyledBackButton()],
                actions: [
                  AnimatedButton(
                    onPressed: c.openChat,
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: const SvgImage.asset(
                        'assets/icons/chat.svg',
                        width: 20.12,
                        height: 21.62,
                      ),
                    ),
                  ),
                  Obx(() {
                    if (c.isBlocked != null) {
                      return const SizedBox.shrink();
                    }

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (constraints.maxWidth > 400) ...[
                          const SizedBox(width: 28),
                          AnimatedButton(
                            onPressed: () => c.call(true),
                            child: const SvgImage.asset(
                              'assets/icons/chat_video_call.svg',
                              height: 17,
                            ),
                          ),
                        ],
                        const SizedBox(width: 28),
                        AnimatedButton(
                          onPressed: () => c.call(false),
                          child: const SvgImage.asset(
                            'assets/icons/chat_audio_call.svg',
                            height: 19,
                          ),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              body: Scrollbar(
                controller: c.scrollController,
                child: Obx(() {
                  return ListView(
                    key: const Key('UserScrollable'),
                    controller: c.scrollController,
                    children: [
                      const SizedBox(height: 8),
                      if (c.isBlocked != null)
                        Block(
                          title: 'label_user_is_blocked'.l10n,
                          children: [BlocklistRecordWidget(c.isBlocked!)],
                        ),
                      Block(
                        title: 'label_public_information'.l10n,
                        children: [
                          BigAvatarWidget.user(c.user),
                          const SizedBox(height: 12),
                          UserNameCopyable(
                            c.user!.user.value.name,
                            c.user!.user.value.num,
                          ),
                          if (c.user!.user.value.status != null)
                            UserStatusCopyable(c.user!.user.value.status!),
                          if (c.user!.user.value.presence != null)
                            Obx(() {
                              return UserPresenceField(
                                c.user!.user.value.presence!,
                                c.user!.user.value
                                    .getStatus(c.user?.lastSeen.value),
                              );
                            }),
                        ],
                      ),
                      Block(
                        title: 'label_contact_information'.l10n,
                        children: [
                          Paddings.basic(
                            UserNumCopyable(
                              key: const Key('UserNum'),
                              c.user!.user.value.num,
                            ),
                          )
                        ],
                      ),
                      Block(
                        title: 'label_actions'.l10n,
                        children: [_actions(c, context)],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ),
              bottomNavigationBar: Obx(() {
                if (c.isBlocked == null) {
                  return const SizedBox();
                }

                return Padding(
                  padding: Insets.dense.copyWith(top: 0),
                  child: SafeArea(child: UnblockButton(c.unblacklist)),
                );
              }),
            );
          });
        });
      },
    );
  }

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() {
          return ActionButton(
            key: Key(c.inContacts.value
                ? 'DeleteFromContactsButton'
                : 'AddToContactsButton'),
            text: c.inContacts.value
                ? 'btn_delete_from_contacts'.l10n
                : 'btn_add_to_contacts'.l10n,
            onPressed: c.status.value.isLoadingMore
                ? null
                : c.inContacts.value
                    ? () => _removeFromContacts(c, context)
                    : c.addToContacts,
          );
        }),
        Obx(() {
          return c.inContacts.isTrue
              ? ActionButton(
                  text: c.inFavorites.value
                      ? 'btn_delete_from_favorites'.l10n
                      : 'btn_add_to_favorites'.l10n,
                  onPressed: c.inFavorites.value
                      ? c.unfavoriteContact
                      : c.favoriteContact,
                )
              : const SizedBox();
        }),
        if (c.user?.user.value.dialog.isLocal == false &&
            c.user?.dialog.value != null) ...[
          Obx(() {
            if (c.isBlocked != null) {
              return const SizedBox.shrink();
            }

            final chat = c.user!.dialog.value!.chat.value;
            final bool isMuted = chat.muted != null;

            return ActionButton(
              text: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
              trailing: isMuted
                  ? const SvgImage.asset(
                      'assets/icons/btn_mute.svg',
                      width: 18.68,
                      height: 15,
                    )
                  : const SvgImage.asset(
                      'assets/icons/btn_unmute.svg',
                      width: 17.86,
                      height: 15,
                    ),
              onPressed: isMuted ? c.unmuteChat : c.muteChat,
            );
          }),
          ActionButton(
            text: 'btn_hide_chat'.l10n,
            trailing:
                const SvgImage.asset('assets/icons/delete.svg', height: 14),
            onPressed: () => _hideChat(c, context),
          ),
          ActionButton(
            key: const Key('ClearHistoryButton'),
            text: 'btn_clear_history'.l10n,
            trailing:
                const SvgImage.asset('assets/icons/delete.svg', height: 14),
            onPressed: () => _clearChat(c, context),
          ),
        ],
        Obx(() {
          return ActionButton(
            key: Key(c.isBlocked != null ? 'Unblock' : 'Block'),
            text: c.isBlocked != null ? 'btn_unblock'.l10n : 'btn_block'.l10n,
            onPressed: c.isBlocked != null
                ? c.unblacklist
                : () => _blacklistUser(c, context),
            trailing: Obx(() {
              final Widget child;
              if (c.blacklistStatus.value.isEmpty) {
                child = const SizedBox();
              } else {
                child = const CustomProgressIndicator();
              }

              return SafeAnimatedSwitcher(
                duration: 200.milliseconds,
                child: child,
              );
            }),
          );
        }),
        ActionButton(text: 'btn_report'.l10n, onPressed: () {}),
      ],
    );
  }

  /// Opens a confirmation popup deleting the [User] from address book.
  Future<void> _removeFromContacts(
    UserController c,
    BuildContext context,
  ) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_contact'.l10n,
      description: [
        TextSpan(text: 'alert_contact_will_be_removed1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.labelLarge,
        ),
        TextSpan(text: 'alert_contact_will_be_removed2'.l10n),
      ],
    );

    if (result == true) {
      await c.removeFromContacts();
    }
  }

  /// Opens a confirmation popup hiding the [Chat]-dialog with the [User].
  Future<void> _hideChat(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_hide_chat'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_hidden1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.labelLarge,
        ),
        TextSpan(text: 'alert_dialog_will_be_hidden2'.l10n),
      ],
    );

    if (result == true) {
      await c.hideChat();
    }
  }

  /// Opens a confirmation popup clearing the [Chat]-dialog with the [User].
  Future<void> _clearChat(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_cleared1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.labelLarge,
        ),
        TextSpan(text: 'alert_dialog_will_be_cleared2'.l10n),
      ],
    );

    if (result == true) {
      await c.clearChat();
    }
  }

  /// Opens a confirmation popup blacklisting the [User].
  Future<void> _blacklistUser(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.labelLarge,
        ),
        TextSpan(text: 'alert_user_will_be_blocked2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(state: c.reason, label: 'label_reason'.l10n),
      ],
    );

    if (result == true) {
      await c.blacklist();
    }
  }
}
