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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_list_view/flutter_list_view.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/model/my_user.dart';
import '/domain/repository/chat.dart';
import '/domain/repository/contact.dart';
import '/domain/repository/user.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/recent_chat.dart';
import 'widget/search_user_tile.dart';

/// View of the `HomeTab.chats` tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

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
                      maxWidth: double.infinity,
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
                  final Widget child;

                  if (c.search.value != null) {
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
                            key: const Key('SearchField'),
                            state: c.search.value!.search,
                            hint: 'label_search'.l10n,
                            maxLines: 1,
                            filled: false,
                            dense: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            style: style.boldBody.copyWith(fontSize: 17),
                            onChanged: () => c.search.value?.query.value =
                                c.search.value?.search.text ?? '',
                          ),
                        ),
                      ),
                    );
                  } else if (c.searching.value) {
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
                            state: c.search2,
                            hint: 'Search',
                            maxLines: 1,
                            filled: false,
                            dense: true,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            style: style.boldBody.copyWith(fontSize: 17),
                            onChanged: () => c.query.value = c.search2.text,
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
                          c.search2.focus.requestFocus,
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
                  Obx(() {
                    return AnimatedSwitcher(
                      duration: 250.milliseconds,
                      child: WidgetButton(
                        onPressed: c.searching.value
                            ? null
                            : () {
                                c.searching.value = true;
                                c.search2.focus.addListener(() {
                                  if (c.search2.focus.hasFocus == false &&
                                      c.search2.text.isEmpty == true) {
                                    c.searching.value = false;
                                  }
                                });
                                Future.delayed(
                                  Duration.zero,
                                  c.search2.focus.requestFocus,
                                );
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20, right: 12),
                          child: SvgLoader.asset(
                            'assets/icons/search.svg',
                            width: 17.77,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
                actions: [
                  Obx(() {
                    Widget child;

                    if (c.searching.value || c.groupCreating.value) {
                      child = WidgetButton(
                        key: const Key('CloseSearch'),
                        onPressed: () => c.closeSearch(false),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 18),
                          child: SizedBox(
                            width: 21.77,
                            child: SvgLoader.asset(
                              'assets/icons/close_primary.svg',
                              height: 15,
                            ),
                          ),
                        ),
                      );
                    } else {
                      child = WidgetButton(
                        onPressed: c.searching.value || c.groupCreating.value
                            ? null
                            : () {
                                if (c.groupCreating.value) {
                                  if (c.selectedChats.isEmpty &&
                                      c.selectedContacts.isEmpty &&
                                      c.selectedUsers.isEmpty &&
                                      c.query.value?.isEmpty != false) {
                                    c.search2.clear();
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
                                  c.populate();
                                }
                              },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12, right: 18),
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
                        ),
                      );
                    }

                    return AnimatedSwitcher(
                      duration: 250.milliseconds,
                      child: child,
                    );
                  }),
                ],
              ),
              body: Obx(() {
                if (c.chatsReady.value) {
                  final Widget? child;

                  final ScrollController controller = ScrollController();

                  if (c.search.value?.search.isEmpty.value == false) {
                    if (c.search.value!.searchStatus.value.isLoading &&
                        c.elements.isEmpty) {
                      child = const Center(
                        key: Key('Loading'),
                        child: CircularProgressIndicator(),
                      );
                    } else if (c.elements.isNotEmpty) {
                      child = ListView.builder(
                        key: const Key('Search'),
                        controller: ScrollController(),
                        itemCount: c.elements.length,
                        itemBuilder: (_, i) {
                          final ListElement element = c.elements[i];
                          final Widget child;

                          if (element is ChatElement) {
                            final RxChat chat = element.chat;
                            child = Padding(
                              padding:
                                  const EdgeInsets.only(left: 10, right: 10),
                              child: Obx(() {
                                return RecentChatTile(
                                  chat,
                                  key: Key('SearchChat_${chat.id}'),
                                  me: c.me,
                                  blocked: c.isBlocked(
                                    chat,
                                    chat.members.values,
                                    c.blacklist,
                                  ),
                                  getUser: c.getUser,
                                  onJoin: () => c.joinCall(chat.id),
                                  onDrop: () => c.dropCall(chat.id),
                                  inCall: () => c.inCall(chat.id),
                                );
                              }),
                            );
                          } else if (element is ContactElement) {
                            child = SearchUserTile(
                              key: Key('SearchContact_${element.contact.id}'),
                              contact: element.contact,
                              onTap: () => c.openChat(contact: element.contact),
                            );
                          } else if (element is UserElement) {
                            child = SearchUserTile(
                              key: Key('SearchUser_${element.user.id}'),
                              user: element.user,
                              onTap: () => c.openChat(user: element.user),
                            );
                          } else if (element is DividerElement) {
                            child = Center(
                              child: Container(
                                margin: const EdgeInsets.fromLTRB(10, 2, 10, 2),
                                padding:
                                    const EdgeInsets.fromLTRB(12, 10, 12, 6),
                                width: double.infinity,
                                child: Center(
                                  child: Text(
                                    element.category.name.capitalizeFirst!,
                                    style: style.systemMessageStyle.copyWith(
                                      color: Colors.black,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          } else {
                            child = const SizedBox();
                          }
                          return AnimationConfiguration.staggeredList(
                            position: i,
                            duration: const Duration(milliseconds: 375),
                            child: SlideAnimation(
                              horizontalOffset: 50,
                              child: FadeInAnimation(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    top: i == 0 ? 3 : 0,
                                    bottom: i == c.elements.length - 1 ? 4 : 0,
                                  ),
                                  child: child,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    } else {
                      child = Center(
                        key: const Key('NothingFound'),
                        child: Text('label_nothing_found'.l10n),
                      );
                    }
                  } else {
                    if (c.groupCreating.value || c.searching.value) {
                      Widget? center;

                      if (c.query.isNotEmpty == true &&
                          c.chats.isEmpty &&
                          c.contacts2.isEmpty &&
                          c.users2.isEmpty) {
                        if (c.searchStatus.value.isSuccess) {
                          center = Center(child: Text('No user found'.l10n));
                        } else {
                          center =
                              const Center(child: CircularProgressIndicator());
                        }
                      } else if ((!c.searching.value ||
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
                                          bottom:
                                              i == c.chats.length - 1 ? 5 : 0,
                                        ),
                                        child: Obx(() {
                                          return RecentChatTile(
                                            chat,
                                            me: c.me,
                                            blocked: c.isBlocked(
                                              chat,
                                              chat.members.values,
                                              c.blacklist,
                                            ),
                                            getUser: c.getUser,
                                            onJoin: () => c.joinCall(chat.id),
                                            onDrop: () => c.dropCall(chat.id),
                                            onLeave: () => c.leaveChat(chat.id),
                                            onHide: () => c.hideChat(chat.id),
                                            inCall: () => c.inCall(chat.id),
                                            onMute: () => c.muteChat(chat.id),
                                            onUnmute: () =>
                                                c.unmuteChat(chat.id),
                                            onFavorite: () =>
                                                c.favoriteChat(chat.id),
                                            onUnfavorite: () =>
                                                c.unfavoriteChat(chat.id),
                                          );
                                        }),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }

                      Widget chip(Widget child) {
                        return DefaultTextStyle(
                          style: style.systemMessageStyle.copyWith(
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

                      child = Column(
                        children: [
                          AnimatedSizeAndFade.showHide(
                            fadeDuration: 300.milliseconds,
                            sizeDuration: 300.milliseconds,
                            show: false,
                            // show: c.groupCreating.value,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                shadowColor: const Color(0x55000000),
                                iconTheme:
                                    const IconThemeData(color: Colors.blue),
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
                                margin:
                                    const EdgeInsets.fromLTRB(10, 12, 10, 2),
                                child: ReactiveTextField(
                                  state: c.search2,
                                  hint: 'Search',
                                  maxLines: 1,
                                  filled: true,
                                  style: style.boldBody.copyWith(fontSize: 17),
                                  onChanged: () =>
                                      c.query.value = c.search2.text,
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
                                              child: Obx(() {
                                                return RecentChatTile(
                                                  chat,
                                                  me: c.me,
                                                  blocked: c.isBlocked(
                                                    chat,
                                                    chat.members.values,
                                                    c.blacklist,
                                                  ),
                                                  getUser: c.getUser,
                                                  onJoin: () =>
                                                      c.joinCall(chat.id),
                                                  onDrop: () =>
                                                      c.dropCall(chat.id),
                                                  onLeave: () =>
                                                      c.leaveChat(chat.id),
                                                  onHide: () =>
                                                      c.hideChat(chat.id),
                                                  inCall: () =>
                                                      c.inCall(chat.id),
                                                  onFavorite: () =>
                                                      c.favoriteChat(chat.id),
                                                  onUnfavorite: () =>
                                                      c.unfavoriteChat(chat.id),
                                                );
                                              }),
                                            );
                                          }
                                        } else if (element is ContactElement) {
                                          if (c.groupCreating.value) {
                                            child = Obx(() {
                                              return selectedTile(
                                                contact: element.contact,
                                                selected: c.selectedContacts
                                                    .contains(element.contact),
                                                onTap: () => c.selectContact(
                                                    element.contact),
                                              );
                                            });
                                          } else {
                                            child = SearchUserTile(
                                              key: Key(
                                                  'SearchContact_${element.contact.id}'),
                                              contact: element.contact,
                                              onTap: () => c.openChat(
                                                  contact: element.contact),
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
                                            child = SearchUserTile(
                                              key: Key(
                                                  'SearchContact_${element.user.id}'),
                                              user: element.user,
                                              onTap: () => c.openChat(
                                                  user: element.user),
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
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                12,
                                                10,
                                                12,
                                                6,
                                              ),
                                              width: double.infinity,
                                              child: Center(
                                                child: Text(
                                                  element.category.name
                                                      .capitalizeFirst!,
                                                  style: style
                                                      .systemMessageStyle
                                                      .copyWith(
                                                    color: Colors.black,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          );
                                        }

                                        return Padding(
                                          padding: EdgeInsets.only(
                                            top: i == 0 ? 3 : 0,
                                            bottom: i == c.elements.length - 1
                                                ? 4
                                                : 0,
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
                    } else if (c.chats.isEmpty) {
                      child = Center(
                        key: const Key('NoChats'),
                        child: Text('label_no_chats'.l10n),
                      );
                    } else {
                      child = AnimationLimiter(
                        key: const Key('Chats'),
                        child: Scrollbar(
                          controller: controller,
                          child: ListView.builder(
                            controller: controller,
                            itemCount: c.chats.length,
                            itemBuilder: (_, i) {
                              final RxChat chat = c.chats[i];
                              return AnimationConfiguration.staggeredList(
                                position: i,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  horizontalOffset: 50,
                                  child: FadeInAnimation(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10),
                                      child: Obx(() {
                                        return RecentChatTile(
                                          chat,
                                          key: Key('RecentChat_${chat.id}'),
                                          me: c.me,
                                          blocked: c.isBlocked(
                                            chat,
                                            chat.members.values,
                                            c.blacklist,
                                          ),
                                          getUser: c.getUser,
                                          onJoin: () => c.joinCall(chat.id),
                                          onDrop: () => c.dropCall(chat.id),
                                          onLeave: () => c.leaveChat(chat.id),
                                          onHide: () => c.hideChat(chat.id),
                                          inCall: () => c.inCall(chat.id),
                                          onMute: () => c.muteChat(chat.id),
                                          onUnmute: () => c.unmuteChat(chat.id),
                                          onFavorite: () =>
                                              c.favoriteChat(chat.id),
                                          onUnfavorite: () =>
                                              c.unfavoriteChat(chat.id),
                                        );
                                      }),
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

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: ContextMenuInterceptor(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: child,
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
