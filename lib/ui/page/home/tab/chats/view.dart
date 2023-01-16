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

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/mobile_paddings.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/selected_tile.dart';
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
        return Stack(
          children: [
            Obx(() {
              return Scaffold(
                extendBodyBehindAppBar: true,
                resizeToAvoidBottomInset: false,
                appBar: CustomAppBar(
                  title: Obx(() {
                    final Widget child;

                    if (c.searching.value) {
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
                              onChanged: () => c.search.value!.query.value =
                                  c.search.value!.search.text,
                            ),
                          ),
                        ),
                      );
                    } else if (c.groupCreating.value) {
                      child = WidgetButton(
                        onPressed: c.startSearch,
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Text(
                              'btn_create_group'.l10n,
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
                            key: const Key('SearchButton'),
                            onPressed: c.searching.value ? null : c.startSearch,
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

                        if (c.searching.value) {
                          child = WidgetButton(
                            key: const Key('CloseSearch'),
                            onPressed: c.groupCreating.value
                                ? () => c.closeSearch(false)
                                : () => c.closeSearch(true),
                            child: SizedBox(
                              width: 21.77,
                              child: SvgLoader.asset(
                                'assets/icons/close_primary.svg',
                                height: 15,
                              ),
                            ),
                          );
                        } else {
                          child = WidgetButton(
                            onPressed: c.groupCreating.value
                                ? c.closeGroupCreating
                                : c.startGroupCreating,
                            child: SizedBox(
                              width: 21.77,
                              child: c.groupCreating.value
                                  ? SvgLoader.asset(
                                      'assets/icons/close_primary.svg',
                                      height: 15,
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
                    final Widget? child;

                    if (c.groupCreating.value) {
                      Widget? center;

                      if (c.search.value?.query.isNotEmpty == true &&
                          c.search.value?.recent.isEmpty == true &&
                          c.search.value?.contacts.isEmpty == true &&
                          c.search.value?.users.isEmpty == true) {
                        if (c.search.value?.searchStatus.value.isSuccess ==
                            true) {
                          center =
                              Center(child: Text('label_nothing_found'.l10n));
                        } else {
                          center =
                              const Center(child: CircularProgressIndicator());
                        }
                      }

                      if (center != null) {
                        child = Padding(
                          padding: const EdgeInsets.only(top: 67),
                          child: center,
                        );
                      } else {
                        child = MobilePaddings(
                          bottomPadding: 0,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(40),
                          ),
                          context: context,
                          child: Scrollbar(
                            controller: c.search.value!.controller,
                            child: ListView.builder(
                              controller: c.search.value!.controller,
                              itemCount: c.elements.length,
                              itemBuilder: (context, i) {
                                final ListElement element = c.elements[i];
                                final Widget child;

                              if (element is RecentElement) {
                                child = Obx(() {
                                  return SelectedTile(
                                    user: element.user,
                                    selected: c.search.value?.selectedRecent
                                            .contains(element.user) ??
                                        false,
                                    onTap: () => c.search.value
                                        ?.select(recent: element.user),
                                  );
                                });
                              } else if (element is ContactElement) {
                                child = Obx(() {
                                  return SelectedTile(
                                    contact: element.contact,
                                    selected: c.search.value?.selectedContacts
                                            .contains(element.contact) ??
                                        false,
                                    onTap: () => c.search.value
                                       ?.select(contact: element.contact),
                                  );
                                });
                              } else if (element is UserElement) {
                                child = Obx(() {
                                  return SelectedTile(
                                    user: element.user,
                                    selected: c.search.value?.selectedUsers
                                            .contains(element.user) ??
                                        false,
                                    onTap: () => c.search.value
                                     ?.select(user: element.user),
                                  );
                                });
                              } else if (element is MyUserElement) {
                                child = Obx(() {
                                  return SelectedTile(
                                    myUser: c.myUser.value,
                                    selected: true,
                                    subtitle: [
                                      const SizedBox(height: 5),
                                      Text(
                                        'label_required'.l10n,
                                        style: TextStyle(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ],
                                  );
                                });
                              } else if (element is DividerElement) {
                                final String text;

                                  switch (element.category) {
                                    case SearchCategory.recent:
                                      text = 'label_recent'.l10n;
                                      break;

                                    case SearchCategory.contact:
                                      text = 'label_contact'.l10n;
                                      break;

                                    case SearchCategory.user:
                                      text = 'label_user'.l10n;
                                      break;

                                    case SearchCategory.chat:
                                      text = 'label_chat'.l10n;
                                      break;
                                  }

                                  child = Center(
                                    child: Container(
                                      margin: const EdgeInsets.fromLTRB(
                                        10,
                                        2,
                                        0,
                                        2,
                                      ),
                                      padding: const EdgeInsets.fromLTRB(
                                        12,
                                        10,
                                        0,
                                        6,
                                      ),
                                      width: double.infinity,
                                      child: Center(
                                        child: Text(
                                          text,
                                          style:
                                              style.systemMessageStyle.copyWith(
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

                                return child;
                              },
                            ),
                          ),
                        );
                      }
                    } else if (c.searching.value &&
                        c.search.value?.search.isEmpty.value == false) {
                      if (c.search.value!.searchStatus.value.isLoading &&
                          c.elements.isEmpty) {
                        child = const Center(
                          key: Key('Loading'),
                          child: CircularProgressIndicator(),
                        );
                      } else if (c.elements.isNotEmpty) {
                        child = MobilePaddings(
                          context: context,
                          child: Scrollbar(
                            controller: c.scrollController,
                            child: ListView.builder(
                              key: const Key('Search'),
                              controller: c.scrollController,
                              itemCount: c.elements.length,
                              itemBuilder: (_, i) {
                                final ListElement element = c.elements[i];
                                final Widget child;

                              if (element is ChatElement) {
                                final RxChat chat = element.chat;
                                child = Padding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                  ),
                                  child: Obx(() {
                                    return RecentChatTile(
                                      chat,
                                      key: Key('SearchChat_${chat.id}'),
                                      me: c.me,
                                      blocked: chat.blacklisted,
                                      getUser: c.getUser,
                                      onJoin: () => c.joinCall(chat.id),
                                      onDrop: () => c.dropCall(chat.id),
                                      inCall: () => c.inCall(chat.id),
                                    );
                                  }),
                                );
                              } else if (element is ContactElement) {
                                child = SearchUserTile(
                                  key: Key(
                                      'SearchContact_${element.contact.id}'),
                                  contact: element.contact,
                                  onTap: () =>
                                      c.openChat(contact: element.contact),
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
                                    margin:
                                        const EdgeInsets.fromLTRB(10, 2, 10, 2),
                                    padding: const EdgeInsets.fromLTRB(
                                        12, 10, 12, 6),
                                    width: double.infinity,
                                    child: Center(
                                      child: Text(
                                        element.category.name.capitalizeFirst!,
                                        style:
                                            style.systemMessageStyle.copyWith(
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
                                        bottom:
                                            i == c.elements.length - 1 ? 4 : 0,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      } else {
                        child = Center(
                          key: const Key('NothingFound'),
                          child: Text('label_nothing_found'.l10n),
                        );
                      }
                    } else {
                      child =  MobilePaddings(
                        context: context,
                        child:AnimationLimiter(
                        key: const Key('Chats'),
                        child: Scrollbar(
                          controller: c.scrollController,
                          child: ListView.builder(
                            controller: c.scrollController,
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
                                        horizontal: 10,
                                      ),
                                      child: Obx(() {
                                        return RecentChatTile(
                                        chat,
                                        key: Key('RecentChat_${chat.id}'),
                                        me: c.me,
                                        getUser: c.getUser,
                                         blocked: chat.blacklisted,
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
                                      );}),
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

                    return ContextMenuInterceptor(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: child,
                      ),
                    );
                  }

                  return const Center(child: CircularProgressIndicator());
                }),
                bottomNavigationBar:
                    c.groupCreating.value ? _createGroup(context, c) : null,
              );
            }),
            Obx(() {
              final Widget child;

              if (c.creatingStatus.value.isLoading) {
                child = Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: const Color(0x33000000),
                  child: const Center(child: CircularProgressIndicator()),
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

  /// Returns an animated [OutlinedRoundedButton]s for creating a group.
  Widget _createGroup(BuildContext context, ChatsTabController c) {
    return Obx(() {
      final Widget child;

      if (c.groupCreating.value) {
        Widget button({
          Key? key,
          Widget? leading,
          required Widget child,
          void Function()? onPressed,
          Color? color,
        }) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 7, bottom: 7),
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
                leading: leading,
                title: child,
                onPressed: onPressed,
                color: color ?? Colors.white,
              ),
            ),
          );
        }

        child = Container(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 5),
          child: Row(
            children: [
              button(
                child: Text(
                  'btn_close'.l10n,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.black),
                ),
                onPressed: c.closeGroupCreating,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              button(
                child: Text(
                  'btn_create_group'.l10n,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: c.createGroup,
                color: Theme.of(context).colorScheme.secondary,
              ),
            ],
          ),
        );
      } else {
        child = const SizedBox();
      }

      return AnimatedSwitcher(duration: 250.milliseconds, child: child);
    });
  }
}
