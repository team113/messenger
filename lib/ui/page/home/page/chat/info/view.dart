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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/my_user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/info/add_member/controller.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/chat_subtitle.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/login/widget/primary_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the [Routes.chatInfo] page.
class ChatInfoView extends StatelessWidget {
  const ChatInfoView(this.id, {super.key});

  /// ID of the [Chat] of this info page.
  final ChatId id;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ChatInfoController>(
      key: const Key('ChatInfoView'),
      init: ChatInfoController(
        id,
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      tag: id.val,
      global: !Get.isRegistered<ChatInfoController>(tag: id.val),
      builder: (c) {
        return Obx(() {
          if (c.status.value.isLoading) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CustomProgressIndicator()),
            );
          } else if (!c.status.value.isSuccess) {
            return Scaffold(
              appBar: AppBar(),
              body: Center(child: Text('label_no_chat_found'.l10n)),
            );
          }

          final List<Widget> blocks = [
            const SizedBox(height: 8),
            _avatar(c, context),
            _name(c, context),
            if (!c.isMonolog) ...[
              SelectionContainer.disabled(child: _link(c, context)),
              SelectionContainer.disabled(child: _members(c, context)),
            ],
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
                  key: const Key('ChatInfoScrollable'),
                  scrollController: c.scrollController,
                  itemScrollController: c.itemScrollController,
                  itemPositionsListener: c.positionsListener,
                  itemCount: blocks.length,
                  itemBuilder: (_, i) => Obx(() {
                    return HighlightedContainer(
                      highlight: c.highlighted.value == i,
                      child: blocks[i],
                    );
                  }),
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Returns the [Block] displaying a [Chat.avatar].
  Widget _avatar(ChatInfoController c, BuildContext context) {
    return Block(
      children: [
        SelectionContainer.disabled(
          child: BigAvatarWidget.chat(
            c.chat,
            key: Key('ChatAvatar_${c.chat!.id}'),
            loading: c.avatar.value.isLoading,
            error: c.avatar.value.errorMessage,
            onUpload: c.pickAvatar,
            onDelete: c.chat?.avatar.value != null ? c.deleteAvatar : null,
          ),
        ),
      ],
    );
  }

  /// Returns the [Block] displaying a [Chat.name].
  Widget _name(ChatInfoController c, BuildContext context) {
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
                  key: const Key('RenameChatField'),
                  state: c.name,
                  label: 'label_name'.l10n,
                  hint: c.chat?.title,
                  floatingLabelBehavior: FloatingLabelBehavior.always,
                  formatters: [LengthLimitingTextInputFormatter(100)],
                ),
              ),
              const SizedBox(height: 16),
              SelectionContainer.disabled(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 16),
                    WidgetButton(
                      key: const Key('SaveNameButton'),
                      onPressed: c.submitName,
                      child: Text(
                        'btn_save'.l10n,
                        style: style.fonts.small.regular.primary,
                      ),
                    ),
                    const Spacer(),
                    WidgetButton(
                      onPressed: () {
                        c.name.text = c.chat!.chat.value.name?.val ?? '';
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
              ),
              const SizedBox(height: 4),
            ];
          } else {
            children = [
              Container(width: double.infinity),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  c.chat?.title ?? c.name.text,
                  style: style.fonts.larger.regular.onBackground,
                ),
              ),
              const SizedBox(height: 12),
              WidgetButton(
                key: const Key('EditNameButton'),
                onPressed: () {
                  final ItemPosition? first =
                      c.positionsListener.itemPositions.value.firstOrNull;

                  // If the [Block] containing this button isn't fully
                  // visible, then animate to it's beginning.
                  if (first?.index == 2 && first!.itemLeadingEdge < 0) {
                    c.itemScrollController.scrollTo(
                      index: 2,
                      curve: Curves.ease,
                      duration: const Duration(milliseconds: 600),
                    );
                    c.highlight(2);
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

  /// Returns the [Chat.directLink] visual representation.
  Widget _link(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      title: 'label_direct_chat_link'.l10n,
      children: [
        Obx(() {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 8, 24),
                child: Text(
                  'label_direct_chat_link_in_chat_description'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
              ),
              DirectLinkField(
                c.chat?.chat.value.directLink,
                onSubmit: (s) async {
                  if (s == null) {
                    await c.deleteChatDirectLink();
                  } else {
                    await c.createChatDirectLink(s);
                  }
                },
                background: c.background.value,
                onEditing: (b) {
                  if (b) {
                    final ItemPosition? first =
                        c.positionsListener.itemPositions.value.firstOrNull;

                    // If the [Block] containing this widget isn't fully
                    // visible, then animate to it's beginning.
                    if (first?.index == 3 && first!.itemLeadingEdge < 0) {
                      c.itemScrollController.scrollTo(
                        index: 3,
                        curve: Curves.ease,
                        duration: const Duration(milliseconds: 600),
                      );
                      c.highlight(3);
                    }
                  }
                },
              ),
            ],
          );
        })
      ],
    );
  }

  /// Returns the [Block] displaying the [Chat.members].
  Widget _members(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      padding: Block.defaultPadding.copyWith(right: 0, left: 0),
      title: 'label_participants'
          .l10nfmt({'count': c.chat!.chat.value.membersCount}),
      children: [
        Obx(() {
          final List<RxUser> members = [];

          for (var u in c.chat!.members.values) {
            if (u.user.id != c.me) {
              members.add(u.user);
            }
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 500),
                child: Scrollbar(
                  controller: c.membersScrollController,
                  child: ListView.builder(
                    key: const Key('ChatMembers'),
                    controller: c.membersScrollController,
                    shrinkWrap: true,
                    itemCount: members.length + 1,
                    itemBuilder: (_, i) {
                      i--;

                      Widget child;

                      final bool hasCall =
                          c.chat?.chat.value.ongoingCall != null;

                      if (i == -1) {
                        final MyUser? myUser = c.myUser.value;
                        final bool inCall = c.chat?.inCall.value == true;

                        child = MemberTile(
                          myUser: myUser,
                          inCall: hasCall ? inCall : null,
                          onCall: inCall
                              ? () {
                                  if (myUser != null) {
                                    c.removeChatCallMember(myUser.id);
                                  }
                                }
                              : c.joinCall,
                        );
                      } else {
                        final RxUser member = members[i];

                        final bool inCall = c
                                .chat?.chat.value.ongoingCall?.members
                                .any((u) => u.user.id == member.id) ==
                            true;

                        child = MemberTile(
                          user: member,
                          inCall: hasCall ? inCall : null,
                          onTap: () =>
                              router.chat(member.user.value.dialog, push: true),
                          onCall: inCall
                              ? () => c.removeChatCallMember(member.id)
                              : () => c.redialChatCallMember(member.id),
                          onKick: () => c.removeChatMember(member.id),
                        );
                      }

                      child = Padding(
                        padding: const EdgeInsets.only(right: 10, left: 10),
                        child: child,
                      );

                      if (i == members.length - 1 && c.haveNext.isTrue) {
                        child = Column(
                          children: [
                            child,
                            CustomProgressIndicator(
                              key: const Key('MembersLoading'),
                              value:
                                  Config.disableInfiniteAnimations ? 0 : null,
                            )
                          ],
                        );
                      }

                      return child;
                    },
                  ),
                ),
              ),
            ],
          );
        }),
        const SizedBox(height: 16),
        WidgetButton(
          key: const Key('AddMemberButton'),
          onPressed: () => AddChatMemberView.show(context, chatId: id),
          child: Text(
            'btn_add_member'.l10n,
            style: style.fonts.small.regular.primary,
          ),
        ),
      ],
    );
  }

  /// Returns the action buttons to do with this [Chat].
  Widget _actions(ChatInfoController c, BuildContext context) {
    final bool favorite = c.chat?.chat.value.favoritePosition != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          onPressed: favorite ? c.unfavoriteChat : c.favoriteChat,
          text: favorite
              ? 'btn_delete_from_favorites'.l10n
              : 'btn_add_to_favorites'.l10n,
          trailing: SvgIcon(
            favorite ? SvgIcons.favorite16 : SvgIcons.unfavorite16,
          ),
        ),
        if (!c.isMonolog)
          ActionButton(
            onPressed: () => _reportChat(c, context),
            text: 'btn_report'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: const SvgIcon(SvgIcons.complaint),
            ),
          ),
        ActionButton(
          key: const Key('ClearHistoryButton'),
          onPressed: () => _clearChat(c, context),
          text: 'btn_clear_history'.l10n,
          trailing: const SvgIcon(SvgIcons.cleanHistorySmall),
        ),
        ActionButton(
          key: const Key('HideChatButton'),
          onPressed: () => _hideChat(c, context),
          text: 'btn_delete_chat'.l10n,
          trailing: const SvgIcon(SvgIcons.delete),
        ),
        if (!c.isMonolog)
          ActionButton(
            onPressed: () => _leaveGroup(c, context),
            text: 'btn_leave_group'.l10n,
            trailing: const SvgIcon(SvgIcons.leaveGroupSmall),
          ),
      ],
    );
  }

  /// Returns information about the [Chat] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    // [SvgIcons.more] buttons with its [ContextMenuRegion].
    final Widget moreButton = Obx(key: const Key('MoreButton'), () {
      final bool favorite = c.chat?.chat.value.favoritePosition != null;
      final bool muted = c.chat?.chat.value.muted != null;

      return AnimatedButton(
        child: ContextMenuRegion(
          key: c.moreKey,
          selector: c.moreKey,
          alignment: Alignment.topRight,
          enablePrimaryTap: true,
          margin: const EdgeInsets.only(bottom: 4, left: 6),
          actions: [
            ContextMenuButton(
              label: favorite
                  ? 'btn_delete_from_favorites'.l10n
                  : 'btn_add_to_favorites'.l10n,
              onPressed: favorite ? c.unfavoriteChat : c.favoriteChat,
              trailing: SvgIcon(
                favorite ? SvgIcons.favoriteSmall : SvgIcons.unfavoriteSmall,
              ),
              inverted: SvgIcon(
                favorite
                    ? SvgIcons.favoriteSmallWhite
                    : SvgIcons.unfavoriteSmallWhite,
              ),
            ),
            if (!c.isMonolog) ...[
              ContextMenuButton(
                key: Key(muted ? 'UnmuteChatButton' : 'MuteChatButton'),
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
                  muted ? SvgIcons.unmuteSmallWhite : SvgIcons.muteSmallWhite,
                ),
                onPressed: muted ? c.unmuteChat : c.muteChat,
              ),
              ContextMenuButton(
                onPressed: () => _reportChat(c, context),
                label: 'btn_report'.l10n,
                trailing: const SvgIcon(SvgIcons.report),
                inverted: const SvgIcon(SvgIcons.reportWhite),
              ),
            ],
            ContextMenuButton(
              onPressed: () => _clearChat(c, context),
              label: 'btn_clear_history'.l10n,
              trailing: const SvgIcon(SvgIcons.cleanHistory),
              inverted: const SvgIcon(SvgIcons.cleanHistoryWhite),
            ),
            ContextMenuButton(
              key: const Key('HideChatButton'),
              onPressed: () => _hideChat(c, context),
              label: 'btn_delete_chat'.l10n,
              trailing: const SvgIcon(SvgIcons.delete19),
              inverted: const SvgIcon(SvgIcons.delete19White),
            ),
            if (!c.isMonolog)
              ContextMenuButton(
                onPressed: () => _leaveGroup(c, context),
                label: 'btn_leave_group'.l10n,
                trailing: const SvgIcon(SvgIcons.leaveGroup),
                inverted: const SvgIcon(SvgIcons.leaveGroupWhite),
              ),
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
        Material(
          elevation: 6,
          type: MaterialType.circle,
          shadowColor: style.colors.onBackgroundOpacity27,
          color: style.colors.onPrimary,
          child: AvatarWidget.fromRxChat(
            c.chat,
            radius: AvatarRadius.medium,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: DefaultTextStyle.merge(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() {
                  return Row(
                    children: [
                      Flexible(
                        child: Text(
                          c.chat!.title,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: style.fonts.big.regular.onBackground,
                        ),
                      ),
                      Obx(() {
                        if (c.chat?.chat.value.muted == null) {
                          return const SizedBox();
                        }

                        return const Padding(
                          padding: EdgeInsets.only(left: 5),
                          child: SvgIcon(SvgIcons.muted),
                        );
                      }),
                    ],
                  );
                }),
                ChatSubtitle(c.chat!, c.me),
              ],
            ),
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
          onPressed: () => router.chat(id),
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

  /// Opens a confirmation popup leaving this [Chat].
  Future<void> _leaveGroup(ChatInfoController c, BuildContext context) async {
    final bool? result = await MessagePopup.alert(
      'label_leave_group'.l10n,
      description: [TextSpan(text: 'alert_you_will_leave_group'.l10n)],
    );

    if (result == true) {
      await c.removeChatMember(c.me!);
    }
  }

  /// Opens a confirmation popup hiding this [Chat].
  Future<void> _hideChat(ChatInfoController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_deleted1'.l10n),
        TextSpan(
          text: c.chat?.title,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_chat_will_be_deleted2'.l10n),
      ],
    );

    if (result == true) {
      await c.hideChat();
    }
  }

  /// Opens a confirmation popup clearing this [Chat].
  Future<void> _clearChat(ChatInfoController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_cleared1'.l10n),
        TextSpan(
          text: c.chat?.title,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_chat_will_be_cleared2'.l10n),
      ],
    );

    if (result == true) {
      await c.clearChat();
    }
  }

  /// Opens a confirmation popup reporting this [Chat].
  Future<void> _reportChat(ChatInfoController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_chat'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_reported1'.l10n),
        TextSpan(
          text: c.chat?.title,
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_chat_will_be_reported2'.l10n),
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
      await c.reportChat();
    }
  }
}
