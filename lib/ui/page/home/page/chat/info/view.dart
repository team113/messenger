// Copyright © 2022-2026 IT ENGINEERING MANAGEMENT INC,
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
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '/config.dart';
import '/domain/model/avatar.dart';
import '/domain/model/chat.dart';
import '/domain/model/crop_area.dart';
import '/domain/model/my_user.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat//controller.dart';
import '/ui/page/home/page/chat/info/add_member/controller.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/chat/widget/notes_block.dart';
import '/ui/page/home/widget/action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/big_avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/direct_link.dart';
import '/ui/page/home/widget/highlighted_container.dart';
import '/ui/page/home/widget/scroll_keyboard_handler.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/obscured_selection_area.dart';
import '/ui/widget/primary_button.dart';
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
              appBar: CustomAppBar(title: _bar(c, context)),
              body: const Center(child: CustomProgressIndicator()),
            );
          } else if (!c.status.value.isSuccess) {
            return Scaffold(
              appBar: CustomAppBar(title: _bar(c, context)),
              body: Center(child: Text('label_no_chat_found'.l10n)),
            );
          }

          final List<Widget> blocks = [
            const SizedBox(height: 8),
            if (c.isMonolog)
              NotesBlock(
                leading: SelectionContainer.disabled(
                  child: BigAvatarWidget.chat(c.chat),
                ),
              )
            else
              _profile(c, context),

            if (!c.isMonolog) ...[
              SelectionContainer.disabled(child: _members(c, context)),
              SelectionContainer.disabled(child: _link(c, context)),
            ],

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
            ),
          );
        });
      },
    );
  }

  /// Builds the profile [Block] with editing functionality.
  Widget _profile(ChatInfoController c, BuildContext context) {
    return Obx(() {
      return Block(
        folded: c.isFavorite,
        children: [
          SelectionContainer.disabled(
            child: BigAvatarWidget.chat(
              c.chat,
              key: Key('ChatAvatar_${c.chat!.id}'),
              loading: c.avatarUpload.value.isLoading,
              error: c.avatarUpload.value.errorMessage,
              onUpload: c.canEdit ? c.pickAvatar : null,
              onEdit: c.canEdit && c.chat?.avatar.value != null
                  ? c.editAvatar
                  : null,
              onDelete: c.canEdit && c.chat?.avatar.value != null
                  ? c.deleteAvatar
                  : null,
              builder: (child) {
                if (c.avatarCrop.value == null &&
                    c.avatarImage.value == null &&
                    c.avatarDeleted.value == false) {
                  return child;
                }

                return AvatarWidget(
                  radius: AvatarRadius.largest,
                  shape: BoxShape.rectangle,
                  title: c.chat?.title(withDeletedLabel: false),
                  color: c.chat?.chat.value.colorDiscriminant(c.me).sum(),
                  avatar: c.avatarDeleted.value || c.avatarImage.value == null
                      ? null
                      : LocalAvatar(
                          file: c.avatarImage.value!,
                          crop: c.avatarCrop.value == null
                              ? null
                              : CropArea(
                                  topLeft: CropPoint(
                                    x: c.avatarCrop.value!.topLeft.x,
                                    y: c.avatarCrop.value!.topLeft.y,
                                  ),
                                  bottomRight: CropPoint(
                                    x: c.avatarCrop.value!.bottomRight.x,
                                    y: c.avatarCrop.value!.bottomRight.y,
                                  ),
                                  angle: c.avatarCrop.value!.angle,
                                ),
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          ReactiveTextField(
            key: const Key('RenameChatField'),
            state: c.name,
            label: 'label_name'.l10n,
            hint: c.chat?.title(),
            floatingLabelBehavior: FloatingLabelBehavior.always,
            formatters: [LengthLimitingTextInputFormatter(100)],
          ),
          const SizedBox(height: 8),
        ],
      );
    });
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 0, 8, 0),
                child: Text(
                  'label_direct_chat_link_in_chat_description'.l10n,
                  style: style.fonts.small.regular.secondary,
                ),
              ),
              DirectLinkField(
                c.chat?.chat.value.directLink,
                key: Key('DirectLinkField'),
                onSubmit: (s) async {
                  if (s == null) {
                    await c.deleteChatDirectLink();
                  } else {
                    await c.createChatDirectLink(s);
                  }
                },
                background: c.background.value,
              ),
            ],
          );
        }),
      ],
    );
  }

  /// Returns the [Block] displaying the [Chat.members].
  Widget _members(ChatInfoController c, BuildContext context) {
    return Block(
      padding: Block.defaultPadding.copyWith(right: 0, left: 0),
      title: 'label_participants'.l10nfmt({
        'count': c.chat!.chat.value.membersCount,
      }),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: PrimaryButton(
            key: const Key('AddMemberButton'),
            onPressed: () => AddChatMemberView.show(context, chatId: id),
            leading: SvgIcon(SvgIcons.addUserWhite),
            title: 'btn_add_participants'.l10n,
          ),
        ),
        const SizedBox(height: 8),
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
                          onKick: () => _leaveGroup(c, context),
                        );
                      } else {
                        final RxUser member = members[i];

                        final bool meInCall = c.chat?.inCall.value == true;
                        final bool inCall =
                            c.chat?.chat.value.ongoingCall?.members.any(
                              (u) => u.user.id == member.id,
                            ) ==
                            true;

                        child = MemberTile(
                          user: member,
                          inCall: hasCall ? inCall : null,
                          onTap: () => router.chat(
                            ChatId.local(member.user.value.id),
                            mode: RouteAs.push,
                          ),
                          onCall: meInCall
                              ? inCall
                                    ? () => c.removeChatCallMember(member.id)
                                    : () => c.redialChatCallMember(member.id)
                              : null,
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
                              value: Config.disableInfiniteAnimations
                                  ? 0
                                  : null,
                            ),
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
        const SizedBox(height: 4),
      ],
    );
  }

  /// Returns the action buttons to do with this [Chat].
  Widget _actions(ChatInfoController c, BuildContext context) {
    final bool favorite = c.chat?.chat.value.favoritePosition != null;
    final bool muted = c.chat?.chat.value.muted != null;
    final bool isLocal = c.chat?.chat.value.id.isLocal == true;
    final bool monolog = c.chat?.chat.value.isMonolog == true;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          key: favorite
              ? const Key('UnfavoriteButton')
              : const Key('FavoriteButton'),
          onPressed: favorite ? c.unfavoriteChat : c.favoriteChat,
          text: favorite
              ? 'btn_delete_from_favorites'.l10n
              : 'btn_add_to_favorites'.l10n,
          trailing: SvgIcon(
            favorite ? SvgIcons.favoriteSmall : SvgIcons.unfavoriteSmall,
          ),
        ),

        if (!isLocal) ...[
          ActionButton(
            key: muted ? const Key('UnmuteButton') : const Key('MuteButton'),
            onPressed: muted ? c.unmuteChat : c.muteChat,
            text: muted
                ? PlatformUtils.isMobile
                      ? 'btn_unmute'.l10n
                      : 'btn_unmute_chat'.l10n
                : PlatformUtils.isMobile
                ? 'btn_mute'.l10n
                : 'btn_mute_chat'.l10n,
            trailing: SvgIcon(
              muted ? SvgIcons.muteSmall : SvgIcons.unmuteSmall,
            ),
          ),
          ActionButton(
            key: const Key('ClearChatButton'),
            onPressed: () => _clearChat(c, context),
            text: 'btn_clear_chat'.l10n,
            trailing: const SvgIcon(SvgIcons.cleanHistory),
          ),
        ],
        if (!isLocal || monolog)
          ActionButton(
            key: const Key('DeleteChatButton'),
            onPressed: () => _hideChat(c, context),
            text: 'btn_delete_chat'.l10n,
            trailing: const SvgIcon(SvgIcons.delete19),
          ),
        if (!monolog) ...[
          ActionButton(
            key: const Key('ReportChatButton'),
            onPressed: () => _reportChat(c, context),
            text: 'btn_report'.l10n,
            trailing: const SvgIcon(SvgIcons.report),
          ),
          ActionButton(
            key: const Key('LeaveChatButton'),
            onPressed: () => _leaveGroup(c, context),
            text: 'btn_leave_group'.l10n,
            danger: true,
            trailing: const SvgIcon(SvgIcons.leaveGroupRed),
          ),
        ],
      ],
    );
  }

  /// Returns information about the [Chat] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(ChatInfoController c, BuildContext context) {
    final bool isMonolog = c.chat?.chat.value.isMonolog == true;

    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: const StyledBackButton(withLabel: true),
          ),
        ),
        const SizedBox(width: 8),
        AnimatedButton(
          onPressed: () => router.dialog(c.chat!.chat.value, c.me),
          child: const SvgIcon(SvgIcons.chat),
        ),
        if (!isMonolog) ...[
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
        ],
        const SizedBox(width: 20),
      ],
    );
  }

  /// Opens a confirmation popup clearing this [Chat].
  Future<void> _clearChat(ChatInfoController c, BuildContext context) async {
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
  Future<void> _hideChat(ChatInfoController c, BuildContext context) async {
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

  /// Opens a confirmation popup reporting this [Chat].
  Future<void> _reportChat(ChatInfoController c, BuildContext context) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_report'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_reported1'.l10n),
        TextSpan(
          text: c.chat?.title(),
          style: style.fonts.normal.regular.onBackground,
        ),
        TextSpan(text: 'alert_chat_will_be_reported2'.l10n),
      ],
      additional: [
        const SizedBox(height: 25),
        ReactiveTextField(
          key: const Key('ReportField'),
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
            key: enabled ? const Key('SendReportButton') : null,
            title: 'btn_proceed'.l10n,
            onPressed: enabled ? () => Navigator.of(context).pop(true) : null,
            leading: SvgIcon(
              enabled ? SvgIcons.reportWhite : SvgIcons.reportGrey,
            ),
          );
        });
      },
    );

    if (result == true) {
      await c.reportChat();
    }
  }
}
