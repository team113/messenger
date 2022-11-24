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

import 'dart:math';
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:badges/badges.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show ChatMemberInfoAction;
import 'package:messenger/domain/model/my_user.dart';
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
import 'mute_chat_popup/view.dart';
import 'widget/hovered_ink.dart';
import 'widget/recent_chat.dart';

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
              subtitle: [
                const SizedBox(height: 5),
                Text(
                  'Gapopa ID: ${(contact?.user.value?.user.value.num.val ?? user?.user.value.num.val)?.replaceAllMapped(
                    RegExp(r'.{4}'),
                    (match) => '${match.group(0)} ',
                  )}',
                  style: const TextStyle(color: Color(0xFF888888)),
                ),
              ],
              selected: selected,
            ),
          );
        }

        Widget selectedTile({
          RxUser? user,
          RxChatContact? contact,
          MyUser? myUser,
          void Function()? onTap,
          bool selected = false,
          List<Widget> subtitle = const [],
        }) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
            child: Stack(
              children: [
                ContactTile(
                  contact: contact,
                  user: user,
                  myUser: myUser,
                  darken: 0,
                  selected: selected,
                  margin: const EdgeInsets.symmetric(vertical: 0),
                  subtitle: subtitle,
                  trailing: [
                    if (myUser == null)
                      SizedBox(
                        width: 30,
                        height: 30,
                        child: AnimatedSwitcher(
                          duration: 200.milliseconds,
                          child: selected
                              ? const CircleAvatar(
                                  backgroundColor: Color(0xFF63B4FF),
                                  radius: 12,
                                  child: Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                )
                              : Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFD7D7D7),
                                      width: 1,
                                    ),
                                  ),
                                  width: 24,
                                  height: 24,
                                ),
                        ),
                      ),
                  ],
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      WidgetButton(
                        onPressed: () => router.user(
                          user?.id ?? contact!.user.value?.id ?? myUser!.id,
                        ),
                        child: const SizedBox(
                          width: 60,
                          height: double.infinity,
                        ),
                      ),
                      Expanded(
                        child: WidgetButton(
                          onPressed: onTap,
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget selectedChat({
          required RxChat chat,
          void Function()? onTap,
          bool selected = false,
        }) {
          Style style = Theme.of(context).extension<Style>()!;
          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 3, 10, 3),
            child: Stack(
              children: [
                SizedBox(
                  height: 72,
                  child: ContextMenuRegion(
                    key: Key('ContextMenuRegion_${chat.chat.value.id}'),
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
                            ? const Color(0xFFD7ECFF).withOpacity(0.8)
                            : style.cardColor,
                        child: InkWell(
                          borderRadius: style.cardRadius,
                          onTap: onTap,
                          hoverColor: selected
                              ? const Color(0x00D7ECFF)
                              : const Color.fromARGB(255, 244, 249, 255),
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(12, 9 + 3, 12, 9 + 3),
                            child: Row(
                              children: [
                                AvatarWidget.fromRxChat(chat, radius: 26),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    chat.title.value,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style:
                                        Theme.of(context).textTheme.headline5,
                                  ),
                                ),
                                SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: AnimatedSwitcher(
                                    duration: 200.milliseconds,
                                    child: selected
                                        ? const CircleAvatar(
                                            backgroundColor: Color(0xFF63B4FF),
                                            radius: 12,
                                            child: Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          )
                                        : Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: const Color(0xFFD7D7D7),
                                                width: 1,
                                              ),
                                            ),
                                            width: 24,
                                            height: 24,
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Row(
                    children: [
                      WidgetButton(
                        onPressed: () => router.user(
                          chat.members.values
                              .firstWhere((e) => e.id != c.me)
                              .id,
                        ),
                        child: const SizedBox(
                          width: 60,
                          height: double.infinity,
                        ),
                      ),
                      Expanded(
                        child: WidgetButton(
                          onPressed: onTap,
                          child: Container(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        Widget createGroupButton() {
          return Obx(() {
            Widget child = const SizedBox();

            if (c.groupCreating.value) {
              // bool enabled = (c.selectedContacts.isNotEmpty ||
              //         c.selectedUsers.isNotEmpty ||
              //         c.selectedChats.isNotEmpty) &&
              //     c.creatingStatus.value.isEmpty;

              Widget button({
                Key? key,
                Widget? leading,
                required Widget child,
                void Function()? onPressed,
                Color? color,
              }) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 6, bottom: 6),
                    // height: 56,
                    decoration: const BoxDecoration(
                      boxShadow: [
                        CustomBoxShadow(
                          blurRadius: 8,
                          color: Color(0x22000000),
                          blurStyle: BlurStyle.outer,
                        ),
                      ],
                    ),
                    child: OutlinedRoundedButton(
                      key: key,
                      maxWidth: null,
                      leading: leading,
                      title: child,
                      onPressed: onPressed,
                      color: color ?? Colors.white,
                    ),
                  ),
                );
              }

              child = Container(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
                child: Row(
                  children: [
                    button(
                      child: const Text(
                        'Close',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: Colors.black),
                      ),
                      onPressed: c.closeSearch,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    button(
                      child: const Text(
                        'Create group',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: c.createGroup,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ],
                ),
              );
            }

            return AnimatedSwitcher(
              duration: 250.milliseconds,
              child: child,
            );
          });
        }

        return Stack(
          children: [
            Scaffold(
              // extendBodyBehindAppBar: true,
              resizeToAvoidBottomInset: false,
              appBar: CustomAppBar(
                title: Obx(() {
                  Widget child;

                  if (c.searching.value) {
                    Style style = Theme.of(context).extension<Style>()!;
                    child = Theme(
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
                        child: Transform.translate(
                          offset: const Offset(0, 1),
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
                      ),
                    );
                  } else if (c.groupCreating.value) {
                    child = WidgetButton(
                      onPressed: () {
                        c.searching.value = true;
                        Future.delayed(
                          Duration.zero,
                          c.search.focus.requestFocus,
                        );
                      },
                      child: SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: Text(
                            'Create group'.l10n,
                            key: const Key('1'),
                          ),
                        ),
                      ),
                    );
                  } else {
                    child = Text('label_chats'.l10n, key: const Key('2'));
                  }

                  return AnimatedSwitcher(
                    duration: 250.milliseconds,
                    child: child,
                  );
                }),
                leading: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: Obx(() {
                      return AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: WidgetButton(
                          onPressed: c.searching.value
                              ? null
                              : () {
                                  c.searching.value = true;
                                  Future.delayed(
                                    Duration.zero,
                                    c.search.focus.requestFocus,
                                  );
                                },
                          child: SvgLoader.asset(
                            'assets/icons/search.svg',
                            width: 17.77,
                          ),
                          // child: c.groupCreating.value
                          //     ? SvgLoader.asset(
                          //         'assets/icons/group.svg',
                          //         width: 21.77,
                          //         height: 18.44,
                          //       )
                          //     : SvgLoader.asset(
                          //         'assets/icons/search.svg',
                          //         width: 17.77,
                          //       ),
                          // child: c.searching.value
                          //     ? SvgLoader.asset(
                          //         'assets/icons/search.svg',
                          //         width: 17.77,
                          //       )
                          //     : SvgLoader.asset(
                          //         'assets/icons/group.svg',
                          //         width: 21.77,
                          //         height: 18.44,
                          //       ),
                        ),
                      );
                    }),
                  ),
                ],
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(left: 12, right: 18),
                    child: Obx(() {
                      Widget child;

                      if (c.searching.value || c.groupCreating.value) {
                        child = WidgetButton(
                          key: const Key('CloseSearch'),
                          onPressed: () => c.closeSearch(false),
                          child: SvgLoader.asset(
                            'assets/icons/close_primary.svg',
                            height: 15,
                          ),
                        );
                      } else {
                        child = WidgetButton(
                          onPressed: c.searching.value || c.groupCreating.value
                              ? null
                              : () {
                                  // if (c.searching.isFalse) {
                                  //   c.searching.value = true;
                                  //   Future.delayed(
                                  //     Duration.zero,
                                  //     c.search.focus.requestFocus,
                                  //   );
                                  // }
                                  if (c.groupCreating.value) {
                                    if (c.selectedChats.isEmpty &&
                                        c.selectedContacts.isEmpty &&
                                        c.selectedUsers.isEmpty &&
                                        c.query.value?.isEmpty != false) {
                                      c.search.clear();
                                      c.query.value = null;
                                      c.searchResults.value = null;
                                      c.searchStatus.value = RxStatus.empty();
                                      c.searching.value = false;
                                      c.groupCreating.value = false;
                                      router.navigation.value = null;
                                      c.selectedChats.clear();
                                      c.selectedUsers.clear();
                                      c.selectedContacts.clear();
                                      c.populate();
                                    }
                                  } else if (c.groupCreating.isFalse) {
                                    c.groupCreating.value = true;
                                    router.navigation.value = const SizedBox();
                                    // router.navigation.value =
                                    // createGroupButton();
                                    // Future.delayed(
                                    //   Duration.zero,
                                    //   c.search.focus.requestFocus,
                                    // );
                                    c.populate();
                                  }
                                },
                          child: SizedBox(
                            width: 21.77,
                            child: c.groupCreating.value
                                ? SvgLoader.asset(
                                    'assets/icons/group.svg',
                                    width: 21.77,
                                    height: 18.44,
                                  )
                                : SvgLoader.asset(
                                    'assets/icons/group.svg',
                                    width: 21.77,
                                    height: 18.44,
                                  ),
                          ),
                        );
                      }

                      return SizedBox(
                        width: 21.77,
                        child: AnimatedSwitcher(
                          duration: 250.milliseconds,
                          child: child,
                        ),
                      );
                    }),
                  ),
                ],
              ),
              body: Obx(() {
                if (c.chatsReady.value) {
                  Widget? center;

                  if (c.query.isNotEmpty != true &&
                      (c.chats.isEmpty &&
                          c.users.isEmpty &&
                          c.contacts.isEmpty)) {
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
                  } else {
                    if ((!c.searching.value ||
                            c.query.value?.isEmpty != false) &&
                        !c.groupCreating.value) {
                      center = AnimationLimiter(
                        child: ContextMenuInterceptor(
                          child: ListView.builder(
                            controller: ScrollController(),
                            itemCount: c.chats.length,
                            itemBuilder: (BuildContext context, int i) {
                              RxChat chat = c.sortedChats[i];
                              return AnimationConfiguration.staggeredList(
                                position: i,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  horizontalOffset: 50.0,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        top: i == 0 ? 5 : 0,
                                        left: 10,
                                        right: 10,
                                        bottom: i == c.chats.length - 1 ? 5 : 0,
                                      ),
                                      child: RecentChatTile(
                                        chat,
                                        me: c.me,
                                        getUser: c.getUser,
                                        onJoin: () => c.joinCall(chat.id),
                                        onDrop: () => c.dropCall(chat.id),
                                        onLeave: () => c.leaveChat(chat.id),
                                        onHide: () => c.hideChat(chat.id),
                                        inCall: () => c.inCall(chat.id),
                                        onMute: () => MuteChatView.show(
                                          context,
                                          chatId: chat.id,
                                          onMute: (duration) => c.muteChat(
                                            chat.id,
                                            duration: duration,
                                          ),
                                        ),
                                        onUnmute: () => c.unmuteChat(chat.id),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }
                  }

                  ThemeData theme = Theme.of(context);
                  final TextStyle? thin =
                      theme.textTheme.bodyText1?.copyWith(color: Colors.black);
                  Style style = Theme.of(context).extension<Style>()!;

                  Widget chip(Widget child) {
                    return DefaultTextStyle(
                      style: style.systemMessageTextStyle.copyWith(
                        fontSize: 11,
                        color: Colors.black,
                      ),
                      maxLines: 1,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                        // margin: const EdgeInsets.only(right: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          // border: style.systemMessageBorder,
                          color: Colors.white,
                        ),
                        child: child,
                      ),
                    );
                  }

                  return Column(
                    children: [
                      AnimatedSizeAndFade.showHide(
                        fadeDuration: 300.milliseconds,
                        sizeDuration: 300.milliseconds,
                        show: false,
                        // show: c.groupCreating.value,
                        child: Theme(
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
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(10, 12, 10, 2),
                            child: ReactiveTextField(
                              state: c.search,
                              hint: 'Search',
                              maxLines: 1,
                              filled: true,
                              style: style.boldBody.copyWith(fontSize: 17),
                              onChanged: () => c.query.value = c.search.text,
                            ),
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
                                    ListElement element = c.elements[i];
                                    Widget child = const SizedBox();

                                    if (element is ChatElement) {
                                      if (c.groupCreating.value) {
                                        child = Obx(() {
                                          return selectedChat(
                                            chat: element.chat,
                                            selected: c.selectedChats
                                                .contains(element.chat),
                                            onTap: () =>
                                                c.selectChat(element.chat),
                                          );
                                        });
                                      } else {
                                        final RxChat chat = element.chat;
                                        child = Padding(
                                          padding: const EdgeInsets.only(
                                            left: 10,
                                            right: 10,
                                          ),
                                          child: RecentChatTile(
                                            chat,
                                            me: c.me,
                                            getUser: c.getUser,
                                            onJoin: () => c.joinCall(chat.id),
                                            onDrop: () => c.dropCall(chat.id),
                                            onLeave: () => c.leaveChat(chat.id),
                                            onHide: () => c.hideChat(chat.id),
                                            inCall: () => c.inCall(chat.id),
                                          ),
                                        );
                                      }
                                    } else if (element is ContactElement) {
                                      if (c.groupCreating.value) {
                                        child = Obx(() {
                                          return selectedTile(
                                            contact: element.contact,
                                            selected: c.selectedContacts
                                                .contains(element.contact),
                                            onTap: () => c
                                                .selectContact(element.contact),
                                          );
                                        });
                                      } else {
                                        child = tile(
                                          contact: element.contact,
                                          onTap: () {
                                            c.openChat(
                                              contact: element.contact,
                                            );
                                          },
                                        );
                                      }
                                    } else if (element is UserElement) {
                                      if (c.groupCreating.value) {
                                        child = Obx(() {
                                          return selectedTile(
                                            user: element.user,
                                            selected: c.selectedUsers
                                                .contains(element.user),
                                            onTap: () =>
                                                c.selectUser(element.user),
                                          );
                                        });
                                      } else {
                                        child = tile(
                                          user: element.user,
                                          onTap: () {
                                            c.openChat(user: element.user);
                                          },
                                        );
                                      }
                                    } else if (element is MyUserElement) {
                                      child = Obx(() {
                                        return selectedTile(
                                          myUser: c.myUser.value,
                                          selected: true,
                                          subtitle: [
                                            const SizedBox(height: 5),
                                            const Text(
                                              'Required',
                                              style: TextStyle(
                                                  color: Color(0xFF888888)),
                                            ),
                                          ],
                                        );
                                      });
                                    } else if (element is DividerElement) {
                                      child = Center(
                                        child: Container(
                                          margin: const EdgeInsets.fromLTRB(
                                            10,
                                            2,
                                            10,
                                            2,
                                          ),
                                          padding: const EdgeInsets.fromLTRB(
                                            12,
                                            10,
                                            12,
                                            6,
                                          ),
                                          width: double.infinity,
                                          // decoration: BoxDecoration(
                                          //   borderRadius:
                                          //       BorderRadius.circular(15),
                                          //   border: style.systemMessageBorder,
                                          //   color: style.systemMessageColor,
                                          // ),
                                          child: Center(
                                            child: Text(
                                              element.category.name
                                                  .capitalizeFirst!,
                                              style: style
                                                  .systemMessageTextStyle
                                                  .copyWith(
                                                color: Colors.black,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );

                                      // return Container(
                                      //   margin: const EdgeInsets.fromLTRB(
                                      //     0,
                                      //     20,
                                      //     0,
                                      //     4,
                                      //   ),
                                      //   child: Row(
                                      //     children: [
                                      //       const SizedBox(width: 8),
                                      //       Expanded(
                                      //         child: Container(
                                      //           width: double.infinity,
                                      //           padding:
                                      //               const EdgeInsets.fromLTRB(
                                      //             12,
                                      //             8,
                                      //             12,
                                      //             8,
                                      //           ),
                                      //           child: Row(
                                      //             children: [
                                      //               Expanded(
                                      //                 child: Container(
                                      //                   height: 0.5,
                                      //                   color: const Color(
                                      //                     0xFF000000,
                                      //                   ),
                                      //                 ),
                                      //               ),
                                      //               const SizedBox(width: 10),
                                      //               Text(
                                      //                 element.category.name
                                      //                     .capitalizeFirst!,
                                      //                 style: const TextStyle(
                                      //                   fontSize: 13,
                                      //                   color:
                                      //                       Color(0xFF000000),
                                      //                 ),
                                      //               ),
                                      //               const SizedBox(width: 10),
                                      //               Expanded(
                                      //                 child: Container(
                                      //                   height: 0.5,
                                      //                   color: const Color(
                                      //                     0xFF000000,
                                      //                   ),
                                      //                 ),
                                      //               ),
                                      //             ],
                                      //           ),
                                      //         ),
                                      //       ),
                                      //       const SizedBox(width: 8),
                                      //     ],
                                      //   ),
                                      // );
                                    }

                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: i == 0 ? 3 : 0,
                                        bottom:
                                            i == c.elements.length - 1 ? 4 : 0,
                                      ),
                                      child: child,
                                    );
                                  },
                                  childCount: c.elements.length,
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
              bottomNavigationBar: Obx(() {
                final Widget child;

                if (c.groupCreating.value) {
                  child = createGroupButton();
                } else {
                  child = const SizedBox();
                }

                return AnimatedSwitcher(
                  duration: 250.milliseconds,
                  child: child,
                );
              }),
            ),
            Obx(() {
              final Widget child;

              if (c.creatingStatus.value.isLoading) {
                child = Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0x33000000),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              } else {
                child = const SizedBox();
              }

              return AnimatedSwitcher(duration: 200.milliseconds, child: child);
            }),
          ],
        );
      },
    );
  }
}
