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

import 'package:expandable_text/expandable_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '/api/backend/schema.dart' show Presence;
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/home/widget/scroll_keyboard_handler.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/line_divider.dart';
import '/ui/widget/obscured_selection_area.dart';
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
                    ? Text('label_unknown_page'.l10n)
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
                  BlocklistRecordWidget(c.isBlocked!, onUnblock: c.unblock),
                ],
              ),
            _name(c, context, index: c.isBlocked != null ? 2 : 1),
            SelectionContainer.disabled(
              child: Block(children: [_actions(c, context)]),
            ),
            const SizedBox(height: 8),
          ];

          return Scaffold(
            appBar: CustomAppBar(title: _bar(c, context)),
            body: ScrollKeyboardHandler(
              scrollController: c.scrollController,
              child: Scrollbar(
                controller: c.scrollController,
                child: ObscuredSelectionArea(
                  contextMenuBuilder: (_, _) => const SizedBox(),
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
                    addAutomaticKeepAlives: false,
                  ),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Returns the [User.name] visual representation.
  Widget _name(UserController c, BuildContext context, {required int index}) {
    final style = Theme.of(context).style;

    final UserBio? bio = c.user?.user.value.bio;

    return Block(
      folded: c.isFavorite,
      padding: EdgeInsets.fromLTRB(32, 8, 32, 16),
      children: [
        Obx(() {
          final List<Widget> children = [
            Container(width: double.infinity),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
              child: Text(
                key: Key('UserViewTitleKey'),
                '${c.user?.title()}',
                style: style.fonts.larger.regular.onBackground,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 4),
            if (c.contactId != null) ...[
              const SizedBox(height: 4),
              const SizedBox(height: 1),
              WidgetButton(
                onPressed: () {
                  final ItemPosition? first =
                      c.positionsListener.itemPositions.value.firstOrNull;

                  // If the [Block] containing this button isn't fully visible,
                  //then animate to it's beginning.
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
            ],
          ];

          return Column(
            key: Key(c.nameEditing.value.toString()),
            children: children,
          );
        }),
        const SizedBox(height: 1),
        Obx(() {
          final String? subtitle = c.user?.user.value.getSubtitle();

          if (subtitle?.isNotEmpty != true) {
            return const SizedBox();
          }

          bool isOnline = false;
          bool isAway = false;

          switch (c.user!.user.value.presence) {
            case Presence.present:
              isOnline = c.user!.user.value.online;
              break;

            case Presence.away:
              isAway = c.user!.user.value.online;
              break;

            case null || Presence.artemisUnknown:
              // No-op.
              break;
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isOnline || isAway)
                    Transform.translate(
                      offset: Offset(0, 0.5),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isAway
                              ? style.colors.warning
                              : style.colors.acceptAuxiliary,
                          shape: BoxShape.circle,
                        ),
                        width: 10,
                        height: 10,
                      ),
                    ),
                  const SizedBox(width: 3),
                  Text(
                    key: Key(
                      c.user?.user.value.presence?.name.capitalized ?? '',
                    ),
                    subtitle!,
                    style: style.fonts.small.regular.secondary,
                  ),
                ],
              ),
              const SizedBox(height: 4),
            ],
          );
        }),
        Obx(() {
          final String? subtitle = c.user?.user.value.status?.val;

          if (subtitle?.isNotEmpty != true) {
            return const SizedBox();
          }

          return Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(subtitle!, style: style.fonts.small.regular.secondary),
              const SizedBox(height: 4),
            ],
          );
        }),
        const SizedBox(height: 8),
        Stack(
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
          ],
        ),
        if (bio != null) ...[
          const SizedBox(height: 12),
          ExpandableText(
            bio.val,
            expandText: 'label_expandable_more'.l10n,
            collapseText: '',
            maxLines: 3,
            linkColor: style.colors.primary,
            animation: true,
            collapseOnTextTap: false,
            style: style.fonts.small.regular.secondary,
            urlStyle: style.fonts.small.regular.primary,
            onUrlTap: (url) => launchUrlString(url),
          ),
        ],
        const SizedBox(height: 16),
        LineDivider('label_identifier'.l10n),
        const SizedBox(height: 21),
        ReactiveTextField.copyable(
          key: const Key('NumCopyable'),
          text: '${c.user?.user.value.num}',
          label: 'label_num'.l10n,
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  /// Returns information about the [User] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(UserController c, BuildContext context) {
    final Widget title = Row(
      children: [StyledBackButton(withLabel: true), SizedBox(width: 10)],
    );

    return Row(
      children: [
        Expanded(child: title),
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
        const SizedBox(width: 20),
      ],
    );
  }

  /// Returns the action buttons to do with this [User].
  Widget _actions(UserController c, BuildContext context) {
    // TODO: Uncomment, when contacts are implemented.
    // final bool contact = c.contact.value != null;
    // final bool favorite =
    //     c.contact.value?.contact.value.favoritePosition != null;

    final bool favorite =
        c.user?.dialog.value?.chat.value.favoritePosition != null;
    final bool muted = c.user?.dialog.value?.chat.value.muted != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          key: favorite
              ? const Key('UnfavoriteButton')
              : const Key('FavoriteButton'),
          text: favorite
              ? 'btn_delete_from_favorites'.l10n
              : 'btn_add_to_favorites'.l10n,
          onPressed: favorite ? c.unfavoriteChat : c.favoriteChat,
          trailing: SvgIcon(
            favorite ? SvgIcons.favorite19 : SvgIcons.unfavorite19,
          ),
        ),
        ActionButton(
          key: muted ? const Key('UnmuteButton') : const Key('MuteButton'),
          text: muted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
          onPressed: muted ? c.unmuteChat : c.muteChat,
          trailing: SvgIcon(muted ? SvgIcons.muted19 : SvgIcons.unmuted19),
        ),
        ActionButton(
          key: const Key('ClearHistoryButton'),
          text: 'btn_clear_history'.l10n,
          onPressed: () => _clearChat(c, context),
          trailing: SvgIcon(SvgIcons.cleanHistory19),
        ),
        ActionButton(
          key: const Key('DeleteChatButton'),
          text: 'btn_delete_chat'.l10n,
          onPressed: () => _hideChat(c, context),
          trailing: SvgIcon(SvgIcons.delete19),
        ),
        ActionButton(
          text: 'btn_report'.l10n,
          trailing: const SvgIcon(SvgIcons.report19),
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
            trailing: const SvgIcon(SvgIcons.blockRed19),
            danger: true,
          );
        }),
      ],
    );
  }

  /// Opens a confirmation popup blocking the [User].
  Future<void> _blockUser(UserController c, BuildContext context) async {
    final style = Theme.of(context).style;

    c.reason.clear();

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_user_will_be_blocked1'.l10n),
        TextSpan(
          text: c.user?.title(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_user_will_be_blocked2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(
          state: c.reason,
          label: 'label_reason'.l10n,
          hint: 'label_reason_hint'.l10n,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          formatters: [LengthLimitingTextInputFormatter(100)],
        ),
      ],
      button: (context) {
        return Obx(() {
          final bool enabled = c.reason.error.value == null;

          return PrimaryButton(
            key: const Key('Proceed'),
            danger: true,
            onPressed: enabled
                ? () {
                    if (c.reason.error.value != null) {
                      return;
                    }

                    Navigator.of(context).pop(true);
                  }
                : null,
            title: 'btn_block'.l10n,
            leading: SvgIcon(enabled ? SvgIcons.blockWhite : SvgIcons.block),
          );
        });
      },
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
          text: c.user?.title(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_user_will_be_reported2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(
          state: c.reporting,
          label: 'label_reason'.l10n,
          hint: 'label_reason_hint'.l10n,
          floatingLabelBehavior: FloatingLabelBehavior.always,
        ),
      ],
      button: (context) {
        return Obx(() {
          final bool enabled = !c.reporting.isEmpty.value;

          return PrimaryButton(
            title: 'btn_report'.l10n,
            onPressed: enabled ? () => Navigator.of(context).pop(true) : null,
            leading: SvgIcon(
              enabled ? SvgIcons.reportWhite : SvgIcons.reportGrey,
            ),
          );
        });
      },
    );

    if (result == true) {
      await c.report();
    }
  }

  /// Opens a confirmation popup clearing this [Chat].
  Future<void> _clearChat(UserController c, BuildContext context) async {
    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      button: (context) => MessagePopup.defaultButton(
        context,
        icon: SvgIcons.cleanHistoryWhite,
        label: 'btn_clear'.l10n,
      ),
    );

    if (result == true) {
      await c.clearChat();
    }
  }

  /// Opens a confirmation popup hiding this [Chat].
  Future<void> _hideChat(UserController c, BuildContext context) async {
    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [TextSpan(text: 'label_to_restore_chats_use_search'.l10n)],
      button: (context) => MessagePopup.deleteButton(
        context,
        icon: SvgIcons.delete19White,
        label: 'btn_delete'.l10n,
      ),
    );

    if (result == true) {
      await c.hideChat();
    }
  }
}
