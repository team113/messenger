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

import 'dart:ui';

import 'package:badges/badges.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show ChatMemberInfoAction;
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import '/domain/model/chat_call.dart';
import '/domain/model/chat_item.dart';
import '/domain/model/chat.dart';
import '/domain/model/sending_status.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/home/page/chat/controller.dart' show ChatCallFinishReasonL10n;
import '/ui/page/home/widget/custom_app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';
import 'widget/hovered_ink.dart';

/// View of the `HomeTab.chats` tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('ChatsTab'),
      init: ChatsTabController(Get.find(), Get.find(), Get.find(), Get.find()),
      builder: (ChatsTabController c) {
        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            title: Text('label_chats'.l10n),
            leading: [
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () async {
                    // TODO: Implement search.
                  },
                  icon: SvgLoader.asset(
                    'assets/icons/search.svg',
                    width: 17.77,
                  ),
                ),
              ),
            ],
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  splashColor: Colors.transparent,
                  hoverColor: Colors.transparent,
                  highlightColor: Colors.transparent,
                  onPressed: () async {
                    // TODO: Implement creating group.
                  },
                  icon: SvgLoader.asset(
                    'assets/icons/group.svg',
                    height: 18.44,
                  ),
                ),
              ),
            ],
          ),
          body: Obx(() {
            if (c.chatsReady.value) {
              if (c.chats.isEmpty) {
                return Center(child: Text('label_no_chats'.l10n));
              }
              MediaQueryData metrics = MediaQuery.of(context);

              return MediaQuery(
                data: metrics.copyWith(
                  padding: metrics.padding.copyWith(
                    top: metrics.padding.top + 60,
                    bottom: metrics.padding.bottom - 18,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(top: 10, bottom: 10),
                  child: ContextMenuInterceptor(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        controller: ScrollController(),
                        itemCount: c.chats.length,
                        itemBuilder: (BuildContext context, int i) {
                          RxChat e = c.chats[i];

                          return AnimationConfiguration.staggeredList(
                            position: i,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              horizontalOffset: 50,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: buildChatTile(context, c, e),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            }

            return const Center(child: CircularProgressIndicator());
          }),
        );
      },
    );
  }

  /// Reactive [ListTile] with [RxChat]'s information.
  Widget buildChatTile(
    BuildContext context,
    ChatsTabController c,
    RxChat rxChat,
  ) {
    return Obx(() {
      Chat chat = rxChat.chat.value;
      ChatItem? item;
      if (rxChat.messages.isNotEmpty) {
        item = rxChat.messages.last.value;
      }
      item ??= chat.lastItem;

      const Color subtitleColor = Color(0xFF666666);
      List<Widget>? subtitle;

      Iterable<String> typings = rxChat.typingUsers
          .where((e) => e.id != c.me)
          .map((e) => e.name?.val ?? e.num.val);

      if (typings.isNotEmpty) {
        if (!rxChat.chat.value.isGroup) {
          subtitle = [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'label_typing'.l10n,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(width: 3),
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: AnimatedTyping(),
                ),
              ],
            ),
          ];
        } else {
          subtitle = [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: Text(
                      typings.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 4),
                    child: AnimatedTyping(),
                  ),
                ],
              ),
            )
          ];
        }
      } else if (item != null) {
        if (item is ChatCall) {
          String description = 'label_chat_call_ended'.l10n;
          if (item.finishedAt == null && item.finishReason == null) {
            subtitle = [
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 2, 6, 2),
                child: Icon(Icons.call, size: 16, color: subtitleColor),
              ),
              Flexible(child: Text('label_call_active'.l10n, maxLines: 2)),
            ];
          } else {
            description =
                item.finishReason?.localizedString(item.authorId == c.me) ??
                    description;
            subtitle = [
              const Padding(
                padding: EdgeInsets.fromLTRB(0, 2, 6, 2),
                child: Icon(Icons.call, size: 16, color: subtitleColor),
              ),
              Flexible(child: Text(description, maxLines: 2)),
            ];
          }
        } else if (item is ChatMessage) {
          final desc = StringBuffer();

          if (!chat.isGroup && item.authorId == c.me) {
            desc.write('${'label_you'.l10n}: ');
          }

          if (item.text != null) {
            desc.write(item.text!.val);
            if (item.attachments.isNotEmpty) {
              desc.write(
                  ' [${item.attachments.length} ${'label_attachments'.l10n}]');
            }
          } else if (item.attachments.isNotEmpty) {
            desc.write(
                '[${item.attachments.length} ${'label_attachments'.l10n}]');
          }

          subtitle = [
            if (chat.isGroup)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: FutureBuilder<RxUser?>(
                  future: c.getUser(item.authorId),
                  builder: (_, AsyncSnapshot<RxUser?> snapshot) =>
                      AvatarWidget.fromRxUser(
                    snapshot.data,
                    radius: 10,
                  ),
                ),
              ),
            Flexible(child: Text(desc.toString(), maxLines: 2)),
            ElasticAnimatedSwitcher(
              child: item.status.value == SendingStatus.sending
                  ? const Icon(Icons.access_alarm, size: 15)
                  : item.status.value == SendingStatus.error
                      ? const Icon(
                          Icons.error_outline,
                          size: 15,
                          color: Colors.red,
                        )
                      : Container(),
            ),
          ];
        } else if (item is ChatForward) {
          subtitle = [
            if (chat.isGroup)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: FutureBuilder<RxUser?>(
                  future: c.getUser(item.authorId),
                  builder: (_, snapshot) => snapshot.data != null
                      ? Obx(
                          () => AvatarWidget.fromUser(
                            snapshot.data!.user.value,
                            radius: 10,
                          ),
                        )
                      : AvatarWidget.fromUser(
                          chat.getUser(item!.authorId),
                          radius: 10,
                        ),
                ),
              ),
            Flexible(child: Text('[${'label_forwarded_message'.l10n}]')),
            ElasticAnimatedSwitcher(
              child: item.status.value == SendingStatus.sending
                  ? const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Icon(Icons.access_alarm, size: 15),
                    )
                  : item.status.value == SendingStatus.error
                      ? const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Icon(
                            Icons.error_outline,
                            size: 15,
                            color: Colors.red,
                          ),
                        )
                      : Container(),
            ),
          ];
        } else if (item is ChatMemberInfo) {
          Widget content = Text('${item.action}');

          switch (item.action) {
            case ChatMemberInfoAction.created:
              content = const Text('Chat created');
              break;

            case ChatMemberInfoAction.added:
              content = Text('${item.user.name ?? item.user.num} was added');
              break;

            case ChatMemberInfoAction.removed:
              content = Text('${item.user.name ?? item.user.num} was removed');
              break;

            case ChatMemberInfoAction.artemisUnknown:
              // No-op.
              break;
          }

          subtitle = [Flexible(child: content)];
        } else {
          subtitle = [
            const Flexible(child: Text('Пустое сообщение', maxLines: 2))
          ];
        }
      }

      Widget circleButton({
        Key? key,
        void Function()? onPressed,
        Color? color,
        required Widget child,
      }) {
        return WidgetButton(
          key: key,
          onPressed: onPressed,
          child: Container(
            key: key,
            height: 38,
            width: 38,
            decoration: BoxDecoration(
              color: color ?? const Color(0xFF63B4FF),
              shape: BoxShape.circle,
            ),
            child: Center(child: child),
          ),
        );
      }

      Style style = Theme.of(context).extension<Style>()!;

      bool selected = router.routes
              .lastWhereOrNull((e) => e.startsWith(Routes.chat))
              ?.startsWith('${Routes.chat}/${chat.id}') ==
          true;

      return ContextMenuRegion(
        key: Key('ContextMenuRegion_${chat.id}'),
        preventContextMenu: false,
        actions: [
          ContextMenuButton(
            key: const Key('ButtonHideChat'),
            label: 'btn_hide_chat'.l10n,
            onPressed: () => c.hideChat(chat.id),
          ),
          if (chat.isGroup)
            ContextMenuButton(
              key: const Key('ButtonLeaveChat'),
              label: 'btn_leave_chat'.l10n,
              onPressed: () => c.leaveChat(chat.id),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
          child: ConditionalBackdropFilter(
            condition: false,
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            borderRadius:
                context.isMobile ? BorderRadius.zero : style.cardRadius,
            child: InkWellWithHover(
              selectedColor: style.primaryCardColor,
              unselectedColor: style.cardColor,
              isSelected: selected,
              hoveredBorder: selected
                  ? style.primaryBorder
                  : style.hoveredBorderUnselected,
              unhoveredBorder:
                  selected ? style.primaryBorder : style.cardBorder,
              borderRadius: style.cardRadius,
              onTap: () => router.chat(chat.id),
              unselectedHoverColor: style.unselectedHoverColor,
              selectedHoverColor: style.primaryCardColor,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                child: Row(
                  children: [
                    AvatarWidget.fromRxChat(rxChat, radius: 30),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  rxChat.title.value,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  style: Theme.of(context).textTheme.headline5,
                                ),
                              ),
                              const SizedBox(height: 10),
                              if (chat.currentCall == null)
                                Text(
                                  chat.currentCall == null ? '10:10' : '32:02',
                                  style: Theme.of(context)
                                      .textTheme
                                      .subtitle2
                                      ?.copyWith(
                                        color: chat.currentCall == null
                                            ? null
                                            : const Color(0xFF63B4FF),
                                      ),
                                ),
                            ],
                          ),
                          Row(
                            children: [
                              const SizedBox(height: 3),
                              Expanded(
                                child: DefaultTextStyle(
                                  style: Theme.of(context).textTheme.subtitle2!,
                                  overflow: TextOverflow.ellipsis,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 3),
                                    child: Row(children: subtitle ?? []),
                                  ),
                                ),
                              ),
                              if (chat.unreadCount != 0) ...[
                                const SizedBox(width: 10),
                                Badge(
                                  toAnimate: false,
                                  elevation: 0,
                                  badgeContent: Padding(
                                    padding: const EdgeInsets.all(2),
                                    child: Text(
                                      '${chat.unreadCount}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (chat.currentCall != null) ...[
                      const SizedBox(width: 10),
                      AnimatedSwitcher(
                        key: const Key('ActiveCallButton'),
                        duration: 300.milliseconds,
                        child: c.isInCall(chat.id)
                            ? circleButton(
                                key: const Key('Drop'),
                                onPressed: () => c.leaveChat(chat.id),
                                color: Colors.red,
                                child: SvgLoader.asset(
                                  'assets/icons/call_end.svg',
                                  width: 38,
                                  height: 38,
                                ),
                              )
                            : circleButton(
                                key: const Key('Join'),
                                onPressed: () => c.joinCall(chat.id),
                                child: SvgLoader.asset(
                                  'assets/icons/audio_call_start.svg',
                                  width: 18,
                                  height: 18,
                                ),
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
