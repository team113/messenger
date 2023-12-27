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
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '/config.dart';
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
import '/ui/page/home/widget/contact_info.dart';
import '/ui/page/home/widget/copy_or_share.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/paddings.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import 'controller.dart';

/// View of the [Routes.chatInfo] page.
class ChatInfoView extends StatelessWidget {
  const ChatInfoView(this.id, {super.key, this.edit = false});

  /// ID of the [Chat] of this info page.
  final ChatId id;

  /// Indicator whether the editing mode is enabled.
  final bool edit;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder<ChatInfoController>(
      key: const Key('ChatInfoView'),
      init: ChatInfoController(
        id,
        Get.find(),
        Get.find(),
        Get.find(),
        edit: edit,
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
                    Block(
                      children: [
                        const SizedBox(height: 8),
                        SelectionContainer.disabled(
                          child: Padding(
                            padding: Insets.basic.copyWith(top: 0, bottom: 0),
                            child: BigAvatarWidget.chat(
                              c.chat,
                              key: Key('ChatAvatar_${c.chat!.id}'),
                              loading: c.avatar.value.isLoading,
                              onUpload: c.editing.value ? c.pickAvatar : null,
                              onDelete: c.editing.value
                                  ? c.chat?.avatar.value != null
                                      ? c.deleteAvatar
                                      : null
                                  : null,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _name(c, context),
                      ],
                    ),
                    if (!c.isMonolog) ...[
                      SelectionContainer.disabled(
                        child: Block(
                          title: 'label_direct_chat_link'.l10n,
                          padding: Block.defaultPadding.copyWith(bottom: 10),
                          children: [
                            Obx(() {
                              final Widget child;

                              if (c.editing.value) {
                                child = Padding(
                                  padding:
                                      const EdgeInsets.only(top: 4, bottom: 12),
                                  child: DirectLinkField(
                                    c.chat?.chat.value.directLink,
                                    onSubmit: c.createChatDirectLink,
                                  ),
                                );
                              } else {
                                child = Padding(
                                  padding: Insets.basic.copyWith(bottom: 0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          6,
                                          0,
                                          8,
                                          24,
                                        ),
                                        child: Text(
                                          'label_direct_chat_link_in_chat_description'
                                              .l10n,
                                          style: style
                                              .fonts.small.regular.secondary,
                                        ),
                                      ),
                                      InfoTile(
                                        padding: EdgeInsets.zero,
                                        title: '${Config.origin}/',
                                        content: c.link.text,
                                        maxLines: null,
                                        trailing: CopyOrShareButton(
                                          '${Config.origin}/${c.link.text}',
                                          onTap: () {
                                            if (c.link.text !=
                                                c.chat?.chat.value.directLink
                                                    ?.slug.val) {
                                              c.link.submit();
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              return SafeAnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: child,
                              );
                            }),
                          ],
                        ),
                      ),
                      SelectionContainer.disabled(
                        child: Block(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                          background: style.colors.background,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                8 + 8,
                                8,
                                8 + 8,
                                8 + 5,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'label_participants'.l10nfmt(
                                        {'count': c.chat!.members.length},
                                      ),
                                      style:
                                          style.fonts.big.regular.onBackground,
                                    ),
                                  ),
                                  AnimatedButton(
                                    onPressed: () => AddChatMemberView.show(
                                      context,
                                      chatId: id,
                                    ),
                                    child: const SvgIcon(SvgIcons.addMember),
                                  )
                                ],
                              ),
                            ),
                            _members(c, context),
                          ],
                        ),
                      ),
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

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);

  /// Returns a [Chat.name] editable field.
  Widget _name(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget child;

      if (c.editing.value) {
        child = _padding(
          ReactiveTextField(
            key: const Key('RenameChatField'),
            state: c.name,
            label: c.chat?.chat.value.name == null
                ? c.chat?.title.value
                : 'label_name'.l10n,
            hint: 'label_chat_name_hint'.l10n,
          ),
        );
      } else {
        child = Padding(
          key: const Key('Key'),
          padding: const EdgeInsets.only(top: 6),
          child: SizedBox(
            width: double.infinity,
            child: Center(
              child: Text(
                c.chat?.title.value ?? 'dot'.l10n * 3,
                style: style.fonts.large.regular.onBackground,
              ),
            ),
          ),
        );
      }

      return AnimatedSizeAndFade(
        sizeDuration: const Duration(milliseconds: 250),
        fadeDuration: const Duration(milliseconds: 250),
        child: child,
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

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ...members.map((e) {
            final bool inCall = c.chat?.chat.value.ongoingCall?.members
                    .any((u) => u.user.id == e.id) ==
                true;

            return MemberTile(
              user: e,
              myUser: e.id == c.me,
              inCall: c.chat?.chat.value.ongoingCall == null
                  ? null
                  : e.id == c.me
                      ? c.inCall
                      : inCall,
              onTap: () {
                if (e.dialog.value != null) {
                  router.chat(
                    e.dialog.value!.id,
                    push: true,
                  );
                } else {
                  router.user(e.id, push: true);
                }
              },
              onCall: inCall
                  ? () => c.removeChatCallMember(e.id)
                  : e.id == c.me
                      ? c.joinCall
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
          trailing: const SvgIcon(SvgIcons.cleanHistory),
        ),
        ActionButton(
          key: const Key('HideButton'),
          onPressed: () => _hideChat(c, context),
          text: 'btn_delete_chat'.l10n,
          trailing: const SvgIcon(SvgIcons.delete),
        ),
        if (!c.isMonolog)
          ActionButton(
            onPressed: () => _leaveGroup(c, context),
            text: 'btn_leave_group'.l10n,
            trailing: const SvgIcon(SvgIcons.leaveGroup),
          ),
      ],
    );
  }

  /// Returns information about the [Chat] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

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
          if (c.editing.value) ...[
            AnimatedButton(
              onPressed: c.editing.toggle,
              decorator: (child) => Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 18, 0),
                child: child,
              ),
              child: const SvgIcon(SvgIcons.closePrimary),
            ),
          ] else ...[
            AnimatedButton(
              onPressed: () => router.chat(c.chat?.id ?? id),
              child: const SvgIcon(SvgIcons.chat),
            ),
            ContextMenuRegion(
              key: c.moreKey,
              selector: c.moreKey,
              alignment: Alignment.topRight,
              enablePrimaryTap: true,
              margin: const EdgeInsets.only(
                bottom: 4,
                left: 20,
              ),
              actions: [
                ContextMenuButton(
                  label: 'btn_audio_call'.l10n,
                  onPressed: () => c.call(false),
                  trailing: const SvgIcon(SvgIcons.makeAudioCall),
                  inverted: const SvgIcon(SvgIcons.makeAudioCallWhite),
                ),
                ContextMenuButton(
                  label: 'btn_video_call'.l10n,
                  onPressed: () => c.call(true),
                  trailing: Transform.translate(
                    offset: const Offset(2, 0),
                    child: const SvgIcon(SvgIcons.makeVideoCall),
                  ),
                  inverted: Transform.translate(
                    offset: const Offset(2, 0),
                    child: const SvgIcon(SvgIcons.makeVideoCallWhite),
                  ),
                ),
                ContextMenuButton(
                  label: 'btn_edit'.l10n,
                  onPressed: c.editing.toggle,
                  trailing: const SvgIcon(SvgIcons.edit),
                  inverted: const SvgIcon(SvgIcons.editWhite),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.only(
                  left: 21 + 10,
                  right: 4 + 21,
                ),
                height: double.infinity,
                child: const SvgIcon(SvgIcons.more),
              ),
            ),
          ],
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
