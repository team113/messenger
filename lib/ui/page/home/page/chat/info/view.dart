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

import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '/domain/model/chat.dart';
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
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
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
      init: ChatInfoController(id, Get.find(), Get.find(), Get.find()),
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
              child: ListView(
                controller: c.scrollController,
                key: const Key('ChatInfoScrollable'),
                children: [
                  const SizedBox(height: 8),
                  Block(
                    title: 'label_public_information'.l10n,
                    children: [
                      BigAvatarWidget.chat(
                        c.chat,
                        key: Key('ChatAvatar_${c.chat!.id}'),
                        loading: c.avatar.value.isLoading,
                        onUpload: c.pickAvatar,
                        onDelete: c.chat?.avatar.value != null
                            ? c.deleteAvatar
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _name(c, context),
                    ],
                  ),
                  if (!c.isMonolog) ...[
                    Block(
                      title: 'label_chat_members'.l10n,
                      children: [_members(c, context)],
                    ),
                    Block(
                      title: 'label_direct_chat_link'.l10n,
                      children: [
                        DirectLinkField(
                          c.chat?.chat.value.directLink,
                          onSubmit: c.createChatDirectLink,
                        ),
                      ],
                    ),
                  ],
                  if (!c.isMonolog) Block(children: [_actions(c, context)]),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);

  /// Returns a [Chat.name] editable field.
  Widget _name(ChatInfoController c, BuildContext context) {
    return Obx(() {
      return _padding(
        ReactiveTextField(
          key: const Key('RenameChatField'),
          state: c.name,
          label: c.chat?.chat.value.name == null
              ? c.chat?.title.value
              : 'label_name'.l10n,
          hint: 'label_chat_name_hint'.l10n,
          onSuffixPressed: c.name.text.isEmpty
              ? null
              : () {
                  PlatformUtils.copy(text: c.name.text);
                  MessagePopup.success('label_copied'.l10n);
                },
          trailing: c.name.text.isEmpty
              ? null
              : Transform.translate(
                  offset: const Offset(0, -1),
                  child: const SvgIcon(SvgIcons.copy),
                ),
        ),
      );
    });
  }

  /// Returns a list of [Chat.members].
  Widget _members(ChatInfoController c, BuildContext context) {
    return Obx(() {
      final RxUser? me = c.chat!.members[c.me];
      final List<RxUser> members = [];

      for (var u in c.chat!.members.entries) {
        if (u.key != c.me) {
          members.add(u.value);
        }
      }

      if (me != null) {
        members.insert(0, me);
      }

      final style = Theme.of(context).style;

      Widget bigButton({
        Key? key,
        Widget? leading,
        required Widget title,
        void Function()? onTap,
      }) {
        return SizedBox(
          key: key,
          height: 56,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              border: style.cardBorder,
              color: style.colors.transparent,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: style.cardRadius,
              color: style.cardColor.darken(0.05),
              child: InkWell(
                borderRadius: style.cardRadius,
                onTap: onTap,
                hoverColor: style.cardColor.darken(0.08),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  child: Row(
                    children: [
                      const SizedBox(width: 4),
                      Expanded(
                        child: DefaultTextStyle(
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: style.fonts.normal.regular.primary,
                          child: title,
                        ),
                      ),
                      if (leading != null) ...[
                        const SizedBox(width: 12),
                        leading,
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          bigButton(
            key: const Key('AddMemberButton'),
            leading: const SvgIcon(SvgIcons.addUser),
            title: Text('btn_add_member'.l10n),
            onTap: () =>
                AddChatMemberView.show(context, chatId: c.chat?.id ?? id),
          ),
          const SizedBox(height: 3),
          ...members.map((e) {
            final bool inCall = c.chat?.chat.value.ongoingCall?.members
                    .any((u) => u.user.id == e.id) ==
                true;

            return MemberTile(
              user: e,
              canLeave: e.id == c.me,
              inCall: e.id == c.me || c.chat?.chat.value.ongoingCall == null
                  ? null
                  : inCall,
              onTap: () => router.user(e.id, push: true),
              onCall: inCall
                  ? () => c.removeChatCallMember(e.id)
                  : () => c.redialChatCallMember(e.id),
              onKick: () => c.removeChatMember(e.id),
            );
          }),
        ],
      );
    });
  }

  /// Returns the action buttons to do with this [Chat].
  Widget _actions(ChatInfoController c, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          onPressed: () {},
          text: 'btn_report'.l10n,
          trailing: Transform.translate(
            offset: const Offset(0, -1),
            child: const SvgIcon(SvgIcons.report),
          ),
        ),
      ],
    );
  }

  /// Returns information about the [Chat] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    final bool favorite = c.chat?.chat.value.favoritePosition != null;
    final bool muted = c.chat?.chat.value.muted != null;
    final bool isLocal = c.chat?.chat.value.id.isLocal == true;

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
              child: AvatarWidget.fromRxChat(
                c.chat,
                radius: AvatarRadius.medium,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DefaultTextStyle.merge(
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            c.chat!.title.value,
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
                  if (!c.isMonolog && c.chat != null)
                    ChatSubtitle(c.chat!, c.me),
                ],
              ),
            ),
          ),
          const SizedBox(width: 40),
          AnimatedButton(
            child: const SvgIcon(SvgIcons.chat),
            onPressed: () => router.chat(c.chat?.id ?? id),
          ),
          const SizedBox(width: 28),
          AnimatedButton(
            child: const SvgIcon(SvgIcons.chatVideoCall),
            onPressed: () => c.call(true),
          ),
          const SizedBox(width: 28),
          AnimatedButton(
            child: const SvgIcon(SvgIcons.chatAudioCall),
            onPressed: () => c.call(false),
          ),
          const SizedBox(width: 10),
          Obx(() {
            return AnimatedButton(
              child: SafeAnimatedSwitcher(
                duration: 250.milliseconds,
                child: ContextMenuRegion(
                  key: c.moreKey,
                  selector: c.moreKey,
                  alignment: Alignment.topRight,
                  enablePrimaryTap: true,
                  margin: const EdgeInsets.only(bottom: 4, left: 20),
                  actions: [
                    ContextMenuButton(
                      key: Key(
                        favorite
                            ? 'UnfavoriteChatButton'
                            : 'FavoriteChatButton',
                      ),
                      label: favorite
                          ? 'btn_delete_from_favorites'.l10n
                          : 'btn_add_to_favorites'.l10n,
                      trailing: SvgIcon(
                        favorite
                            ? SvgIcons.favoriteSmall
                            : SvgIcons.unfavoriteSmall,
                      ),
                      onPressed: favorite ? c.unfavoriteChat : c.favoriteChat,
                    ),
                    if (!c.isMonolog)
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
                        onPressed: muted ? c.unmuteChat : c.muteChat,
                      ),
                    if (!isLocal)
                      ContextMenuButton(
                        key: const Key('ClearHistoryButton'),
                        label: 'btn_clear_history'.l10n,
                        trailing: const SvgIcon(SvgIcons.cleanHistory),
                        onPressed: () => _clearChat(c, context),
                      ),
                    if (!c.isMonolog)
                      ContextMenuButton(
                        key: const Key('LeaveGroupButton'),
                        label: 'btn_leave_group'.l10n,
                        trailing: const SvgIcon(SvgIcons.leaveGroup),
                        onPressed: () => _leaveGroup(c, context),
                      ),
                    ContextMenuButton(
                      key: const Key('HideChatButton'),
                      label: 'btn_delete_chat'.l10n,
                      trailing: const SvgIcon(
                        SvgIcons.cleanHistory,
                      ),
                      onPressed: () => _hideChat(c, context),
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
          text: c.chat?.title.value,
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
          text: c.chat?.title.value,
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
