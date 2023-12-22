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
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/chat_subtitle.dart';
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
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
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
              appBar: CustomAppBar(title: _bar(c, context)),
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
                      Block(children: [_actions(c, context)]),
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
                  child: SafeArea(child: UnblockButton(c.unblock)),
                );
              }),
            );
          });
        });
      },
    );
  }

  /// Returns information about the [User] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final bool inCall = c.chat?.inCall.value ?? false;

      return Center(
        child: Row(
          children: [
            const SizedBox(width: 8),
            const StyledBackButton(),
            Material(
              elevation: 6,
              type: MaterialType.circle,
              shadowColor: style.colors.onBackgroundOpacity27,
              color: style.colors.onPrimary,
              child: Center(
                child: AvatarWidget.fromRxUser(
                  c.user,
                  radius: AvatarRadius.medium,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: DefaultTextStyle.merge(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: Obx(() {
                  final RxChat? chat = c.user?.dialog.value;

                  final bool monolog = chat?.chat.value.isMonolog == true;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '${c.user?.user.value.name?.val ?? c.user?.user.value.num}',
                            ),
                          ),
                          Obx(() {
                            if (c.user?.dialog.value?.chat.value.muted ==
                                null) {
                              return const SizedBox();
                            }

                            return const Padding(
                              padding: EdgeInsets.only(left: 5),
                              child: SvgIcon(SvgIcons.muted),
                            );
                          }),
                        ],
                      ),
                      if (!monolog && chat != null) ChatSubtitle(chat, c.me),
                    ],
                  );
                }),
              ),
            ),
            const SizedBox(width: 40),
            AnimatedButton(
              onPressed: c.openChat,
              child: const SvgIcon(SvgIcons.chat),
            ),
            const SizedBox(width: 28),
            AnimatedButton(
              enabled: !inCall,
              onPressed: inCall ? null : () => c.call(true),
              child: SvgIcon(
                inCall
                    ? SvgIcons.chatVideoCallDisabled
                    : SvgIcons.chatVideoCall,
              ),
            ),
            const SizedBox(width: 28),
            AnimatedButton(
              enabled: !inCall,
              onPressed: inCall ? null : () => c.call(false),
              child: SvgIcon(
                inCall
                    ? SvgIcons.chatAudioCallDisabled
                    : SvgIcons.chatAudioCall,
              ),
            ),
            const SizedBox(width: 10),
            Obx(() {
              final bool contact = c.inContacts.value;
              final bool favorite = c.inFavorites.value;
              final bool blocked = c.isBlocked != null;

              final RxChat? dialog = c.user?.user.value.dialog.isLocal == false
                  ? c.user?.dialog.value
                  : null;

              final bool muted = dialog?.chat.value.muted != null;

              return AnimatedButton(
                child: SafeAnimatedSwitcher(
                  duration: 250.milliseconds,
                  child: ContextMenuRegion(
                    key: c.moreKey,
                    selector: c.moreKey,
                    alignment: Alignment.topRight,
                    enablePrimaryTap: true,
                    margin: const EdgeInsets.only(bottom: 4, right: 12),
                    actions: [
                      ContextMenuButton(
                        key: Key(
                          contact
                              ? 'DeleteFromContactsButton'
                              : 'AddToContactsButton',
                        ),
                        label: contact
                            ? 'btn_delete_from_contacts'.l10n
                            : 'btn_add_to_contacts'.l10n,
                        trailing: SvgIcon(
                          contact
                              ? SvgIcons.deleteContact
                              : SvgIcons.addContact,
                        ),
                        inverted: SvgIcon(
                          contact
                              ? SvgIcons.deleteContactWhite
                              : SvgIcons.addContactWhite,
                        ),
                        onPressed: contact
                            ? () => _removeFromContacts(c, context)
                            : c.addToContacts,
                      ),
                      if (contact)
                        ContextMenuButton(
                          key: Key(
                            favorite
                                ? 'UnfavoriteContactButton'
                                : 'FavoriteContactButton',
                          ),
                          label: favorite
                              ? 'btn_delete_from_favorites'.l10n
                              : 'btn_add_to_favorites'.l10n,
                          trailing: SvgIcon(
                            favorite
                                ? SvgIcons.favoriteSmall
                                : SvgIcons.unfavoriteSmall,
                          ),
                          inverted: SvgIcon(
                            favorite
                                ? SvgIcons.favoriteSmallWhite
                                : SvgIcons.unfavoriteSmallWhite,
                          ),
                          onPressed: favorite
                              ? c.unfavoriteContact
                              : c.favoriteContact,
                        ),
                      if (dialog != null) ...[
                        ContextMenuButton(
                          key: Key(
                              muted ? 'UnmuteChatButton' : 'MuteChatButton'),
                          label: muted
                              ? PlatformUtils.isMobile
                                  ? 'btn_unmute'.l10n
                                  : 'btn_unmute_chat'.l10n
                              : PlatformUtils.isMobile
                                  ? 'btn_mute'.l10n
                                  : 'btn_mute_chat'.l10n,
                          trailing: SvgIcon(
                            muted ? SvgIcons.unmuteSmall : SvgIcons.muteSmall,
                          ),
                          inverted: SvgIcon(
                            muted
                                ? SvgIcons.unmuteSmallWhite
                                : SvgIcons.muteSmallWhite,
                          ),
                          onPressed: muted ? c.unmuteChat : c.muteChat,
                        ),
                        ContextMenuButton(
                          key: const Key('ClearHistoryButton'),
                          label: 'btn_clear_history'.l10n,
                          trailing: const SvgIcon(SvgIcons.cleanHistory),
                          inverted: const SvgIcon(SvgIcons.cleanHistoryWhite),
                          onPressed: () => _clearChat(c, context),
                        ),
                        ContextMenuButton(
                          key: const Key('HideChatButton'),
                          label: 'btn_delete_chat'.l10n,
                          trailing: const SvgIcon(SvgIcons.delete19),
                          inverted: const SvgIcon(SvgIcons.delete19White),
                          onPressed: () => _hideChat(c, context),
                        ),
                      ],
                      ContextMenuButton(
                        key: Key(blocked ? 'Unblock' : 'Block'),
                        label: blocked ? 'btn_unblock'.l10n : 'btn_block'.l10n,
                        trailing: const SvgIcon(SvgIcons.block),
                        inverted: const SvgIcon(SvgIcons.blockWhite),
                        onPressed:
                            blocked ? c.unblock : () => _blockUser(c, context),
                      ),
                    ],
                    child: Container(
                      key: const Key('MoreButton'),
                      padding: const EdgeInsets.only(left: 20, right: 21),
                      height: double.infinity,
                      child: const SvgIcon(SvgIcons.more),
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      );
    });
  }

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          text: 'btn_report'.l10n,
          trailing: const SvgIcon(SvgIcons.report),
          onPressed: () {},
        ),
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
          style: style.fonts.normal.regular.onBackground,
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
      'label_delete_chat'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_deleted1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_dialog_will_be_deleted2'.l10n),
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
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_dialog_will_be_cleared2'.l10n),
      ],
    );

    if (result == true) {
      await c.clearChat();
    }
  }

  /// Opens a confirmation popup blocking the [User].
  Future<void> _blockUser(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text:
              c.user?.user.value.name?.val ?? c.user?.user.value.num.toString(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_user_will_be_blocked2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(state: c.reason, label: 'label_reason'.l10n),
      ],
    );

    if (result == true) {
      await c.block();
    }
  }
}
