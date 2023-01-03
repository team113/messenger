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

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'create_group/controller.dart';
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
      ),
      builder: (ChatsTabController c) {
        return Scaffold(
          extendBodyBehindAppBar: true,
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
              } else {
                child = Text('label_chats'.l10n);
              }

              return AnimatedSwitcher(duration: 250.milliseconds, child: child);
            }),
            leading: [
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 12),
                child: Obx(() {
                  return AnimatedSwitcher(
                    duration: 250.milliseconds,
                    child: WidgetButton(
                      key: const Key('SearchButton'),
                      onPressed: c.search.value != null ? null : c.toggleSearch,
                      child: SvgLoader.asset(
                        'assets/icons/search.svg',
                        width: 17.77,
                      ),
                    ),
                  );
                }),
              ),
            ],
            actions: [
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 18),
                child: Obx(() {
                  final Widget child;

                  if (c.search.value != null) {
                    child = WidgetButton(
                      key: const Key('CloseSearch'),
                      onPressed: () {
                        if (c.search.value?.query.isNotEmpty == true) {
                          c.toggleSearch(false);
                        }
                      },
                      child: SvgLoader.asset(
                        'assets/icons/close_primary.svg',
                        height: 15,
                      ),
                    );
                  } else {
                    child = WidgetButton(
                      onPressed: () => showDialog(
                        context: context,
                        builder: (_) => const CreateGroupView(),
                      ),
                      child: SvgLoader.asset(
                        'assets/icons/group.svg',
                        height: 18.44,
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
            if (!c.chatsReady.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final Widget? child;

            if (c.search.value?.search.isEmpty.value == false) {
              if (c.search.value!.searchStatus.value.isLoading &&
                  c.elements.isEmpty) {
                child = const Center(
                  key: Key('Loading'),
                  child: CircularProgressIndicator(),
                );
              } else if (c.elements.isNotEmpty) {
                child = AnimationLimiter(
                  child: ListView.builder(
                    key: const Key('Search'),
                    controller: ScrollController(),
                    itemCount: c.elements.length,
                    itemBuilder: (_, i) {
                      final ListElement element = c.elements[i];
                      final Widget child;

                      if (element is ChatElement) {
                        final RxChat chat = element.chat;
                        child = Padding(
                          padding: const EdgeInsets.only(left: 10, right: 10),
                          child: RecentChatTile(
                            chat,
                            key: Key('SearchChat_${chat.id}'),
                            me: c.me,
                            getUser: c.getUser,
                            onJoin: () => c.joinCall(chat.id),
                            onDrop: () => c.dropCall(chat.id),
                            inCall: () => c.inCall(chat.id),
                          ),
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
                            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
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
                  ),
                );
              } else {
                child = Center(
                  key: const Key('NothingFound'),
                  child: Text('label_nothing_found'.l10n),
                );
              }
            } else {
              if (c.chats.isEmpty) {
                child = Center(
                  key: const Key('NoChats'),
                  child: Text('label_no_chats'.l10n),
                );
              } else {
                final MediaQueryData? mediaQuery = MediaQuery.maybeOf(context);
                print(mediaQuery!.padding);
                print(mediaQuery.viewInsets);
                print(mediaQuery.viewPadding);
                print(mediaQuery.systemGestureInsets);
                print('----');
                return AnimationLimiter(
                  key: const Key('Chats'),
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      padding: EdgeInsets.only(
                        left: 0.0,
                        right: 0.0,
                        top: 60,
                        bottom: 58,
                      ),
                      // size: Size(mediaQuery.size.width,
                      //     mediaQuery.size.height - mediaQuery.padding.top),
                    ),
                    child: Container(
                      padding: mediaQuery.padding.copyWith(
                          top: mediaQuery.systemGestureInsets.top + 5,
                          bottom: mediaQuery.systemGestureInsets.bottom),
                      child: ListView.builder(
                        // padding: mediaQuery.padding.copyWith(
                        //   left: 0.0,
                        //   right: 0.0,
                        //   top: mediaQuery.padding.top + mediaQuery.viewInsets.top,
                        //   bottom: mediaQuery.padding.bottom +
                        //       mediaQuery.viewInsets.bottom,
                        // ),
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
                                  child: RecentChatTile(
                                    chat,
                                    key: Key('RecentChat_${chat.id}'),
                                    me: c.me,
                                    getUser: c.getUser,
                                    onJoin: () => c.joinCall(chat.id),
                                    onDrop: () => c.dropCall(chat.id),
                                    onLeave: () => c.leaveChat(chat.id),
                                    onHide: () => c.hideChat(chat.id),
                                    inCall: () => c.inCall(chat.id),
                                    onMute: () => c.muteChat(chat.id),
                                    onUnmute: () => c.unmuteChat(chat.id),
                                    onFavorite: () => c.favoriteChat(chat.id),
                                    onUnfavorite: () =>
                                        c.unfavoriteChat(chat.id),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                );
              }
            }

            return Container(
              // padding: const EdgeInsets.symmetric(vertical: 5),
              child: ContextMenuInterceptor(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: child,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
