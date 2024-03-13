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
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

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
import '/ui/page/home/widget/quick_button.dart';
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

          return Scaffold(
            appBar: CustomAppBar(title: _bar(c, context)),
            body: Scrollbar(
              controller: c.scrollController,
              child: SelectionArea(
                child: ListView(
                  controller: c.scrollController,
                  key: const Key('ChatInfoScrollable'),
                  children: [
                    const SizedBox(height: 8),
                    _profile(c, context),
                    _quick(c, context),
                    if (!c.isMonolog) ...[
                      SelectionContainer.disabled(child: _link(c, context)),
                      SelectionContainer.disabled(child: _members(c, context)),
                    ],
                    SelectionContainer.disabled(
                      child: Block(children: [_actions(c, context)]),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

  /// Builds the [Block] displaying a [ChatAvatar], if any, and [ChatName].
  Widget _profile(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      overlay: [
        EditBlockButton(
          key: const Key('EditProfileButton'),
          onPressed: c.profileEditing.toggle,
          editing: c.profileEditing.value,
        ),
      ],
      children: [
        SelectionContainer.disabled(
          child: BigAvatarWidget.chat(
            c.chat,
            key: Key('ChatAvatar_${c.chat!.id}'),
            loading: c.avatar.value.isLoading,
            error: c.avatar.value.errorMessage,
          ),
        ),
        Obx(() {
          final List<Widget> children;

          if (c.profileEditing.value) {
            children = [
              const SizedBox(height: 4),
              SelectionContainer.disabled(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    WidgetButton(
                      key: const Key('UploadAvatar'),
                      onPressed: c.pickAvatar,
                      child: Text(
                        'btn_upload'.l10n,
                        style: style.fonts.small.regular.primary,
                      ),
                    ),
                    if (c.chat?.avatar.value != null) ...[
                      Text(
                        'space_or_space'.l10n,
                        style: style.fonts.small.regular.onBackground,
                      ),
                      WidgetButton(
                        key: const Key('DeleteAvatar'),
                        onPressed: c.deleteAvatar,
                        child: Text(
                          'btn_delete'.l10n.toLowerCase(),
                          style: style.fonts.small.regular.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SelectionContainer.disabled(
                child: ReactiveTextField(
                  key: const Key('RenameChatField'),
                  state: c.name,
                  label: 'label_name'.l10n,
                  hint: c.chat?.title,
                  formatters: [LengthLimitingTextInputFormatter(100)],
                ),
              ),
              const SizedBox(height: 4),
            ];
          } else {
            children = [
              const SizedBox(height: 18),
              Container(width: double.infinity),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Text(
                  c.chat?.title ?? c.name.text,
                  style: style.fonts.large.regular.onBackground,
                ),
              ),
            ];
          }

          return AnimatedSizeAndFade(
            fadeDuration: 250.milliseconds,
            sizeDuration: 250.milliseconds,
            child: Column(
              key: Key(c.profileEditing.value.toString()),
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
      padding: Block.defaultPadding.copyWith(bottom: 10),
      overlay: [
        EditBlockButton(
          key: const Key('EditLinkButton'),
          onPressed: c.linkEditing.toggle,
          editing: c.linkEditing.value,
        ),
      ],
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
                    c.linkEditing.value = false;
                    await c.deleteChatDirectLink();
                  } else {
                    await c.createChatDirectLink(s);
                    c.linkEditing.value = false;
                  }
                },
                background: c.background.value,
                editing: c.linkEditing.value,
                onEditing: (b) => c.linkEditing.value = b,
              ),
            ],
          );
        })
      ],
    );
  }

  /// Returns the [Block] displaying the [Chat.members].
  Widget _members(ChatInfoController c, BuildContext context) {
    return Block(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 8),
      title: 'label_participants'
          .l10nfmt({'count': c.chat!.chat.value.membersCount}),
      overlay: [
        Positioned(
          top: 0,
          right: 0,
          child: AnimatedButton(
            key: const Key('AddMemberButton'),
            decorator: (child) => Padding(
              padding: const EdgeInsets.fromLTRB(2, 4, 2, 2),
              child: child,
            ),
            onPressed: () => AddChatMemberView.show(context, chatId: id),
            child: const SvgIcon(SvgIcons.addMemberSmall),
          ),
        ),
      ],
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
      ],
    );
  }

  /// Returns the action buttons to do with this [Chat].
  Widget _actions(ChatInfoController c, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        if (!c.isMonolog)
          ActionButton(
            onPressed: () {},
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
    final Widget editButton = Obx(key: const Key('MoreButton'), () {
      final bool favorite = c.chat?.chat.value.favoritePosition != null;
      final bool hasCall = c.chat?.chat.value.ongoingCall != null;

      return ContextMenuRegion(
        key: c.moreKey,
        selector: c.moreKey,
        alignment: Alignment.topRight,
        enablePrimaryTap: true,
        margin: const EdgeInsets.only(bottom: 4, left: 20),
        actions: [
          ContextMenuButton(
            label: 'label_open_chat'.l10n,
            onPressed: () => router.chat(id),
            trailing: const SvgIcon(SvgIcons.chat18),
            inverted: const SvgIcon(SvgIcons.chat18White),
          ),
          ContextMenuButton(
            label: 'btn_audio_call'.l10n,
            onPressed: hasCall ? null : () => c.call(false),
            trailing: hasCall
                ? const SvgIcon(SvgIcons.makeAudioCallDisabled)
                : const SvgIcon(SvgIcons.makeAudioCall),
            inverted: const SvgIcon(SvgIcons.makeAudioCallWhite),
          ),
          ContextMenuButton(
            label: 'btn_video_call'.l10n,
            onPressed: hasCall ? null : () => c.call(true),
            trailing: Transform.translate(
              offset: const Offset(2, 0),
              child: hasCall
                  ? const SvgIcon(SvgIcons.makeVideoCallDisabled)
                  : const SvgIcon(SvgIcons.makeVideoCall),
            ),
            inverted: Transform.translate(
              offset: const Offset(2, 0),
              child: const SvgIcon(SvgIcons.makeVideoCallWhite),
            ),
          ),
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
          if (!c.isMonolog)
            ContextMenuButton(
              onPressed: () {
                // TODO: Implement.
              },
              label: 'btn_report'.l10n,
              trailing: const SvgIcon(SvgIcons.report),
              inverted: const SvgIcon(SvgIcons.reportWhite),
            ),
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
          padding: const EdgeInsets.only(left: 31, right: 25),
          height: double.infinity,
          child: const SvgIcon(SvgIcons.more),
        ),
      );
    });

    final Widget title;

    if (!c.displayName.value) {
      title = Row(
        key: const Key('Profile'),
        children: [
          const StyledBackButton(),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 0),
              child: Center(child: Text('label_profile'.l10n)),
            ),
          ),
        ],
      );
    } else {
      title = Row(
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
    }

    return Row(
      children: [
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: title,
          ),
        ),
        editButton,
      ],
    );
  }

  /// Returns the [QuickButton] for quick actions to do with this [Chat].
  Widget _quick(ChatInfoController c, BuildContext context) {
    return SelectionContainer.disabled(
      child: Center(
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
          constraints:
              context.isNarrow ? null : const BoxConstraints(maxWidth: 400),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: QuickButton(
                  label: 'label_chat'.l10n,
                  icon: SvgIcons.chat,
                  onPressed: () => router.chat(id),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: QuickButton(
                  label: 'btn_audio'.l10n,
                  icon: SvgIcons.chatAudioCall,
                  onPressed: () => c.call(false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: QuickButton(
                  label: 'btn_video'.l10n,
                  icon: SvgIcons.chatVideoCall,
                  onPressed: () => c.call(true),
                ),
              ),
            ],
          ),
        ),
      ),
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
}
