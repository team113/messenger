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
import '/ui/page/home/widget/actions.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import 'controller.dart';
import 'widget/blocked.dart';
import 'widget/blocked_field.dart';
import 'widget/name.dart';
import 'widget/num.dart';
import 'widget/presence.dart';
import 'widget/status.dart';

/// View of the [Routes.user] page.
class UserView extends StatelessWidget {
  const UserView(this.id, {super.key});

  /// ID of the [User] this [UserView] represents.
  final UserId id;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      init: UserController(id, Get.find(), Get.find(), Get.find(), Get.find()),
      tag: id.val,
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
                          final String? status = c.user?.user.value.getStatus();
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
                                  '${c.user?.user.value.name?.val ?? c.user?.user.value.num.val}'),
                              if (subtitle.isNotEmpty)
                                Text(
                                  subtitle,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: style.colors.secondary),
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
                  WidgetButton(
                    onPressed: c.openChat,
                    child: Transform.translate(
                      offset: const Offset(0, 1),
                      child: SvgImage.asset(
                        'assets/icons/chat.svg',
                        width: 20.12,
                        height: 21.62,
                      ),
                    ),
                  ),
                  if (constraints.maxWidth > 400) ...[
                    const SizedBox(width: 28),
                    WidgetButton(
                      onPressed: () => c.call(true),
                      child: SvgImage.asset(
                        'assets/icons/chat_video_call.svg',
                        height: 17,
                      ),
                    ),
                  ],
                  const SizedBox(width: 28),
                  WidgetButton(
                    onPressed: () => c.call(false),
                    child: SvgImage.asset(
                      'assets/icons/chat_audio_call.svg',
                      height: 19,
                    ),
                  ),
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
                      if (c.isBlacklisted != null)
                        Block(
                          title: 'label_user_is_blocked'.l10n,
                          children: [
                            BlockedWidget(isBlacklisted: c.isBlacklisted),
                          ],
                        ),
                      Block(
                        title: 'label_public_information'.l10n,
                        children: [
                          WidgetButton(
                            onPressed: c.user?.user.value.avatar == null
                                ? null
                                : () async {
                                    await GalleryPopup.show(
                                      context: context,
                                      gallery: GalleryPopup(
                                        initialKey: c.avatarKey,
                                        children: [
                                          GalleryItem.image(
                                            c.user!.user.value.avatar!.original
                                                .url,
                                            c.user!.id.val,
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                            child: AvatarWidget.fromRxUser(
                              c.user,
                              radius: 100,
                              badge: false,
                            ),
                          ),
                          const SizedBox(height: 15),
                          NameWidget(user: c.user),
                          StatusWidget(user: c.user),
                          PresenceWidget(user: c.user),
                        ],
                      ),
                      Block(
                        title: 'label_contact_information'.l10n,
                        children: [NumWidget(user: c.user)],
                      ),
                      Block(
                        title: 'label_actions'.l10n,
                        children: [
                          Obx(
                            () => ActionsWidget(
                              inContacts: c.inContacts.value,
                              inFavorites: c.inFavorites.value,
                              status: c.status.value,
                              blacklistStatus: c.blacklistStatus.value,
                              user: c.user,
                              isBlacklisted: c.isBlacklisted,
                              addToContacts: () => c.addToContacts(),
                              unblacklist: () => c.unblacklist(),
                              favoriteContact: () => c.favoriteContact(),
                              unfavoriteContact: () => c.unfavoriteContact(),
                              muteChat: () => c.muteChat(),
                              unmuteChat: () => c.unmuteChat(),
                              removeFromContacts: () =>
                                  _removeFromContacts(c, context),
                              hideChat: () => _hideChat(c, context),
                              clearChat: () => _clearChat(c, context),
                              blacklistUser: () => _blacklistUser(c, context),
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  );
                }),
              ),
              bottomNavigationBar: Obx(() {
                if (c.isBlacklisted == null) {
                  return const SizedBox();
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                  child: BlockedField(unblacklist: () => c.unblacklist()),
                );
              }),
            );
          });
        });
      },
    );
  }

  /// Opens a confirmation popup deleting the [User] from address book.
  Future<void> _removeFromContacts(
    UserController c,
    BuildContext context,
  ) async {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_delete_contact'.l10n,
      description: [
        TextSpan(text: 'alert_contact_will_be_removed1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
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
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_hide_chat'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_hidden1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
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
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_cleared1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
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
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text: c.user?.user.value.name?.val ?? c.user?.user.value.num.val,
          style: TextStyle(color: style.colors.onBackground),
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
