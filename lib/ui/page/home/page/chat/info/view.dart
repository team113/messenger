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

import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/controller.dart';
import '/ui/page/home/page/chat/info/add_member/controller.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/block.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/gallery_popup.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the [Routes.chatInfo] page.
class ChatInfoView extends StatelessWidget {
  const ChatInfoView(this.id, {Key? key}) : super(key: key);

  /// ID of the [Chat] of this info page.
  final ChatId id;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder<ChatInfoController>(
      key: const Key('ChatInfoView'),
      init: ChatInfoController(id, Get.find(), Get.find(), Get.find()),
      tag: id.val,
      global: false,
      dispose: (state) => state.controller?.onClose(),
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
              title: Row(
                children: [
                  Material(
                    elevation: 6,
                    type: MaterialType.circle,
                    shadowColor: style.colors.onBackgroundOpacity27,
                    color: style.colors.onPrimary,
                    child: Center(
                      child: AvatarWidget.fromRxChat(c.chat, radius: 17),
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
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  c.chat!.title.value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              if (c.chat?.chat.value.muted != null) ...[
                                const SizedBox(width: 5),
                                SvgImage.asset(
                                  'assets/icons/muted.svg',
                                  width: 19.99 * 0.6,
                                  height: 15 * 0.6,
                                ),
                              ]
                            ],
                          ),
                          _chatSubtitle(c, context),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
              ),
              padding: const EdgeInsets.only(left: 4, right: 20),
              leading: const [StyledBackButton()],
              actions: [
                WidgetButton(
                  onPressed: () => router.chat(id, push: true),
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: SvgImage.asset(
                      'assets/icons/chat.svg',
                      width: 20.12,
                      height: 21.62,
                    ),
                  ),
                ),
                if (c.chat!.chat.value.ongoingCall == null) ...[
                  if (!context.isMobile) ...[
                    const SizedBox(width: 28),
                    WidgetButton(
                      onPressed: () => c.call(true),
                      child: SvgImage.asset(
                        'assets/icons/chat_video_call.svg',
                        height: 17,
                      ),
                    ),
                  ],
                  const SizedBox(width: 28),
                  WidgetButton(
                    onPressed: () => c.call(false),
                    child: SvgImage.asset(
                      'assets/icons/chat_audio_call.svg',
                      height: 19,
                    ),
                  ),
                ] else ...[
                  const SizedBox(width: 14),
                  AnimatedSwitcher(
                    key: const Key('ActiveCallButton'),
                    duration: 300.milliseconds,
                    child: c.inCall
                        ? WidgetButton(
                            key: const Key('Drop'),
                            onPressed: c.dropCall,
                            child: Container(
                              height: 22,
                              width: 22,
                              decoration: BoxDecoration(
                                color: style.colors.dangerColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgImage.asset(
                                  'assets/icons/call_end.svg',
                                  width: 22,
                                  height: 22,
                                ),
                              ),
                            ),
                          )
                        : WidgetButton(
                            key: const Key('Join'),
                            onPressed: c.joinCall,
                            child: Container(
                              height: 22,
                              width: 22,
                              decoration: BoxDecoration(
                                color: style.colors.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: SvgImage.asset(
                                  'assets/icons/audio_call_start.svg',
                                  width: 10,
                                  height: 10,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ],
            ),
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
                      _avatar(c, context),
                      const SizedBox(height: 15),
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
                      children: [_link(c, context)],
                    ),
                  ],
                  Block(
                    title: 'label_actions'.l10n,
                    children: [_actions(c, context)],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  /// Returns a subtitle to display under the [Chat]'s title.
  Widget _chatSubtitle(ChatInfoController c, BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;

    return Obx(() {
      final Rx<Chat> chat = c.chat!.chat;

      if (chat.value.isGroup) {
        final String? subtitle = chat.value.getSubtitle();
        if (subtitle != null) {
          return Text(subtitle, style: style);
        }
      }

      return Container();
    });
  }

  /// Basic [Padding] wrapper.
  Widget _padding(Widget child) =>
      Padding(padding: const EdgeInsets.all(8), child: child);

  /// Returns a [Chat.avatar] visual representation along with its manipulation
  /// buttons.
  Widget _avatar(ChatInfoController c, BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WidgetButton(
              key: Key('ChatAvatar_${c.chat!.id}'),
              onPressed: c.chat?.chat.value.avatar == null
                  ? c.pickAvatar
                  : () async {
                      await GalleryPopup.show(
                        context: context,
                        gallery: GalleryPopup(
                          initialKey: c.avatarKey,
                          children: [
                            GalleryItem.image(
                              c.chat!.chat.value.avatar!.original.url,
                              c.chat!.chat.value.id.val,
                            ),
                          ],
                        ),
                      );
                    },
              child: AvatarWidget.fromRxChat(
                c.chat,
                key: c.avatarKey,
                radius: 100,
              ),
            ),
            Positioned.fill(
              child: Obx(() {
                return AnimatedSwitcher(
                  duration: 200.milliseconds,
                  child: c.avatar.value.isLoading
                      ? Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: style.colors.onBackgroundOpacity13,
                          ),
                          child: const Center(child: CustomProgressIndicator()),
                        )
                      : const SizedBox.shrink(),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WidgetButton(
              key: const Key('UploadAvatar'),
              onPressed: c.pickAvatar,
              child: Text(
                'btn_upload'.l10n,
                style: TextStyle(color: style.colors.primary, fontSize: 11),
              ),
            ),
            if (c.chat?.chat.value.avatar != null) ...[
              Text(
                'space_or_space'.l10n,
                style:
                    TextStyle(color: style.colors.onBackground, fontSize: 11),
              ),
              WidgetButton(
                key: const Key('DeleteAvatar'),
                onPressed: c.deleteAvatar,
                child: Text(
                  'btn_delete'.l10n.toLowerCase(),
                  style: TextStyle(color: style.colors.primary, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

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
          hint: 'label_name_hint'.l10n,
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
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgImage.asset('assets/icons/copy.svg', height: 15),
                  ),
                ),
        ),
      );
    });
  }

  /// Returns a [Chat.directLink] editable field.
  Widget _link(ChatInfoController c, BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReactiveTextField(
            key: const Key('LinkField'),
            state: c.link,
            onSuffixPressed: c.link.isEmpty.value
                ? null
                : () {
                    PlatformUtils.copy(
                      text:
                          '${Config.origin}${Routes.chatDirectLink}/${c.link.text}',
                    );

                    MessagePopup.success('label_copied'.l10n);
                  },
            trailing: c.link.isEmpty.value
                ? null
                : Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child:
                          SvgImage.asset('assets/icons/copy.svg', height: 15),
                    ),
                  ),
            label: '${Config.origin}/',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 6, 24, 6),
            child: Row(
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                    children: [
                      TextSpan(
                        text: 'label_transition_count'.l10nfmt({
                              'count':
                                  c.chat?.chat.value.directLink?.usageCount ?? 0
                            }) +
                            'dot_space'.l10n,
                        style: TextStyle(color: style.colors.secondary),
                      ),
                      TextSpan(
                        text: 'label_details'.l10n,
                        style: TextStyle(
                          color: style.colors.primary,
                        ),
                        recognizer: TapGestureRecognizer()..onTap = () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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

      final Style style = Theme.of(context).extension<Style>()!;

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
                          style: TextStyle(
                            fontSize: 15,
                            color: style.colors.primary,
                            fontWeight: FontWeight.w300,
                          ),
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
            leading: Icon(Icons.people, color: style.colors.primary),
            title: Text('btn_add_member'.l10n),
            onTap: () => AddChatMemberView.show(context, chatId: id),
          ),
          const SizedBox(height: 3),
          ...members.map((e) {
            final bool inCall = c.chat?.chat.value.ongoingCall?.members
                    .any((u) => u.user.id == e.id) ==
                true;

            return ContactTile(
              user: e,
              darken: 0.05,
              dense: true,
              onTap: () => router.user(e.id, push: true),
              trailing: [
                if (e.id != c.me && c.chat?.chat.value.ongoingCall != null) ...[
                  if (inCall)
                    WidgetButton(
                      key: const Key('Drop'),
                      onPressed: () => c.removeChatCallMember(e.id),
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: BoxDecoration(
                          color: style.colors.dangerColor,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: SvgImage.asset(
                            'assets/icons/call_end.svg',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                    )
                  else
                    Material(
                      color: style.colors.primary,
                      type: MaterialType.circle,
                      child: InkWell(
                        onTap: () => c.redialChatCallMember(e.id),
                        borderRadius: BorderRadius.circular(60),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Center(
                            child: SvgImage.asset(
                              'assets/icons/audio_call_start.svg',
                              width: 10,
                              height: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 12),
                ],
                if (e.id == c.me)
                  WidgetButton(
                    onPressed: () => _removeChatMember(c, context, e),
                    child: Text(
                      'btn_leave'.l10n,
                      style:
                          TextStyle(color: style.colors.primary, fontSize: 15),
                    ),
                  )
                else
                  WidgetButton(
                    key: const Key('DeleteMemberButton'),
                    onPressed: () => _removeChatMember(c, context, e),
                    child: SvgImage.asset(
                      'assets/icons/delete.svg',
                      height: 14 * 1.5,
                    ),
                  ),
                const SizedBox(width: 6),
              ],
            );
          }),
        ],
      );
    });
  }

  /// Dense [Padding] wrapper.
  Widget _dense(Widget child) =>
      Padding(padding: const EdgeInsets.fromLTRB(8, 4, 8, 4), child: child);

  /// Returns the action buttons to do with this [Chat].
  Widget _actions(ChatInfoController c, BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!c.isMonolog) ...[
          _dense(
            FieldButton(
              onPressed: () {},
              text: 'btn_add_to_contacts'.l10n,
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              style: TextStyle(color: style.colors.primary),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!c.isLocal) ...[
          _dense(
            Obx(() {
              final bool favorited =
                  c.chat?.chat.value.favoritePosition != null;

              return FieldButton(
                key: Key(
                  favorited ? 'UnfavoriteChatButton' : 'FavoriteChatButton',
                ),
                onPressed: favorited ? c.unfavoriteChat : c.favoriteChat,
                text: favorited
                    ? 'btn_delete_from_favorites'.l10n
                    : 'btn_add_to_favorites'.l10n,
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child:
                        SvgImage.asset('assets/icons/delete.svg', height: 14),
                  ),
                ),
                style: TextStyle(color: style.colors.primary),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (!c.isMonolog) ...[
          _dense(
            Obx(() {
              final bool muted = c.chat?.chat.value.muted != null;

              return FieldButton(
                onPressed: muted ? c.unmuteChat : c.muteChat,
                text: muted ? 'btn_unmute_chat'.l10n : 'btn_mute_chat'.l10n,
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: muted
                        ? SvgImage.asset(
                            'assets/icons/btn_mute.svg',
                            width: 18.68,
                            height: 15,
                          )
                        : SvgImage.asset(
                            'assets/icons/btn_unmute.svg',
                            width: 17.86,
                            height: 15,
                          ),
                  ),
                ),
                style: TextStyle(color: style.colors.primary),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
        _dense(
          FieldButton(
            key: const Key('HideChatButton'),
            onPressed: () => _hideChat(c, context),
            text: 'btn_hide_chat'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            style: TextStyle(color: style.colors.primary),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          FieldButton(
            key: const Key('ClearHistoryButton'),
            onPressed: () => _clearChat(c, context),
            text: 'btn_clear_history'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            style: TextStyle(color: style.colors.primary),
          ),
        ),
        if (!c.isMonolog) ...[
          const SizedBox(height: 10),
          _dense(
            FieldButton(
              onPressed: () => _leaveGroup(c, context),
              text: 'btn_leave_group'.l10n,
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              style: TextStyle(color: style.colors.primary),
            ),
          ),
          const SizedBox(height: 10),
          _dense(
            FieldButton(
              onPressed: () => _blacklistChat(c, context),
              text: 'btn_block'.l10n,
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              style: TextStyle(color: style.colors.primary),
            ),
          ),
          const SizedBox(height: 10),
          _dense(
            FieldButton(
              onPressed: () {},
              text: 'btn_report'.l10n,
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              style: TextStyle(color: style.colors.primary),
            ),
          ),
        ],
      ],
    );
  }

  /// Opens a confirmation popup removing the provided [user].
  Future<void> _removeChatMember(
    ChatInfoController c,
    BuildContext context,
    RxUser user,
  ) async {
    final Style style = Theme.of(context).extension<Style>()!;

    if (c.me == user.id) {
      await _leaveGroup(c, context);
    } else {
      final bool? result = await MessagePopup.alert(
        'label_remove_member'.l10n,
        description: [
          TextSpan(text: 'alert_user_will_be_removed1'.l10n),
          TextSpan(
            text: user.user.value.name?.val ?? user.user.value.num.val,
            style: TextStyle(color: style.colors.onBackground),
          ),
          TextSpan(text: 'alert_user_will_be_removed2'.l10n),
        ],
      );

      if (result == true) {
        await c.removeChatMember(user.id);
      }
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

  /// Opens a confirmation popup hiding this [Chat].
  Future<void> _hideChat(ChatInfoController c, BuildContext context) async {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_hide_chat'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_hidden1'.l10n),
        TextSpan(
          text: c.chat?.title.value,
          style: TextStyle(color: style.colors.onBackground),
        ),
        TextSpan(text: 'alert_chat_will_be_hidden2'.l10n),
      ],
    );

    if (result == true) {
      await c.hideChat();
    }
  }

  /// Opens a confirmation popup clearing this [Chat].
  Future<void> _clearChat(ChatInfoController c, BuildContext context) async {
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_cleared1'.l10n),
        TextSpan(
          text: c.chat?.title.value,
          style: TextStyle(color: style.colors.onBackground),
        ),
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
    final Style style = Theme.of(context).extension<Style>()!;

    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_blocked1'.l10n),
        TextSpan(
          text: c.chat?.title.value,
          style: TextStyle(color: style.colors.onBackground),
        ),
        TextSpan(text: 'alert_chat_will_be_blocked2'.l10n),
      ],
    );

    if (result == true) {
      // TODO: Blacklist this [Chat].
    }
  }
}
