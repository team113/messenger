// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/copy_or_share.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/home/widget/info_tile.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import 'controller.dart';
import 'widget/blocklist_record.dart';

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

          final List<Widget> blocks = [
            const SizedBox(height: 8),
            if (c.isBlocked != null)
              Block(
                title: 'label_user_is_blocked'.l10n,
                children: [
                  BlocklistRecordWidget(
                    c.isBlocked!,
                    onUnblock: c.unblock,
                  ),
                ],
              ),
            _avatar(c, context),
            _name(c, context, index: c.isBlocked != null ? 3 : 2),
            _info(c),
            SelectionContainer.disabled(
              child: Block(children: [_actions(c, context)]),
            ),
            const SizedBox(height: 8),
          ];

          return Scaffold(
            appBar: CustomAppBar(title: _bar(c, context)),
            body: Scrollbar(
              controller: c.scrollController,
              child: SelectionArea(
                contextMenuBuilder: (_, __) => const SizedBox(),
                child: ScrollablePositionedList.builder(
                  key: const Key('UserScrollable'),
                  itemCount: blocks.length,
                  itemBuilder: (_, i) => Obx(() {
                    return HighlightedContainer(
                      highlight: c.highlighted.value == i,
                      child: blocks[i],
                    );
                  }),
                  scrollController: c.scrollController,
                  itemScrollController: c.itemScrollController,
                  itemPositionsListener: c.positionsListener,
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds a [Block] displaying a [User.avatar].
  Widget _avatar(UserController c, BuildContext context) {
    return Obx(() {
      return Block(
        children: [
          SelectionContainer.disabled(
            child: BigAvatarWidget.user(
              c.user,
              key: Key('UserAvatar_${c.id}'),
              loading: c.avatar.value.isLoading,
              error: c.avatar.value.errorMessage,
              onUpload: c.contactId != null ? c.pickAvatar : null,
            ),
          ),
          if (c.contactId == null) const SizedBox(height: 10),
        ],
      );
    });
  }

  /// Returns the [User.name] visual representation.
  Widget _name(
    UserController c,
    BuildContext context, {
    required int index,
  }) {
    final style = Theme.of(context).style;

    return Block(
      children: [
        Obx(() {
          final List<Widget> children;

          if (c.nameEditing.value) {
            children = [
              const SizedBox(height: 10),
              SelectionContainer.disabled(
                child: ReactiveTextField(
                  state: c.name,
                  label: 'label_name'.l10n,
                  hint: c.user!.title,
                  formatters: [LengthLimitingTextInputFormatter(100)],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 16),
                  WidgetButton(
                    onPressed: c.submitName,
                    child: SelectionContainer.disabled(
                      child: Text(
                        'btn_save'.l10n,
                        style: style.fonts.small.regular.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  WidgetButton(
                    onPressed: () {
                      c.name.unchecked =
                          c.contact.value?.contact.value.name.val ??
                              c.name.text;
                      c.nameEditing.value = false;
                    },
                    child: SelectionContainer.disabled(
                      child: Text(
                        'btn_cancel'.l10n,
                        style: style.fonts.small.regular.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                ],
              ),
            ];
          } else {
            children = [
              Container(width: double.infinity),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  c.contact.value?.contact.value.name.val ?? c.name.text,
                  style: style.fonts.larger.regular.onBackground,
                ),
              ),
              const SizedBox(height: 8),
              if (c.contactId != null) ...[
                const SizedBox(height: 1),
                WidgetButton(
                  onPressed: () {
                    final ItemPosition? first =
                        c.positionsListener.itemPositions.value.firstOrNull;

                    // If the [Block] containing this button isn't fully
                    // visible, then animate to it's beginning.
                    if (first?.index == index && first!.itemLeadingEdge < 0) {
                      c.itemScrollController.scrollTo(
                        index: index,
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 600),
                      );
                      c.highlight(index);
                    }

                    c.nameEditing.value = true;
                  },
                  child: SelectionContainer.disabled(
                    child: Text(
                      'btn_change'.l10n,
                      style: style.fonts.small.regular.primary,
                    ),
                  ),
                ),
              ]
            ];
          }

          return AnimatedSizeAndFade(
            fadeDuration: 250.milliseconds,
            sizeDuration: 250.milliseconds,
            child: Column(
              key: Key(c.nameEditing.value.toString()),
              children: children,
            ),
          );
        }),
      ],
    );
  }

  /// Returns the [User.num] and [User.bio] visual representation.
  Widget _info(UserController c) {
    final UserBio? bio = c.user?.user.value.bio;

    return Block(
      title: 'label_info'.l10n,
      children: [
        Paddings.basic(
          InfoTile(
            key: const Key('NumCopyable'),
            title: 'label_num'.l10n,
            content: c.user!.user.value.num.toString(),
            trailing: CopyOrShareButton(c.user!.user.value.num.toString()),
          ),
        ),
        if (bio != null)
          Paddings.basic(
            InfoTile(
              title: 'label_about'.l10n,
              content: bio.val,
              maxLines: null,
            ),
          ),
      ],
    );
  }

  /// Returns information about the [User] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(UserController c, BuildContext context) {
    final style = Theme.of(context).style;

    final Widget moreButton = Obx(key: const Key('MoreButton'), () {
      // TODO: Uncomment, when contacts are implemented.
      // final bool contact = c.contactId != null;
      // final bool favorite =
      //     c.contact.value?.contact.value.favoritePosition != null;

      final RxChat? dialog = c.user?.dialog.value;
      final bool isMuted = dialog?.chat.value.muted != null;

      return AnimatedButton(
        child: ContextMenuRegion(
          key: c.moreKey,
          selector: c.moreKey,
          alignment: Alignment.topRight,
          enablePrimaryTap: true,
          margin: const EdgeInsets.only(bottom: 4, left: 5),
          actions: [
            // TODO: Uncomment, when contacts are implemented.
            // ContextMenuButton(
            //   key: contact
            //       ? const Key('DeleteFromContactsButton')
            //       : const Key('AddToContactsButton'),
            //   label: contact
            //       ? 'btn_delete_from_contacts'.l10n
            //       : 'btn_add_to_contacts'.l10n,
            //   onPressed: contact ? c.removeFromContacts : c.addToContacts,
            //   trailing: SvgIcon(
            //     contact ? SvgIcons.deleteContact : SvgIcons.addContact,
            //   ),
            //   inverted: SvgIcon(
            //     contact
            //         ? SvgIcons.deleteContactWhite
            //         : SvgIcons.addContactWhite,
            //   ),
            // ),
            // ContextMenuButton(
            //   key: favorite
            //       ? const Key('DeleteFromFavoriteButton')
            //       : const Key('AddToFavoriteButton'),
            //   label: favorite
            //       ? 'btn_delete_from_favorites'.l10n
            //       : 'btn_add_to_favorites'.l10n,
            //   onPressed: favorite
            //       ? c.unfavoriteContact
            //       : () async {
            //           await c.addToContacts();
            //           await c.favoriteContact();
            //         },
            //   trailing: SvgIcon(
            //     favorite ? SvgIcons.favoriteSmall : SvgIcons.unfavoriteSmall,
            //   ),
            //   inverted: SvgIcon(
            //     favorite
            //         ? SvgIcons.favoriteSmallWhite
            //         : SvgIcons.unfavoriteSmallWhite,
            //   ),
            // ),
            if (dialog?.id.isLocal == false) ...[
              ContextMenuButton(
                label: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
                trailing: SvgIcon(
                  isMuted ? SvgIcons.muteSmall : SvgIcons.unmuteSmall,
                ),
                inverted: SvgIcon(
                  isMuted ? SvgIcons.muteSmallWhite : SvgIcons.unmuteSmallWhite,
                ),
                onPressed: isMuted ? c.unmuteChat : c.muteChat,
              ),
              ContextMenuButton(
                label: 'btn_delete_chat'.l10n,
                trailing: const SvgIcon(SvgIcons.delete19),
                inverted: const SvgIcon(SvgIcons.delete19White),
                onPressed: () => _hideChat(c, context),
              ),
              ContextMenuButton(
                key: const Key('ClearHistoryButton'),
                label: 'btn_clear_history'.l10n,
                trailing: const SvgIcon(SvgIcons.cleanHistory),
                inverted: const SvgIcon(SvgIcons.cleanHistoryWhite),
                onPressed: () => _clearChat(c, context),
              ),
            ],
            ContextMenuButton(
              onPressed: () => _reportUser(c, context),
              label: 'btn_report'.l10n,
              trailing: const SvgIcon(SvgIcons.report),
              inverted: const SvgIcon(SvgIcons.reportWhite),
            ),
            if (c.isBlocked == null)
              ContextMenuButton(
                key: const Key('Block'),
                label: 'btn_block'.l10n,
                onPressed: () => _blockUser(c, context),
                trailing: const SvgIcon(SvgIcons.block),
                inverted: const SvgIcon(SvgIcons.blockWhite),
              )
          ],
          child: Container(
            padding: const EdgeInsets.only(left: 28, right: 21),
            height: double.infinity,
            child: const SvgIcon(SvgIcons.more),
          ),
        ),
      );
    });

    final Widget title = Row(
      children: [
        const StyledBackButton(),
        Center(
          child: AvatarWidget.fromRxUser(c.user, radius: AvatarRadius.medium),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Obx(() {
              final String? subtitle = c.user?.user.value.getStatus();

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    c.user!.title,
                    style: style.fonts.big.regular.onBackground,
                  ),
                  if (subtitle?.isNotEmpty == true)
                    Text(
                      key: Key(
                        c.user?.user.value.presence?.name.capitalizeFirst ?? '',
                      ),
                      subtitle!,
                      style: style.fonts.small.regular.secondary,
                    )
                ],
              );
            }),
          ),
        ),
        const SizedBox(width: 10),
      ],
    );

    return Row(
      children: [
        Expanded(
          child: title,
        ),
        const SizedBox(width: 8),
        AnimatedButton(
          onPressed: () => router.chat(ChatId.local(c.user!.user.value.id)),
          child: const SvgIcon(SvgIcons.chat),
        ),
        const SizedBox(width: 28),
        AnimatedButton(
          onPressed: () => c.call(true),
          child: const SvgIcon(SvgIcons.chatVideoCall),
        ),
        const SizedBox(width: 28),
        AnimatedButton(
          key: const Key('AudioCall'),
          onPressed: () => c.call(false),
          child: const SvgIcon(SvgIcons.chatAudioCall),
        ),
        moreButton,
      ],
    );
  }

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    return Obx(() {
      // TODO: Uncomment, when contacts are implemented.
      // final bool contact = c.contact.value != null;
      // final bool favorite =
      //     c.contact.value?.contact.value.favoritePosition != null;

      final RxChat? dialog = c.user?.dialog.value;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // TODO: Uncomment, when contacts are implemented.
          // ActionButton(
          //   text: contact
          //       ? 'btn_delete_from_contacts'.l10n
          //       : 'btn_add_to_contacts'.l10n,
          //   onPressed: contact ? c.removeFromContacts : c.addToContacts,
          //   trailing: SvgIcon(
          //     contact ? SvgIcons.deleteContact16 : SvgIcons.addContact16,
          //   ),
          // ),
          // ActionButton(
          //   text: favorite
          //       ? 'btn_delete_from_favorites'.l10n
          //       : 'btn_add_to_favorites'.l10n,
          //   onPressed: favorite ? c.unfavoriteContact : c.favoriteContact,
          //   trailing: SvgIcon(
          //     favorite ? SvgIcons.favorite16 : SvgIcons.unfavorite16,
          //   ),
          // ),

          if (dialog?.id.isLocal == false) ...[
            Obx(() {
              final bool isMuted = dialog?.chat.value.muted != null;

              return ActionButton(
                text: isMuted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
                trailing:
                    SvgIcon(isMuted ? SvgIcons.muted16 : SvgIcons.unmuted16),
                onPressed: isMuted ? c.unmuteChat : c.muteChat,
              );
            }),
            ActionButton(
              text: 'btn_delete_chat'.l10n,
              trailing: const SvgIcon(SvgIcons.delete),
              onPressed: () => _hideChat(c, context),
            ),
            ActionButton(
              key: const Key('ClearHistoryButton'),
              text: 'btn_clear_history'.l10n,
              trailing: const SvgIcon(SvgIcons.cleanHistory16),
              onPressed: () => _clearChat(c, context),
            ),
          ],
          ActionButton(
            text: 'btn_report'.l10n,
            trailing: const SvgIcon(SvgIcons.report16),
            onPressed: () => _reportUser(c, context),
          ),
          Obx(() {
            if (c.isBlocked != null) {
              return const SizedBox();
            }

            return ActionButton(
              key: const Key('Block'),
              text: 'btn_block'.l10n,
              onPressed: () => _blockUser(c, context),
              trailing: const SvgIcon(SvgIcons.blockSmall),
            );
          }),
        ],
      );
    });
  }

  /// Opens a confirmation popup hiding the [Chat]-dialog with the [User].
  Future<void> _hideChat(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [
        TextSpan(text: 'alert_dialog_will_be_deleted1'.l10n),
        TextSpan(
          text: c.user?.title,
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
          text: c.user?.title,
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
          text: c.user?.title,
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

  /// Opens a confirmation popup reporting the [User].
  Future<void> _reportUser(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_report'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_reported1'.l10n),
        TextSpan(
          text: c.user?.title,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_user_will_be_reported2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(state: c.reporting, label: 'label_reason'.l10n),
      ],
      button: (context) {
        return Obx(() {
          return PrimaryButton(
            title: 'btn_proceed'.l10n,
            onPressed: c.reporting.isEmpty.value
                ? null
                : () => Navigator.of(context).pop(true),
          );
        });
      },
    );

    if (result == true) {
      await c.report();
    }
  }
}
