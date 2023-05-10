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
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/config.dart';
import '/domain/model/chat.dart';
import '/domain/model/user.dart';
import '/domain/repository/chat.dart';
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
    return GetBuilder<ChatInfoController>(
      key: const Key('ChatInfoView'),
      init: ChatInfoController(id, Get.find(), Get.find(), Get.find()),
      tag: id.val,
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
                    shadowColor: const Color(0x55000000),
                    color: Colors.white,
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
                          ChatSubtitle(c.chat),
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
                              decoration: const BoxDecoration(
                                color: Colors.red,
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
                                color: Theme.of(context).colorScheme.secondary,
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
                      ChatAvatar(
                        c.chat,
                        avatarKey: c.avatarKey,
                        avatar: c.avatar,
                        pickAvatar: c.pickAvatar,
                        deleteAvatar: c.deleteAvatar,
                      ),
                      const SizedBox(height: 15),
                      ChatName(c.chat, c.name),
                    ],
                  ),
                  if (!c.isMonolog) ...[
                    Block(
                      title: 'label_chat_members'.l10n,
                      children: [
                        ChatMembers(
                          id,
                          chat: c.chat,
                          me: c.me,
                          redialChatCallMember: c.redialChatCallMember,
                          removeChatCallMember: c.removeChatCallMember,
                          removeChatMember: _removeChatMember,
                        )
                      ],
                    ),
                    Block(
                      title: 'label_direct_chat_link'.l10n,
                      children: [ChatLink(c.chat, c.link)],
                    ),
                  ],
                  Block(
                    title: 'label_actions'.l10n,
                    children: [
                      ChatActions(
                        c.chat,
                        isMonolog: c.isMonolog,
                        isLocal: c.isLocal,
                        unfavoriteChat: c.unfavoriteChat,
                        favoriteChat: c.favoriteChat,
                        unmuteChat: c.unmuteChat,
                        muteChat: c.muteChat,
                        hideChat: _hideChat,
                        clearChat: _clearChat,
                        leaveGroup: _leaveGroup,
                        blacklistChat: _blacklistChat,
                      )
                    ],
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

  /// Opens a confirmation popup removing the provided [user].
  Future<void> _removeChatMember(
    ChatInfoController c,
    BuildContext context,
    RxUser user,
  ) async {
    if (c.me == user.id) {
      await _leaveGroup(c, context);
    } else {
      final bool? result = await MessagePopup.alert(
        'label_remove_member'.l10n,
        description: [
          TextSpan(text: 'alert_user_will_be_removed1'.l10n),
          TextSpan(
            text: user.user.value.name?.val ?? user.user.value.num.val,
            style: const TextStyle(color: Colors.black),
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
    final bool? result = await MessagePopup.alert(
      'label_hide_chat'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_hidden1'.l10n),
        TextSpan(
          text: c.chat?.title.value,
          style: const TextStyle(color: Colors.black),
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
    final bool? result = await MessagePopup.alert(
      'label_clear_history'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_cleared1'.l10n),
        TextSpan(
          text: c.chat?.title.value,
          style: const TextStyle(color: Colors.black),
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
    final bool? result = await MessagePopup.alert(
      'label_block'.l10n,
      description: [
        TextSpan(text: 'alert_chat_will_be_blocked1'.l10n),
        TextSpan(
          text: c.chat?.title.value,
          style: const TextStyle(color: Colors.black),
        ),
        TextSpan(text: 'alert_chat_will_be_blocked2'.l10n),
      ],
    );

    if (result == true) {
      // TODO: Blacklist this [Chat].
    }
  }
}

/// Basic [Padding] wrapper.
class _PaddingWidget extends StatelessWidget {
  const _PaddingWidget(this.child);

  /// [Widget] that will be wrapped with padding.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(padding: const EdgeInsets.all(8), child: child);
  }
}

/// Dense [Padding] wrapper.
class _DenseWidget extends StatelessWidget {
  const _DenseWidget(this.child);

  /// [Widget] that will be wrapped in padding.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
      child: child,
    );
  }
}

/// [Widget] which returns a subtitle to display under the [Chat]'s title.
class ChatSubtitle extends StatelessWidget {
  const ChatSubtitle(this.chat, {super.key});

  /// Unified reactive [Chat] with chat items.
  final RxChat? chat;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.bodySmall;

    return Obx(() {
      if (chat!.chat.value.isGroup) {
        final String? subtitle = chat!.chat.value.getSubtitle();
        if (subtitle != null) {
          return Text(subtitle, style: style);
        }
      }

      return const SizedBox();
    });
  }
}

/// [Widget] which returns a [Chat.avatar] visual representation along with its
/// manipulation buttons.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar(
    this.chat, {
    super.key,
    required this.avatar,
    this.avatarKey,
    this.pickAvatar,
    this.deleteAvatar,
  });

  /// Unified reactive [Chat] with chat items.
  final RxChat? chat;

  /// [GlobalKey] used to uniquely identify the [State] of the avatar widget.
  final GlobalKey<State<StatefulWidget>>? avatarKey;

  /// Reactive status object related to the avatar.
  final Rx<RxStatus> avatar;

  /// [Function] that allows the user to select and pick an avatar image.
  final Future<void> Function()? pickAvatar;

  /// [Function] that allows the user to delete the avatar image.
  final Future<void> Function()? deleteAvatar;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WidgetButton(
              key: Key('ChatAvatar_${chat!.id}'),
              onPressed: chat?.chat.value.avatar == null
                  ? pickAvatar
                  : () async {
                      await GalleryPopup.show(
                        context: context,
                        gallery: GalleryPopup(
                          initialKey: avatarKey,
                          children: [
                            GalleryItem.image(
                              chat!.chat.value.avatar!.original.url,
                              chat!.chat.value.id.val,
                            ),
                          ],
                        ),
                      );
                    },
              child: AvatarWidget.fromRxChat(
                chat,
                key: avatarKey,
                radius: 100,
              ),
            ),
            Positioned.fill(
              child: Obx(() {
                return AnimatedSwitcher(
                  duration: 200.milliseconds,
                  child: avatar.value.isLoading
                      ? Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x22000000),
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
              onPressed: pickAvatar,
              child: Text(
                'btn_upload'.l10n,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontSize: 11,
                ),
              ),
            ),
            if (chat?.chat.value.avatar != null) ...[
              Text(
                'space_or_space'.l10n,
                style: const TextStyle(color: Colors.black, fontSize: 11),
              ),
              WidgetButton(
                key: const Key('DeleteAvatar'),
                onPressed: deleteAvatar,
                child: Text(
                  'btn_delete'.l10n.toLowerCase(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// [Widget] which returns a [Chat.name] editable field.
class ChatName extends StatelessWidget {
  const ChatName(this.chat, this.name, {super.key});

  /// Unified reactive [Chat] with chat items.
  final RxChat? chat;

  /// [State] of a [TextField] related to the chat name.
  final TextFieldState name;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return _PaddingWidget(
        ReactiveTextField(
          key: const Key('RenameChatField'),
          state: name,
          label: chat?.chat.value.name == null
              ? chat?.title.value
              : 'label_name'.l10n,
          hint: 'label_name_hint'.l10n,
          onSuffixPressed: name.text.isEmpty
              ? null
              : () {
                  PlatformUtils.copy(text: name.text);
                  MessagePopup.success('label_copied'.l10n);
                },
          trailing: name.text.isEmpty
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
}

/// [Widget] which returns a [Chat.directLink] editable field.
class ChatLink extends StatelessWidget {
  const ChatLink(this.chat, this.link, {super.key});

  /// Unified reactive [Chat] with chat items.
  final RxChat? chat;

  /// [State] of a [TextField] related to the chat link.
  final TextFieldState link;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ReactiveTextField(
            key: const Key('LinkField'),
            state: link,
            onSuffixPressed: link.isEmpty.value
                ? null
                : () {
                    PlatformUtils.copy(
                      text:
                          '${Config.origin}${Routes.chatDirectLink}/${link.text}',
                    );

                    MessagePopup.success('label_copied'.l10n);
                  },
            trailing: link.isEmpty.value
                ? null
                : Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child: SvgImage.asset(
                        'assets/icons/copy.svg',
                        height: 15,
                      ),
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
                                  chat?.chat.value.directLink?.usageCount ?? 0
                            }) +
                            'dot_space'.l10n,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      TextSpan(
                        text: 'label_details'.l10n,
                        style: const TextStyle(color: Color(0xFF00A3FF)),
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
}

/// [Widget] which returns a list of [Chat.members].
class ChatMembers extends StatelessWidget {
  const ChatMembers(
    this.id, {
    super.key,
    required this.removeChatCallMember,
    required this.redialChatCallMember,
    this.chat,
    this.me,
    this.removeChatMember,
  });

  /// Unified reactive [Chat] with chat items.
  final RxChat? chat;

  /// ID of the current user.
  final UserId? me;

  /// ID of the current [chat].
  final ChatId id;

  /// [Function] that removes a [chat] member from an ongoing call.
  final Future<void> Function(UserId userId) removeChatCallMember;

  /// [Function] that redials a [chat] call member.
  final Future<void> Function(UserId userId) redialChatCallMember;

  /// [Function] that removes a [chat] member.
  final void Function(
    ChatInfoController c,
    BuildContext context,
    RxUser user,
  )? removeChatMember;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final RxUser? rxMe = chat!.members[me];
      final List<RxUser> members = [];

      for (var u in chat!.members.entries) {
        if (u.key != me) {
          members.add(u.value);
        }
      }

      if (rxMe != null) {
        members.insert(0, rxMe);
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BigButton(
            key: const Key('AddMemberButton'),
            leading: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: Text('btn_add_member'.l10n),
            onTap: () => AddChatMemberView.show(context, chatId: id),
          ),
          const SizedBox(height: 3),
          ...members.map((e) {
            final bool inCall = chat?.chat.value.ongoingCall?.members
                    .any((u) => u.user.id == e.id) ==
                true;

            return ContactTile(
              user: e,
              darken: 0.05,
              dense: true,
              onTap: () => router.user(e.id, push: true),
              trailing: [
                if (e.id != me && chat?.chat.value.ongoingCall != null) ...[
                  if (inCall)
                    WidgetButton(
                      key: const Key('Drop'),
                      onPressed: () => removeChatCallMember(e.id),
                      child: Container(
                        height: 22,
                        width: 22,
                        decoration: const BoxDecoration(
                          color: Colors.red,
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
                      color: Theme.of(context).colorScheme.secondary,
                      type: MaterialType.circle,
                      child: InkWell(
                        onTap: () => redialChatCallMember(e.id),
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
                if (e.id == me)
                  WidgetButton(
                    onPressed: () => removeChatMember,
                    child: Text(
                      'btn_leave'.l10n,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 15,
                      ),
                    ),
                  )
                else
                  WidgetButton(
                    key: const Key('DeleteMemberButton'),
                    onPressed: () => removeChatMember,
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
}

/// [Widget] which returns the action buttons to do with this [Chat].
class ChatActions extends StatelessWidget {
  const ChatActions(
    this.chat, {
    super.key,
    required this.isMonolog,
    required this.isLocal,
    this.hideChat,
    this.clearChat,
    this.leaveGroup,
    this.blacklistChat,
    this.unfavoriteChat,
    this.favoriteChat,
    this.unmuteChat,
    this.muteChat,
  });

  /// Unified reactive [Chat] with chat items.
  final RxChat? chat;

  /// Indicator whether the [chat] is a monolog or not.
  final bool isMonolog;

  /// Indicator whether the [chat] is a local or not.
  final bool isLocal;

  /// [Function] that unfavorites the chat.
  final Future<void> Function()? unfavoriteChat;

  /// [Function] that favorites the chat.
  final Future<void> Function()? favoriteChat;

  /// [Function] that unmutes the chat.
  final Future<void> Function()? unmuteChat;

  /// [Function] that mutes the chat.
  final Future<void> Function()? muteChat;

  /// [Function] that hides the chat.
  final void Function(ChatInfoController c, BuildContext context)? hideChat;

  /// [Function] that clears the chat.
  final void Function(ChatInfoController c, BuildContext context)? clearChat;

  /// [Function] that leaves the group chat.
  final void Function(ChatInfoController c, BuildContext context)? leaveGroup;

  /// [Function] that adds the chat to the blacklist.
  final void Function(
    ChatInfoController c,
    BuildContext context,
  )? blacklistChat;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isMonolog) ...[
          _DenseWidget(
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
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 10),
        ],
        if (!isLocal) ...[
          _DenseWidget(
            Obx(() {
              final bool favorited = chat?.chat.value.favoritePosition != null;

              return FieldButton(
                key: Key(
                  favorited ? 'UnfavoriteChatButton' : 'FavoriteChatButton',
                ),
                onPressed: favorited ? unfavoriteChat : favoriteChat,
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
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
        if (!isMonolog) ...[
          _DenseWidget(
            Obx(() {
              final bool muted = chat?.chat.value.muted != null;

              return FieldButton(
                onPressed: muted ? unmuteChat : muteChat,
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
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              );
            }),
          ),
          const SizedBox(height: 10),
        ],
        _DenseWidget(
          FieldButton(
            key: const Key('HideChatButton'),
            onPressed: () => hideChat,
            text: 'btn_hide_chat'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
        const SizedBox(height: 10),
        _DenseWidget(
          FieldButton(
            key: const Key('ClearHistoryButton'),
            onPressed: () => clearChat,
            text: 'btn_clear_history'.l10n,
            trailing: Transform.translate(
              offset: const Offset(0, -1),
              child: Transform.scale(
                scale: 1.15,
                child: SvgImage.asset('assets/icons/delete.svg', height: 14),
              ),
            ),
            style: TextStyle(color: Theme.of(context).colorScheme.secondary),
          ),
        ),
        if (!isMonolog) ...[
          const SizedBox(height: 10),
          _DenseWidget(
            FieldButton(
              onPressed: () => leaveGroup,
              text: 'btn_leave_group'.l10n,
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 10),
          _DenseWidget(
            FieldButton(
              onPressed: () => blacklistChat,
              text: 'btn_block'.l10n,
              trailing: Transform.translate(
                offset: const Offset(0, -1),
                child: Transform.scale(
                  scale: 1.15,
                  child: SvgImage.asset('assets/icons/delete.svg', height: 14),
                ),
              ),
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          const SizedBox(height: 10),
          _DenseWidget(
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
              style: TextStyle(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
        ],
      ],
    );
  }
}

/// [Widget] that displays a customizable button with a [leading] widget
/// and a [title] widget.
class BigButton extends StatelessWidget {
  const BigButton({
    super.key,
    required this.title,
    this.leading,
    this.onTap,
  });

  /// Leading [Widget] displayed before the title.
  final Widget? leading;

  /// Title [Widget] displayed in the button.
  final Widget title;

  /// [Function] called when the button is tapped.
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return SizedBox(
      key: key,
      height: 56,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: style.cardRadius,
          border: style.cardBorder,
          color: Colors.transparent,
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
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w300,
                      ),
                      child: title,
                    ),
                  ),
                  if (leading != null) ...[
                    const SizedBox(width: 12),
                    leading!,
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
}
