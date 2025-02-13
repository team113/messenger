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
import 'package:collection/collection.dart';
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
import '/ui/widget/animated_button.dart';
import '/ui/widget/member_tile.dart';
import '/ui/widget/primary_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
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
            if (c.isMonolog) ...[
              _avatar(c, context),
              const NotesBlock.info(),
            ] else ...[
              _profile(c, context),
              SelectionContainer.disabled(child: _members(c, context)),
              SelectionContainer.disabled(child: _link(c, context)),
              SelectionContainer.disabled(
                child: Block(children: [_actions(c, context)]),
              ),
            ],
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
                  itemBuilder:
                      (_, i) => Obx(() {
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

  /// Builds the profile [Block] with editing functionality.
  Widget _profile(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Obx(() {
      final Widget name;

      if (c.profileEditing.value) {
        name = Column(
          key: const Key('Name'),
          children: [
            const SizedBox(height: 8),
            ReactiveTextField(
              key: const Key('RenameChatField'),
              state: c.name,
              label: 'label_name'.l10n,
              hint: c.chat?.title,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              formatters: [LengthLimitingTextInputFormatter(100)],
            ),
          ],
        );
      } else {
        name = SizedBox(
          width: double.infinity,
          child: Center(
            child: Text(
              '${c.chat?.title}',
              style: style.fonts.larger.regular.onBackground,
            ),
          ),
        );
      }

      final Widget button;

      if (c.profileEditing.value) {
        button = Column(
          key: const Key('Button'),
          children: [
            const SizedBox(height: 8),
            Stack(
              children: [
                PrimaryButton(
                  key: Key('SaveEditingButton'),
                  title: 'btn_save'.l10n,
                  onPressed: () {
                    c.profileEditing.toggle();
                    c.submitName();
                    c.submitAvatar();
                  },
                  style: style.fonts.normal.regular.onPrimary,
                ),
                const Positioned(
                  left: 16,
                  top: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    child: SvgIcon(SvgIcons.sentWhite, height: 13, width: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        );
      } else {
        button = SizedBox(width: double.infinity);
      }

      return Block(
        overlay: [
          Positioned(
            top: 16,
            right: 0,
            child: WidgetButton(
              onPressed:
                  c.profileEditing.value
                      ? c.closeEditing
                      : c.profileEditing.toggle,
              child: SizedBox(
                width: 16,
                height: 16,
                child: Center(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child:
                        c.profileEditing.value
                            ? SvgIcon(
                              key: Key('CloseEditingButton'),
                              SvgIcons.closePrimary,
                              width: 12,
                              height: 12,
                            )
                            : SvgIcon(
                              key: Key('EditProfileButton'),
                              SvgIcons.edit,
                            ),
                  ),
                ),
              ),
            ),
          ),
        ],
        children: [
          const SizedBox(height: 8),
          AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: name,
          ),
          const SizedBox(height: 16),
          SelectionContainer.disabled(
            child: BigAvatarWidget.chat(
              c.chat,
              key: Key('ChatAvatar_${c.chat!.id}'),
              loading: c.avatarUpload.value.isLoading,
              error: c.avatarUpload.value.errorMessage,
              onUpload:
                  c.profileEditing.value
                      ? c.canEdit
                          ? c.pickAvatar
                          : null
                      : null,
              onEdit:
                  c.profileEditing.value
                      ? c.canEdit && c.chat?.avatar.value != null
                          ? c.editAvatar
                          : null
                      : null,
              onDelete:
                  c.profileEditing.value
                      ? c.canEdit && c.chat?.avatar.value != null
                          ? c.deleteAvatar
                          : null
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
                  title: c.chat?.title,
                  color: c.chat?.chat.value.colorDiscriminant(c.me).sum(),
                  avatar:
                      c.avatarDeleted.value || c.avatarImage.value == null
                          ? null
                          : LocalAvatar(
                            file: c.avatarImage.value!,
                            crop:
                                c.avatarCrop.value == null
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
          AnimatedSizeAndFade(
            fadeDuration: const Duration(milliseconds: 250),
            sizeDuration: const Duration(milliseconds: 250),
            child: button,
          ),
        ],
      );
    });
  }

  /// Returns the [Block] displaying a [Chat.avatar].
  Widget _avatar(ChatInfoController c, BuildContext context) {
    return Obx(() {
      final Avatar? avatar = c.chat?.avatar.value;

      return Block(
        children: [
          SelectionContainer.disabled(
            child: BigAvatarWidget.chat(
              c.chat,
              key: Key('ChatAvatar_${c.chat!.id}'),
              loading: c.avatarUpload.value.isLoading,
              error: c.avatarUpload.value.errorMessage,
              onUpload: c.pickAvatar,
              onEdit: avatar != null ? c.editAvatar : null,
              onDelete: c.chat?.avatar.value != null ? c.deleteAvatar : null,
            ),
          ),
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
                key: Key('DirectLinkField'),
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
        }),
      ],
    );
  }

  /// Returns the [Block] displaying the [Chat.members].
  Widget _members(ChatInfoController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Block(
      padding: Block.defaultPadding.copyWith(right: 0, left: 0),
      title: 'label_participants'.l10nfmt({
        'count': c.chat!.chat.value.membersCount,
      }),
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
                          onCall:
                              inCall
                                  ? () {
                                    if (myUser != null) {
                                      c.removeChatCallMember(myUser.id);
                                    }
                                  }
                                  : c.joinCall,
                        );
                      } else {
                        final RxUser member = members[i];

                        final bool inCall =
                            c.chat?.chat.value.ongoingCall?.members.any(
                              (u) => u.user.id == member.id,
                            ) ==
                            true;

                        child = MemberTile(
                          user: member,
                          inCall: hasCall ? inCall : null,
                          onTap:
                              () => router.chat(
                                ChatId.local(member.user.value.id),
                                push: true,
                              ),
                          onCall:
                              inCall
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ActionButton(
          onPressed: () => _reportChat(c, context),
          text: 'btn_report'.l10n,
          trailing: const SvgIcon(SvgIcons.report),
        ),
        ActionButton(
          onPressed: () => _leaveGroup(c, context),
          text: 'btn_leave_group'.l10n,
          danger: true,
          trailing: const SvgIcon(SvgIcons.leaveGroupRed),
        ),
      ],
    );
  }

  /// Returns information about the [Chat] and related to it action buttons in
  /// the [CustomAppBar].
  Widget _bar(ChatInfoController c, BuildContext context) {
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
            onPressed:
                c.reporting.isEmpty.value
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
