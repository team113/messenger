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

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:messenger/config.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/controller.dart';
import 'package:messenger/ui/page/home/page/chat/get_paid/view.dart';
import 'package:messenger/ui/page/home/page/chat/widget/chat_subtitle.dart';
import 'package:messenger/ui/page/home/page/user/widget/contact_info.dart';
import 'package:messenger/ui/page/home/page/user/widget/copy_or_share.dart';
import 'package:messenger/ui/page/home/widget/paddings.dart';
import 'package:messenger/ui/widget/animated_size_and_fade.dart';
import 'package:messenger/ui/widget/animated_switcher.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:share_plus/share_plus.dart';

import '/domain/model/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'add_member/view.dart';
import 'controller.dart';

/// View of the [Routes.chatInfo] page.
class ChatInfoView extends StatelessWidget {
  const ChatInfoView(this.id, {super.key, this.edit = false});

  /// ID of the [Chat] of this info page.
  final ChatId id;

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
            appBar: CustomAppBar(
              // actions: [
              //   AnimatedButton(
              //     onPressed: () {},
              //     child: const SvgIcon(SvgIcons.favorite),
              //   ),
              // ],
              title: _bar(c, context),
              // padding: const EdgeInsets.only(left: 4, right: 20),
              // leading: const [StyledBackButton()],
            ),
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
                              error: c.avatar.value.errorMessage,
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
                          // padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
                          children: [_link(context, c)],
                        ),
                      ),
                      SelectionContainer.disabled(
                        child: Block(
                          padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                          background: const Color.fromARGB(255, 240, 242, 244),
                          // title: 'label_chat_members'
                          //     .l10nfmt({'count': c.chat!.members.length}),
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
            // onSuffixPressed: c.name.text.isEmpty
            //     ? null
            //     : () {
            //         PlatformUtils.copy(text: c.name.text);
            //         MessagePopup.success('label_copied'.l10n);
            //       },
            // trailing: c.name.text.isEmpty
            //     ? null
            //     : Transform.translate(
            //         offset: const Offset(0, -1),
            //         child: const SvgIcon(SvgIcons.copy),
            //       ),
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
                c.chat?.title.value ?? '...',
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

      members.sort((a, b) {
        final first = a.user.value.name?.val ?? a.user.value.num.val;
        final second = b.user.value.name?.val ?? b.user.value.num.val;
        return first.compareTo(second);
      });

      if (me != null) {
        members.insert(0, me);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // BigButton(
          //   key: const Key('AddMemberButton'),
          //   // leading: Icon(Icons.people, color: style.colors.primary),
          //   // leading: const SvgIcon(SvgIcons.addUser),

          //   title:
          //       Text('label_participants'.l10nfmt({'count': members.length})),
          //   leading: Text('btn_add'.l10n),
          //   onPressed: () => AddChatMemberView.show(context, chatId: id),
          // ),
          // const SizedBox(height: 3),
          ...members.map((e) {
            final bool inCall = c.chat?.chat.value.ongoingCall?.members
                    .any((u) => u.user.id == e.id) ==
                true;

            return MemberTile(
              user: e,
              canLeave: e.id == c.me,
              inCall: c.chat?.chat.value.ongoingCall == null
                  ? null
                  : e.id == c.me
                      ? c.inCall
                      : inCall,
              onTap: () {
                if (e.dialog.value != null) {
                  router.chat(e.dialog.value!.id, push: true);
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
          // Padding(
          //   padding:
          //       EdgeInsets.fromLTRB(0, 12, Block.defaultPadding.right + 8, 0),
          //   child: Align(
          //     alignment: Alignment.centerRight,
          //     child: AnimatedButton(
          //       onPressed: () => AddChatMemberView.show(context, chatId: id),
          //       child: Text(
          //         'Добавить участника',
          //         style: style.fonts.small.regular.primary,
          //       ),
          //     ),
          //   ),
          // ),
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
        // if (!c.isMonolog)
        //   Obx(() {
        //     final bool muted = c.chat?.chat.value.muted != null;
        //     return ActionButton(
        //       onPressed: muted ? c.unmuteChat : c.muteChat,
        //       text: muted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
        //       trailing: Transform.translate(
        //         offset: const Offset(0, -1),
        //         child: muted
        //             ? const SvgIcon(SvgIcons.muted16)
        //             : const SvgIcon(SvgIcons.unmuted16),
        //       ),
        //     );
        //   }),
        // ActionButton(
        //   key: const Key('HideChatButton'),
        //   onPressed: () => _hideChat(c, context),
        //   text: 'btn_delete_chat'.l10n,
        //   trailing: Transform.translate(
        //     offset: const Offset(0, -1),
        //     child: const SvgIcon(SvgIcons.delete),
        //   ),
        // ),

        // if (!c.isMonolog) ...[
        //   ActionButton(
        //     onPressed: () => _leaveGroup(c, context),
        //     text: 'btn_leave_group'.l10n,
        //     trailing: const SvgIcon(SvgIcons.leaveGroup16),
        //   ),
        //   ActionButton(
        //     onPressed: () => _blacklistChat(c, context),
        //     text: 'btn_block'.l10n,
        //     trailing: const SvgIcon(SvgIcons.block16),
        //   ),
        if (!c.isMonolog)
          ActionButton(
            onPressed: c.report,
            text: 'btn_report'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: const SvgIcon(SvgIcons.report16),
            ),
          ),
        ActionButton(
          key: const Key('ClearHistoryButton'),
          onPressed: () => _clearChat(c, context),
          text: 'btn_clear_history'.l10n,
          trailing: const SvgIcon(SvgIcons.cleanHistory16),
        ),
        ActionButton(
          key: const Key('HideButton'),
          onPressed: () => _hideChat(c, context),
          text: 'btn_delete_chat'.l10n,
          trailing: const SvgIcon(SvgIcons.delete),
        ),

        if (!c.isMonolog) ...[
          // ActionButton(
          //   onPressed: () => _blacklistChat(c, context),
          //   text: 'btn_block'.l10n,
          //   trailing: const SvgIcon(SvgIcons.block16),
          // ),
          ActionButton(
            onPressed: () => _leaveGroup(c, context),
            text: 'btn_leave_group'.l10n,
            trailing: const SvgIcon(SvgIcons.leaveGroup16),
          ),
        ],
        // ],
      ],
    );
  }

  Widget _link(BuildContext context, ChatInfoController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget child;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              6,
              0,
              8,
              24,
            ),
            child: Text(
              'Пользователи, пришедшие по прямой ссылке, автоматически становятся полноправными участниками группы.',
              style: style.fonts.small.regular.secondary,
            ),
          ),
          DirectLinkField(
            c.chat?.chat.value.directLink,
            onSubmit: (s) => s == null
                ? c.deleteChatDirectLink()
                : c.createChatDirectLink(s),
            background: c.background.value,
          ),
        ],
      );

      if (c.editing.value) {
        child = Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 12),
          child: DirectLinkField(
            c.chat?.chat.value.directLink,
            onSubmit: c.createChatDirectLink,
            transitions: false,
          ),
        );
      } else {
        child = DirectLinkField(
          c.chat?.chat.value.directLink,
          onSubmit: (s) =>
              s == null ? c.deleteChatDirectLink() : c.createChatDirectLink(s),
          background: c.background.value,
        );
        // child = Padding(
        //   padding: Insets.basic.copyWith(bottom: 0),
        //   child: Column(
        //     crossAxisAlignment: CrossAxisAlignment.start,
        //     children: [
        //       Padding(
        //         padding: const EdgeInsets.fromLTRB(
        //           6,
        //           0,
        //           8,
        //           24,
        //         ),
        //         child: Text(
        //           'Пользователи, пришедшие по прямой ссылке, автоматически становятся полноправными участниками группы.',
        //           style: style.fonts.small.regular.secondary,
        //         ),
        //       ),
        //       // ContactInfoContents(
        //       //   padding: EdgeInsets.zero,
        //       //   title: '${Config.origin}/',
        //       //   content: c.link.text,
        //       //   icon: const SvgIcon(SvgIcons.profileLink),
        //       //   maxLines: null,
        //       //   trailing: CopyOrShareButton(
        //       //     '${Config.origin}/${c.link.text}',
        //       //     onCopy: () {
        //       //       if (c.link.text !=
        //       //           c.chat?.chat.value.directLink?.slug.val) {
        //       //         c.link.submit();
        //       //       }
        //       //     },
        //       //   ),
        //       // ),
        //     ],
        //   ),
        // );
      }

      return SafeAnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: child,
      );
    });
  }

  Widget _bar(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    final bool contact = false;
    final bool favorite = c.chat?.chat.value.favoritePosition != null;
    final bool muted = c.chat?.chat.value.muted != null;

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
            // AnimatedButton(
            //   onPressed: () {},
            //   child: const SvgIcon(SvgIcons.edit),
            // ),
            AnimatedButton(
              onPressed: () => router.chat(c.chat?.id ?? id),
              child: const SvgIcon(SvgIcons.chat),
            ),
            // const SizedBox(width: 28),
            // AnimatedButton(
            //   onPressed: () => c.call(true),
            //   child: const SvgIcon(SvgIcons.chatVideoCall),
            // ),
            // const SizedBox(width: 28),
            // AnimatedButton(
            //   onPressed: () => c.call(false),
            //   child: const SvgIcon(SvgIcons.chatAudioCall),
            // ),
            // const SizedBox(width: 28),
            // AnimatedButton(
            //   onPressed: () {},
            //   child: const SvgIcon(SvgIcons.edit),
            // ),
            // AnimatedButton(
            //   onPressed: () => router.chat(c.chat?.id ?? id),
            //   child: const SvgIcon(SvgIcons.chat),
            // ),
            // const SizedBox(width: 28),

            // Obx(() {
            //   final bool muted = c.chat?.chat.value.muted != null;

            //   return AnimatedButton(
            //     onPressed: muted ? c.unmuteChat : c.muteChat,
            //     child: SvgIcon(muted ? SvgIcons.muted22 : SvgIcons.unmuted22),
            //   );
            // }),
            // const SizedBox(width: 28),
            // Obx(() {
            //   final bool favorite = c.chat?.chat.value.favoritePosition != null;

            //   return AnimatedButton(
            //     onPressed: favorite ? c.unfavoriteChat : c.favoriteChat,
            //     child: SvgIcon(
            //       favorite ? SvgIcons.favorite22 : SvgIcons.unfavorite22,
            //     ),
            //   );
            // }),
            // const SizedBox(width: 28),
            // AnimatedButton(
            //   decorator: (child) => Padding(
            //     padding: const EdgeInsets.only(bottom: 1, right: 16),
            //     child: child,
            //   ),
            //   onPressed: c.editing.toggle,
            //   child: const SvgIcon(SvgIcons.editGroup),
            // ),
            // AnimatedButton(
            //   onPressed: c.editing.toggle,
            //   child: const SvgIcon(SvgIcons.edit22),
            // ),
            // AnimatedButton(
            //   onPressed: c.editing.toggle,
            //   decorator: (child) => Padding(
            //     padding: const EdgeInsets.fromLTRB(0, 0, 0, 0),
            //     child: child,
            //   ),
            //   child: Text(
            //     'Редактировать',
            //     style: style.fonts.normal.regular.primary,
            //   ),
            // ),
            // const SizedBox(width: 21),
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
            if (false)
              Obx(() {
                return ContextMenuRegion(
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
                      // label: 'btn_edit'.l10n,
                      label: 'Редактировать профиль',
                      onPressed: c.editing.toggle,
                      trailing: const SvgIcon(SvgIcons.edit),
                      inverted: const SvgIcon(SvgIcons.editWhite),
                    ),

                    if (c.chat?.chat.value.isDialog == true) ...[
                      ContextMenuButton(
                        label: 'btn_set_price'.l10n,
                        onPressed: () => GetPaidView.show(
                          context,
                          mode: GetPaidMode.user,
                          user: c.chat!.members.values.firstWhere(
                            (e) => e.id != c.me,
                          ),
                        ),
                        trailing: const SvgIcon(SvgIcons.gapopaCoin),
                        inverted: const SvgIcon(SvgIcons.gapopaCoinWhite),
                      ),
                      ContextMenuButton(
                        label: contact
                            ? 'btn_delete_from_contacts'.l10n
                            : 'btn_add_to_contacts'.l10n,
                        onPressed:
                            contact ? c.removeFromContacts : c.addToContacts,
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
                      ),
                    ],
                    if (false)
                      ContextMenuButton(
                        label: favorite
                            ? 'btn_delete_from_favorites'.l10n
                            : 'btn_add_to_favorites'.l10n,
                        onPressed: favorite ? c.unfavoriteChat : c.favoriteChat,
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
                      ),
                    if (false && !c.isMonolog)
                      ContextMenuButton(
                        label: muted
                            ? PlatformUtils.isMobile
                                ? 'btn_unmute'.l10n
                                : 'btn_unmute_chat'.l10n
                            : PlatformUtils.isMobile
                                ? 'btn_mute'.l10n
                                : 'btn_mute_chat'.l10n,
                        onPressed: muted ? c.unmuteChat : c.muteChat,
                        trailing: SvgIcon(
                          muted ? SvgIcons.unmuteSmall : SvgIcons.muteSmall,
                        ),
                        inverted: SvgIcon(
                          muted
                              ? SvgIcons.unmuteSmallWhite
                              : SvgIcons.muteSmallWhite,
                        ),
                      ),
                    ContextMenuButton(
                      label: 'btn_clear_history'.l10n,
                      trailing: const SvgIcon(SvgIcons.cleanHistory),
                      inverted: const SvgIcon(SvgIcons.cleanHistoryWhite),
                      onPressed: () => _clearChat(c, context),
                    ),
                    // if (!c.isMonolog)
                    //   ContextMenuButton(
                    //     onPressed: () => _leaveGroup(c, context),
                    //     label: 'btn_leave_group'.l10n,
                    //     trailing: const SvgIcon(SvgIcons.leaveGroup),
                    //     inverted: const SvgIcon(SvgIcons.leaveGroupWhite),
                    //   ),
                    // ContextMenuButton(
                    //   label: 'btn_delete_chat'.l10n,
                    //   trailing: const SvgIcon(SvgIcons.delete19),
                    //   inverted: const SvgIcon(SvgIcons.delete19White),
                    //   onPressed: () => _hideChat(c, context),
                    // ),
                    if (!c.isMonolog) ...[
                      // ContextMenuButton(
                      //   label: 'btn_block'.l10n,
                      //   trailing: const SvgIcon(SvgIcons.block),
                      //   inverted: const SvgIcon(SvgIcons.blockWhite),
                      //   onPressed: () {},
                      // ),
                      // ContextMenuButton(
                      //   onPressed: () {},
                      //   label: 'btn_report'.l10n,
                      //   trailing: const SvgIcon(SvgIcons.report16),
                      // ),
                    ],
                  ],
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 21 + 10,
                      right: 4 + 21,
                    ),
                    height: double.infinity,
                    child: const SvgIcon(SvgIcons.more),
                  ),
                );
              }),
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
            style: style.fonts.normal.regular.onBackground),
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
            style: style.fonts.normal.regular.onBackground),
        TextSpan(text: 'alert_chat_will_be_cleared2'.l10n),
      ],
    );

    if (result == true) {
      await c.clearChat();
    }
  }

  /// Opens a confirmation popup blacklisting this [Chat].
  Future<void> _blacklistChat(
    ChatInfoController c,
    BuildContext context,
  ) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_blocked1'.l10n),
        TextSpan(
            text: c.chat?.title.value,
            style: style.fonts.normal.regular.onBackground),
        TextSpan(text: 'alert_chat_will_be_blocked2'.l10n),
      ],
    );

    if (result == true) {
      // TODO: Blacklist this [Chat].
    }
  }
}

class BigButton extends StatefulWidget {
  const BigButton({
    super.key,
    this.onPressed,
    required this.title,
    this.leading,
  });

  final Widget? leading;
  final Widget title;
  final void Function()? onPressed;

  @override
  State<BigButton> createState() => _BigButtonState();
}

class _BigButtonState extends State<BigButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return MouseRegion(
      opaque: false,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: SizedBox(
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
            // color: style.cardColor.darken(0.05),
            color: style.cardColor,
            child: InkWell(
              borderRadius: style.cardRadius,
              onTap: widget.onPressed,
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
                        style: style.fonts.normal.regular.secondary,
                        child: widget.title,
                      ),
                    ),
                    if (widget.leading != null) ...[
                      const SizedBox(width: 12),
                      DefaultTextStyle(
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: style.fonts.normal.regular.onBackground.copyWith(
                          color: style.colors.primary,
                        ),
                        child: widget.leading!,
                      ),
                      // AnimatedScale(
                      //   duration: const Duration(milliseconds: 100),
                      //   scale: _hovered ? 1.05 : 1,
                      //   child: widget.leading!,
                      // ),
                      const SizedBox(width: 4),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
