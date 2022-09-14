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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:badges/badges.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show ChatMemberInfoAction;
import 'package:messenger/domain/repository/contact.dart';
import 'package:messenger/ui/page/home/tab/chats/search/view.dart';
import 'package:messenger/ui/page/home/widget/animated_typing.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/outlined_rounded_button.dart';
import 'package:messenger/ui/widget/text_field.dart';
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
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/widget/animations.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import 'controller.dart';
import 'create_group/controller.dart';
import 'create_group/view.dart';
import 'widget/hovered_ink.dart';

/// View of the `HomeTab.chats` tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      key: const Key('ChatsTab'),
      init: ChatsTabController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (ChatsTabController c) {
        Widget tile({
          RxUser? user,
          RxChatContact? contact,
          void Function()? onTap,
          bool selected = false,
        }) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ContactTile(
              contact: contact,
              user: user,
              darken: 0,
              onTap: () {
                onTap?.call();
              },
              selected: selected,
            ),
          );
        }

        return Stack(
          children: [
            Scaffold(
              // extendBodyBehindAppBar: true,
              appBar: CustomAppBar.from(
                context: context,
                title: Obx(() {
                  final TextStyle? thin = Theme.of(context)
                      .textTheme
                      .bodyText1
                      ?.copyWith(color: Colors.black);

                  if (c.searching.value) {
                    Style style = Theme.of(context).extension<Style>()!;
                    return Theme(
                      data: Theme.of(context).copyWith(
                        shadowColor: const Color(0x55000000),
                        iconTheme: const IconThemeData(color: Colors.blue),
                        inputDecorationTheme: InputDecorationTheme(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: BorderSide.none,
                          ),
                          focusColor: Colors.white,
                          fillColor: Colors.white,
                          hoverColor: Colors.transparent,
                          filled: true,
                          isDense: true,
                          contentPadding: EdgeInsets.fromLTRB(
                            15,
                            PlatformUtils.isDesktop ? 30 : 23,
                            15,
                            0,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: ReactiveTextField(
                          state: c.search,
                          hint: 'Search',
                          maxLines: 1,
                          filled: false,
                          dense: true,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          style: style.boldBody.copyWith(fontSize: 17),
                          onChanged: () => c.query.value = c.search.text,
                        ),
                      ),
                    );
                  }

                  return Text('label_chats'.l10n);
                }),
                leading: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: IconButton(
                      splashColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      highlightColor: Colors.transparent,
                      onPressed: () {
                        if (c.searching.isFalse) {
                          c.searching.value = true;
                          Future.delayed(
                            Duration.zero,
                            c.search.focus.requestFocus,
                          );
                        }
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
                    padding: const EdgeInsets.only(right: 8.0),
                    child: Obx(() {
                      Widget child;
                      if (c.searching.value) {
                        child = IconButton(
                          key: const Key('CloseSearch'),
                          splashColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () {
                            c.search.clear();
                            c.query.value = null;
                            c.searchResults.value = null;
                            c.searchStatus.value = RxStatus.empty();
                            c.searching.value = false;
                          },
                          icon: SvgLoader.asset(
                            'assets/icons/close_primary.svg',
                            height: 15,
                          ),
                        );
                      } else {
                        child = IconButton(
                          splashColor: Colors.transparent,
                          hoverColor: Colors.transparent,
                          highlightColor: Colors.transparent,
                          onPressed: () async {
                            await ModalPopup.show(
                              context: context,
                              child: const CreateGroupView(),
                              desktopConstraints: const BoxConstraints(
                                maxWidth: double.infinity,
                                maxHeight: double.infinity,
                              ),
                              modalConstraints:
                                  const BoxConstraints(maxWidth: 380),
                              mobileConstraints: const BoxConstraints(
                                maxWidth: double.infinity,
                                maxHeight: double.infinity,
                              ),
                              mobilePadding: const EdgeInsets.all(0),
                              desktopPadding: const EdgeInsets.all(0),
                            );
                          },
                          icon: SvgLoader.asset(
                            'assets/icons/group.svg',
                            height: 18.44,
                          ),
                        );
                      }

                      return AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: child,
                      );
                    }),
                  ),
                ],
              ),
              body: Obx(() {
                if (c.chatsReady.value) {
                  Widget? center;

                  if (c.query.isNotEmpty != true && c.chats.isEmpty) {
                    center = Center(child: Text('label_no_chats'.l10n));
                  } else if (c.query.isNotEmpty == true &&
                      c.chats.isEmpty &&
                      c.contacts.isEmpty &&
                      c.users.isEmpty) {
                    if (c.searchStatus.value.isSuccess) {
                      center = Center(child: Text('No user found'.l10n));
                    } else {
                      center = const Center(child: CircularProgressIndicator());
                    }
                  }

                  ThemeData theme = Theme.of(context);
                  final TextStyle? thin =
                      theme.textTheme.bodyText1?.copyWith(color: Colors.black);

                  return Column(
                    children: [
                      AnimatedSizeAndFade.showHide(
                        fadeDuration: 300.milliseconds,
                        sizeDuration: 300.milliseconds,
                        show: c.searching.value && c.query.isNotEmpty == true,
                        child: Container(
                          margin: const EdgeInsets.fromLTRB(2, 12, 2, 2),
                          height: 15,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              WidgetButton(
                                onPressed: () => c.jumpTo(0),
                                child: Obx(() {
                                  return Text(
                                    'Chats',
                                    style: thin?.copyWith(
                                      fontSize: 15,
                                      color: c.selected.value == 0
                                          ? const Color(0xFF63B4FF)
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 20),
                              WidgetButton(
                                onPressed: () => c.jumpTo(1),
                                child: Obx(() {
                                  return Text(
                                    'Contacts',
                                    style: thin?.copyWith(
                                      fontSize: 15,
                                      color: c.selected.value == 1
                                          ? const Color(0xFF63B4FF)
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 20),
                              WidgetButton(
                                onPressed: () => c.jumpTo(2),
                                child: Obx(() {
                                  return Text(
                                    'Users',
                                    style: thin?.copyWith(
                                      fontSize: 15,
                                      color: c.selected.value == 2
                                          ? const Color(0xFF63B4FF)
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(width: 20),
                              WidgetButton(
                                onPressed: () => c.jumpTo(2),
                                child: Obx(() {
                                  return Text(
                                    'Messages',
                                    style: thin?.copyWith(
                                      fontSize: 15,
                                      color: c.selected.value == 3
                                          ? const Color(0xFF63B4FF)
                                          : null,
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: center ??
                            ContextMenuInterceptor(
                              child: FlutterListView(
                                controller: c.controller,
                                delegate: FlutterListViewDelegate(
                                  (context, i) {
                                    dynamic e = c.getIndex(i);

                                    Widget child = Container();

                                    if (e is RxChat) {
                                      child = Padding(
                                        padding: const EdgeInsets.only(
                                          left: 10,
                                          right: 10,
                                        ),
                                        child: buildChatTile(context, c, e),
                                      );
                                    } else if (e is RxUser) {
                                      child = tile(
                                        user: e,
                                        onTap: () {
                                          c.openChat(user: e);
                                        },
                                      );
                                    } else if (e is RxChatContact) {
                                      child = tile(
                                        contact: e,
                                        onTap: () {
                                          c.openChat(contact: e);
                                        },
                                      );
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: i == 0 ? 10 : 0,
                                        bottom: i ==
                                                c.chats.length +
                                                    c.contacts.length +
                                                    c.users.length -
                                                    1
                                            ? 10
                                            : 0,
                                      ),
                                      child: child,
                                    );
                                  },
                                  childCount: c.chats.length +
                                      c.contacts.length +
                                      c.users.length,
                                ),
                              ),
                            ),
                      ),
                    ],
                  );

                  return ContextMenuInterceptor(
                    child: AnimationLimiter(
                      child: ListView.builder(
                        controller: ScrollController(),
                        itemCount:
                            c.chats.length + c.contacts.length + c.users.length,
                        itemBuilder: (BuildContext context, int i) {
                          return Container();
                        },
                      ),
                    ),
                  );
                }

                return const Center(child: CircularProgressIndicator());
              }),
            ),
          ],
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

      // if (chat.currentCall == null) {
      if (typings.isNotEmpty) {
        if (!rxChat.chat.value.isGroup) {
          subtitle = [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Печатает'.l10n,
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
              // Padding(
              //   padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
              //   child: ElevatedButton(
              //     onPressed: () => c.joinCall(chat.id),
              //     child: Text('btn_chat_join_call'.l10n),
              //   ),
              // ),
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
          var desc = StringBuffer();

          if (!chat.isGroup && item.authorId == c.me) {
            desc.write('${'label_you'.l10n}: ');
          }

          String? text = item.text?.val.replaceAll(' ', '');
          if (text?.isEmpty == true) {
            text = null;
          } else {
            text = item.text?.val;
          }

          if (text != null) {
            desc.write(text);
            if (item.attachments.isNotEmpty) {
              desc.write(
                  ' [${item.attachments.length} ${'label_attachments'.l10n}]');
            }
          } else if (item.attachments.isNotEmpty) {
            desc.write(
                '[${item.attachments.length} ${'label_attachments'.l10n}]');
          } else {
            desc.write('[Quoted message]');
          }

          subtitle = [
            if (chat.isGroup)
              Padding(
                padding: const EdgeInsets.only(right: 5),
                child: FutureBuilder<RxUser?>(
                  future: c.getUser(item.authorId),
                  builder: (_, snapshot) => AvatarWidget.fromRxUser(
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
              if (chat.isGroup) {
                content = const Text('Group created');
              } else {
                content = const Text('Dialog created');
              }
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
      /*  } else {


        final TextStyle? thin = Theme.of(context)
            .textTheme
            .bodyText1
            ?.copyWith(color: Colors.black);

        subtitle = [
          // Expanded(
          //   child: OutlinedRoundedButton(
          //     maxWidth: null,
          //     title: Text(
          //       'btn_join_call'.l10n,
          //       style: thin?.copyWith(color: Colors.white),
          //     ),
          //     height: 27,
          //     borderRadius: BorderRadius.circular(30),
          //     onPressed: () => c.joinCall(chat.id),
          //     color: const Color(0xFF63B4FF),
          //   ),
          // ),
          // const Expanded(
          //   child: Text(
          //     'Присоединиться',
          //     style: TextStyle(
          //       color: Color(0xFF63B4FF),
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 6),
          // _circleButton(
          //   onPressed: () => c.joinCall(chat.id, withVideo: true),
          //   child: SvgLoader.asset(
          //     'assets/icons/chat_video_call_white.svg',
          //     width: 27.72,
          //     height: 19,
          //   ),
          // ),
          // const SizedBox(width: 12),
          // _circleButton(
          //   onPressed: () => c.joinCall(chat.id),
          //   child: SvgLoader.asset(
          //     'assets/icons/chat_audio_call_white.svg',
          //     width: 21,
          //     height: 21,
          //   ),
          // ),
          if (chat.unreadCount != 0) const SizedBox(width: 12),
          // Expanded(
          //   child: OutlinedRoundedButton(
          //     height: 35,
          //     color: const Color(0xFF63B4FF),
          //     onPressed: () => c.joinCall(chat.id),
          //     title: SvgLoader.asset(
          //       'assets/icons/chat_audio_call_white.svg',
          //       width: 21,
          //       height: 21,
          //     ),
          //   ),
          // ),
          // const SizedBox(width: 6),
          // Expanded(
          //   child: OutlinedRoundedButton(
          //     height: 35,
          //     color: const Color(0xFF63B4FF),
          //     onPressed: () => c.joinCall(chat.id, withVideo: true),
          //     title: SvgLoader.asset(
          //       'assets/icons/chat_video_call_white.svg',
          //       width: 27.72,
          //       height: 19,
          //     ),
          //   ),
          // ),
          // if (chat.unreadCount != 0) const SizedBox(width: 6),
        ];
        // subtitle = [
        //   Flexible(
        //     child: Padding(
        //       padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
        //       child: ElevatedButton(
        //         onPressed: () => c.joinCall(chat.id),
        //         child: Row(
        //           mainAxisSize: MainAxisSize.min,
        //           children: [
        //             const Icon(Icons.call, size: 21, color: Colors.white),
        //             const SizedBox(width: 5),
        //             Flexible(
        //               child: Text(
        // 'btn_join_call'.l10n,
        // maxLines: 1,
        // overflow: TextOverflow.ellipsis,
        //               ),
        //             ),
        //           ],
        //         ),
        //       ),
        //     ),
        //   ),
        //   Padding(
        //     padding: const EdgeInsets.fromLTRB(10, 4, 0, 4),
        //     child: ElevatedButton(
        //       onPressed: () => c.joinCall(chat.id, withVideo: true),
        //       child:
        //           const Icon(Icons.video_call, size: 22, color: Colors.white),
        //     ),
        //   ),
        // ];
      }*/

      Widget _circleButton({
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
          padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
          child: ConditionalBackdropFilter(
            condition: false,
            filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
            borderRadius:
                context.isMobile ? BorderRadius.zero : style.cardRadius,
            child: InkWellWithHover(
              selectedColor: const Color.fromRGBO(210, 227, 249, 1),
              unselectedColor: style.cardColor,
              isSelected: selected,
              hoveredBorder: selected
                  ? Border.all(
                      color: const Color(0xFFB9D9FA),
                      width: 0.5,
                    )
                  : Border.all(
                      color: const Color(0xFFDAEDFF),
                      width: 0.5,
                    ),
              unhoveredBorder:
                  selected ? style.primaryBorder : style.cardBorder,
              borderRadius: style.cardRadius,
              onTap: () => router.chat(chat.id),
              unselectedHoverColor: const Color.fromARGB(255, 244, 249, 255),
              // unselectedHoverColor: const Color.fromRGBO(230, 241, 254, 1),
              selectedHoverColor: const Color.fromRGBO(210, 227, 249, 1),
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
                                  // : '${chat.currentCall?.conversationStartedAt?.val.minute}:${chat.currentCall?.conversationStartedAt?.val.second}',
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
                                    padding: const EdgeInsets.all(2.0),
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
                            ? _circleButton(
                                key: const Key('Drop'),
                                onPressed: () => c.dropCall(chat.id),
                                color: Colors.red,
                                child: SvgLoader.asset(
                                  'assets/icons/call_end.svg',
                                  width: 38,
                                  height: 38,
                                ),
                              )
                            : _circleButton(
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
