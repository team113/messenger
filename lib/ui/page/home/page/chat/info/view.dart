// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:collection/collection.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/controller.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:messenger/util/platform_utils.dart';

import '/config.dart';
import '/domain/model/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/info/add_member/controller.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';
import 'remove_member/view.dart';

/// View of the [Routes.chatInfo] page.
class ChatInfoView extends StatelessWidget {
  const ChatInfoView(this.id, {Key? key}) : super(key: key);

  /// ID of the [Chat] of this info page.
  final ChatId id;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    Widget block({
      List<Widget> children = const [],
      EdgeInsets padding = const EdgeInsets.fromLTRB(32, 16, 32, 16),
    }) {
      return Center(
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
          decoration: BoxDecoration(
            // color: Colors.white,
            border: style.primaryBorder,
            color: style.messageColor,
            borderRadius: BorderRadius.circular(15),
            // border: Border.all(color: const Color(0xFFE0E0E0)),
          ),
          constraints:
              context.isNarrow ? null : const BoxConstraints(maxWidth: 400),
          padding: padding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      );
    }

    return GetBuilder<ChatInfoController>(
      key: const Key('ChatInfoView'),
      init: ChatInfoController(id, Get.find(), Get.find(), Get.find()),
      tag: id.val,
      builder: (c) {
        return Obx(() {
          if (c.status.value.isLoading) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
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
                  Center(
                    child: AvatarWidget.fromRxChat(
                      c.chat,
                      radius: 17,
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
                                SvgLoader.asset(
                                  'assets/icons/muted.svg',
                                  width: 19.99,
                                  height: 15,
                                ),
                                // Icon(
                                //   Icons.volume_off,
                                //   color:
                                //       Theme.of(context).primaryIconTheme.color,
                                //   size: 17,
                                // ),
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
                  onPressed: () => router.chat(id),
                  child: Transform.translate(
                    offset: const Offset(0, 1),
                    child: SvgLoader.asset(
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
                      child: SvgLoader.asset(
                        'assets/icons/chat_video_call.svg',
                        height: 17,
                      ),
                    ),
                  ],
                  const SizedBox(width: 28),
                  WidgetButton(
                    onPressed: () => c.call(false),
                    child: SvgLoader.asset(
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
                                child: SvgLoader.asset(
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
                                child: SvgLoader.asset(
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
            body: ListView(
              children: [
                const SizedBox(height: 8),
                block(
                  children: [
                    _label(context, 'Публичная информация'),
                    _avatar(c, context),
                    const SizedBox(height: 15),
                    _name(c, context),
                  ],
                ),
                block(
                  children: [
                    _label(context, 'Участники'),
                    _members(c, context),
                  ],
                ),
                block(
                  children: [
                    _label(context, 'Прямая ссылка'),
                    _link(c, context),
                  ],
                ),
                block(
                  children: [
                    _label(context, 'Действия'),
                    _actions(c, context),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          );
        });
      },
    );
  }

  /// Returns a header subtitle of the [Chat].
  Widget _chatSubtitle(ChatInfoController c, BuildContext context) {
    final TextStyle? style = Theme.of(context).textTheme.caption;

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
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            WidgetButton(
              onPressed: () async {
                await c.pickAvatar();
              },
              child: AvatarWidget.fromRxChat(
                c.chat,
                radius: 100,
                quality: AvatarQuality.original,
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
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x22000000),
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      : const SizedBox.shrink(),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Center(
          child: WidgetButton(
            onPressed:
                c.chat?.chat.value.avatar == null ? null : c.deleteAvatar,
            child: SizedBox(
              height: 20,
              child: c.chat?.chat.value.avatar == null
                  ? null
                  : Text(
                      'Delete',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                      ),
                    ),
            ),
          ),
        ),
        // const SizedBox(height: 10),
      ],
    );

    // Builds the manipulation buttons with [Chat.avatar] upload or removal
    // indication.
    Widget buttons() {
      if (c.avatar.value.isLoading) {
        return const CircularProgressIndicator();
      } else if (c.avatar.value.isSuccess) {
        return const Center(child: Icon(Icons.check));
      } else {
        return Row(
          children: [
            TextButton(
              key: const Key('ChangeAvatar'),
              onPressed: c.pickAvatar,
              child: Text('btn_change_avatar'.l10n),
            ),
            if (c.chat?.avatar.value != null)
              TextButton(
                key: const Key('DeleteAvatar'),
                onPressed: c.deleteAvatar,
                child: Text('btn_delete_avatar'.l10n),
              ),
          ],
        );
      }
    }

    return Obx(() {
      return _padding(
        Row(
          children: [
            AvatarWidget.fromRxChat(
              c.chat,
              key: const Key('ChatAvatar'),
              radius: 29,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: buttons(),
              ),
            )
          ],
        ),
      );
    });
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
                  Clipboard.setData(ClipboardData(text: c.name.text));
                  // MessagePopup.success('label_copied_to_clipboard'.l10n);
                },
          trailing: c.name.text.isEmpty
              ? null
              : Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/copy.svg',
                      height: 15,
                    ),
                  ),
                ),
        ),
      );
    });
  }

  /// Returns a [Chat.directLink] editable field.
  Widget _link(ChatInfoController c, BuildContext context) {
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
                    Clipboard.setData(
                      ClipboardData(
                        text:
                            '${Config.origin}${Routes.chatDirectLink}/${c.link.text}',
                      ),
                    );

                    // MessagePopup.success('label_copied_to_clipboard'.l10n);
                  },
            trailing: c.link.isEmpty.value
                ? null
                : Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child: SvgLoader.asset(
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
                      const TextSpan(
                        text: 'Переходов: 0. ',
                        // style: TextStyle(color: Color(0xFF888888)),
                        style: TextStyle(color: Color(0xFF888888)),
                      ),
                      TextSpan(
                        text: 'Подробнее.',
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

      return ExpandablePanel(
        key: const Key('ChatDirectLinkExpandable'),
        header: ListTile(
          leading: const Icon(Icons.link),
          title: Text('label_direct_chat_link'.l10n),
        ),
        collapsed: Container(),
        expanded: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('label_direct_chat_link_in_chat_description'.l10n),
              const SizedBox(height: 10),
              _padding(
                ReactiveTextField(
                  key: const Key('DirectChatLinkTextField'),
                  enabled: true,
                  state: c.link,
                  prefixText: '${Config.origin}${Routes.chatDirectLink}/',
                  label: 'label_direct_chat_link'.l10n,
                  suffix: Icons.copy,
                  onSuffixPressed:
                      c.chat?.chat.value.directLink == null ? null : c.copyLink,
                ),
              ),
              Row(
                children: [
                  Text(
                    '${'label_transition_count'.l10n}: ${c.chat?.chat.value.directLink?.usageCount ?? 0}',
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (c.chat?.chat.value.directLink != null &&
                            !c.link.isEmpty.value)
                          Flexible(
                            child: TextButton(
                              key: const Key('RemoveChatDirectLink'),
                              onPressed:
                                  !c.link.editable.value ? null : c.deleteLink,
                              child: Text(
                                'btn_delete_direct_chat_link'.l10n,
                                style: context.textTheme.bodyText1!.copyWith(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        Flexible(
                          child: TextButton(
                            key: const Key('GenerateChatDirectLink'),
                            onPressed: c.link.editable.value
                                ? c.link.isEmpty.value
                                    ? c.generateLink
                                    : c.link.submit
                                : null,
                            child: Text(
                              c.link.isEmpty.value
                                  ? 'btn_generate_direct_chat_link'.l10n
                                  : 'btn_submit'.l10n,
                              style: context.textTheme.bodyText1!.copyWith(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _label(BuildContext context, String text) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            text,
            style: style.systemMessageStyle
                .copyWith(color: Colors.black, fontSize: 18),
          ),
        ),
      ),
    );
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
        Widget? subtitle,
        void Function()? onTap,
        bool selected = false,
      }) {
        return SizedBox(
          height: 56, // 73,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: style.cardRadius,
              border: style.cardBorder,
              color: Colors.transparent,
            ),
            child: Material(
              type: MaterialType.card,
              borderRadius: style.cardRadius,
              color: selected
                  ? style.cardSelectedColor
                  : style.cardColor.darken(0.05),
              child: InkWell(
                borderRadius: style.cardRadius,
                onTap: onTap,
                hoverColor: const Color(0xFFF4F9FF),
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
            leading: Icon(
              Icons.people,
              color: Theme.of(context).colorScheme.secondary,
            ),
            title: const Text('Добавить участника'),
            onTap: () => AddMemberView.show(context, chatId: id),
          ),
          const SizedBox(height: 3),
          // Container(
          //   // constraints: const BoxConstraints(minHeight: 76),
          //   decoration: BoxDecoration(
          //     borderRadius: style.cardRadius,
          //     border: style.cardBorder,
          //     color: Colors.transparent,
          //   ),
          //   child: Material(
          //     type: MaterialType.card,
          //     borderRadius: style.cardRadius,
          //     color: style.cardColor.darken(0.05),
          //     child: InkWell(
          //       borderRadius: style.cardRadius,
          //       onTap: () => AddMemberView.show(context, chatId: id),
          //       hoverColor: const Color(0xFFF4F9FF),
          //       child: Padding(
          //         padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          //         child: Row(
          //           children: [
          //             const AvatarWidget(radius: 30),
          //             const SizedBox(width: 12),
          //             Expanded(
          //               child: Text(
          //                 'Добавить в группу',
          //                 overflow: TextOverflow.ellipsis,
          //                 maxLines: 1,
          //                 style: Theme.of(context)
          //                     .textTheme
          //                     .headline5
          //                     ?.copyWith(
          //                       color: Theme.of(context).colorScheme.secondary,
          //                     ),
          //               ),
          //             ),
          //           ],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 6),
          // WidgetButton(
          //   onPressed: () => AddMemberView.show(context, chatId: id),
          //   child: IgnorePointer(
          //     child: ReactiveTextField(
          //       state: TextFieldState(
          //         text: 'Добавить участника',
          //         editable: false,
          //       ),
          //       style:
          //           TextStyle(color: Theme.of(context).colorScheme.secondary),
          //     ),
          //   ),
          // ),
          // const SizedBox(height: 10),
          ...members.map((e) {
            final bool inCall = c.chat?.chat.value.ongoingCall?.members
                    .none((u) => u.user.id == e.id) ==
                false;

            return ContactTile(
              user: e,
              darken: 0.05,
              onTap: () => router.user(e.id, push: true),
              trailing: [
                if (e.id != c.me && c.chat?.chat.value.ongoingCall != null) ...[
                  if (inCall)
                    WidgetButton(
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
                          child: SvgLoader.asset(
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
                        onTap: () => c.redialChatCallMember(e.id),
                        borderRadius: BorderRadius.circular(60),
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: Center(
                            child: SvgLoader.asset(
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
                    // onPressed: () => c.removeChatMember(e.id),
                    onPressed: () => RemoveMemberView.show(
                      context,
                      chatId: c.chatId,
                      user: e,
                    ),
                    child: Text(
                      'Leave',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 15,
                      ),
                    ),
                  )
                else
                  WidgetButton(
                    // onPressed: () => c.removeChatMember(e.id),
                    onPressed: () => RemoveMemberView.show(
                      context,
                      chatId: c.chatId,
                      user: e,
                    ),
                    child: SvgLoader.asset(
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

  Widget _actions(ChatInfoController c, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Добавить в контакты',
                  editable: false,
                ),
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/delete.svg',
                      height: 14,
                    ),
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Добавить в избранные',
                  editable: false,
                ),
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/delete.svg',
                      height: 14,
                    ),
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          Obx(() {
            final bool muted = c.chat?.chat.value.muted != null;

            return WidgetButton(
              onPressed: () => muted ? c.unmuteChat(id) : c.muteChat(id),
              child: IgnorePointer(
                child: ReactiveTextField(
                  state: TextFieldState(
                    text: muted
                        ? 'Включить уведомления'
                        : 'Отключить уведомления',
                    editable: false,
                  ),
                  trailing: Transform.translate(
                    offset: const Offset(0, -1),
                    child: Transform.scale(
                      scale: 1.15,
                      child: muted
                          ? SvgLoader.asset(
                              'assets/icons/btn_mute.svg',
                              width: 18.68,
                              height: 15,
                            )
                          : SvgLoader.asset(
                              'assets/icons/btn_unmute.svg',
                              width: 17.86,
                              height: 15,
                            ),
                    ),
                  ),
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.secondary),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Скрыть чат',
                  editable: false,
                ),
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/delete.svg',
                      height: 14,
                    ),
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Очистить чат',
                  editable: false,
                ),
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/delete.svg',
                      height: 14,
                    ),
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Покинуть группу',
                  editable: false,
                ),
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/delete.svg',
                      height: 14,
                    ),
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Заблокировать',
                  editable: false,
                ),
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/delete.svg',
                      height: 14,
                    ),
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _dense(
          WidgetButton(
            onPressed: () {},
            child: IgnorePointer(
              child: ReactiveTextField(
                state: TextFieldState(
                  text: 'Пожаловаться',
                  editable: false,
                ),
                trailing: Transform.translate(
                  offset: const Offset(0, -1),
                  child: Transform.scale(
                    scale: 1.15,
                    child: SvgLoader.asset(
                      'assets/icons/delete.svg',
                      height: 14,
                    ),
                  ),
                ),
                style:
                    TextStyle(color: Theme.of(context).colorScheme.secondary),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
