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

import 'dart:ui';

import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/page/home/page/my_profile/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/widget/animated_delayed_switcher.dart';
import 'package:messenger/ui/widget/animated_size_and_fade.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/util/message_popup.dart';

import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/my_profile/widget/field_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/selected_tile.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'widget/recent_chat.dart';
import 'widget/search_user_tile.dart';

/// View of the `HomeTab.chats` tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({super.key, this.onSwitched});

  final void Function()? onSwitched;

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;
    final ColorScheme colors = Theme.of(context).colorScheme;

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
              return AnimatedContainer(
                duration: 200.milliseconds,
                color: c.search.value != null || c.searching.value
                    ? style.colors.secondaryHighlight
                    : style.colors.transparent,
              );
            }),
            Obx(() {
              return Scaffold(
                extendBodyBehindAppBar: true,
                resizeToAvoidBottomInset: false,
                appBar: CustomAppBar(
                  border: (c.searching.value ||
                          c.search.value?.search.isFocused.value == true ||
                          c.search.value?.query.value.isNotEmpty == true)
                      ? Border.all(color: colors.secondary, width: 2)
                      : null,
                  // border: c.search.value != null || c.selecting.value
                  //     ? Border.all(color: colors.secondary, width: 2)
                  //     : null,
                  title: Obx(() {
                    final Widget child;

                    if (c.searching.value) {
                      child = Theme(
                        data: MessageFieldView.theme(context),
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
                      child = SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: Center(
                          child: Text(
                            'btn_create_group'.l10n,
                            key: const Key('1'),
                          ),
                        ),
                      );
                    } else if (c.selecting.value) {
                      child = Text(
                        'btn_select_and_delete'.l10n,
                        key: const Key('3'),
                      );
                    } else {
                      final Widget synchronization;

                      if (c.fetching.value == null &&
                          c.status.value.isLoadingMore) {
                        synchronization = Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Center(
                            child: Text(
                              'label_synchronization'.l10n,
                              style: TextStyle(
                                fontSize: 13,
                                color: style.colors.secondary,
                              ),
                            ),
                          ),
                        );
                      } else {
                        synchronization = const SizedBox.shrink();
                      }

                      child = Column(
                        key: const Key('2'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          WidgetButton(
                            onPressed: () {},
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              // crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'label_chats'.l10n,
                                  // style: TextStyle(
                                  //   color:
                                  //       Theme.of(context).colorScheme.primary,
                                  // ),
                                ),
                                // const SizedBox(width: 0),
                                // Transform.translate(
                                //   offset: const Offset(0, 2),
                                //   child: Icon(
                                //     Icons.more_horiz,
                                //     size: 16,
                                //     color:
                                //         Theme.of(context).colorScheme.primary,
                                //   ),
                                // )
                              ],
                            ),
                          ),
                          AnimatedSizeAndFade(
                            sizeDuration: const Duration(milliseconds: 300),
                            fadeDuration: const Duration(milliseconds: 300),
                            child: synchronization,
                          ),
                        ],
                      );
                    }

                    return AnimatedSwitcher(
                      duration: 250.milliseconds,
                      child: child,
                    );
                  }),
                  leading: [
                    Obx(() {
                      final bool selected = c.chats.where((e) {
                        final bool isHidden = e.chat.value.isHidden &&
                            !e.chat.value.isRoute(router.route, c.me);

                        return ((!e.id.isLocal ||
                                e.messages.isNotEmpty ||
                                e.chat.value.isMonolog) &&
                            !isHidden);
                      }).every(
                        (e) => c.selectedChats.any((m) => m == e.id),
                      );

                      if (c.selecting.value) {
                        return WidgetButton(
                          onPressed: () {
                            final List<RxChat> chats = [];

                            for (RxChat e in c.chats) {
                              final bool isHidden = e.chat.value.isHidden &&
                                  !e.chat.value.isRoute(router.route, c.me);

                              if ((!e.id.isLocal ||
                                      e.messages.isNotEmpty ||
                                      e.chat.value.isMonolog) &&
                                  !isHidden) {
                                chats.add(e);
                              }
                            }

                            bool selected = chats.every(
                              (e) => c.selectedChats.any((m) => m == e.id),
                            );

                            if (selected) {
                              c.selectedChats.clear();
                            } else {
                              for (var e in chats) {
                                if (!c.selectedChats.contains(e.id)) {
                                  c.selectChat(e);
                                }
                              }
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.only(left: 20, right: 6),
                            height: double.infinity,
                            // child: Icon(
                            //   Icons.more_horiz,
                            //   color: Theme.of(context).colorScheme.primary,
                            // ),
                            // child: Icon(
                            //   key: const Key('ArrowBack'),
                            //   Icons.select_all,
                            //   size: 20,
                            //   color: Theme.of(context).colorScheme.primary,
                            // ),
                            child: SelectedDot(
                              selected: selected,
                              inverted: false,
                              outlined: !selected,
                              size: 21,
                            ),
                          ),
                        );
                        return const SizedBox(width: 49.77);
                      }

                      return AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: WidgetButton(
                          key: c.searching.value
                              ? const Key('CloseSearchButton')
                              : const Key('SearchButton'),
                          onPressed:
                              c.searching.value ? c.closeSearch : c.startSearch,
                          child: Container(
                            padding: const EdgeInsets.only(
                              left: 20,
                              right: 6,
                            ),
                            height: double.infinity,
                            // child: Icon(
                            //   Icons.more_horiz,
                            //   color: Theme.of(context).colorScheme.primary,
                            // ),
                            child: c.searching.value
                                ? Icon(
                                    key: const Key('ArrowBack'),
                                    Icons.arrow_back_ios_new,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  )
                                : SvgImage.asset(
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
                      Widget? child;

                      if (c.searching.value) {
                        if (c.search.value?.search.isEmpty.value == false) {
                          child = SvgImage.asset(
                            'assets/icons/search_exit.svg',
                            key: const Key('CloseSearch'),
                            height: 11,
                          );
                        } else {
                          child = null;
                        }
                      } else {
                        child = c.groupCreating.value || c.selecting.value
                            ? SvgImage.asset(
                                c.searching.value
                                    ? 'assets/icons/search_exit.svg'
                                    : 'assets/icons/close_primary.svg',
                                key: const Key('CloseGroupSearching'),
                                height: c.searching.value ? 11 : 15,
                              )
                            : Transform.translate(
                                offset: const Offset(-1, 0),
                                child: SvgImage.asset(
                                  'assets/icons/contacts_switch.svg',
                                  key: const Key('Contacts'),
                                  alignment: Alignment.center,
                                  width: 22.4,
                                  height: 20.8,
                                ),
                              );
                      }

                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (child != null)
                            WidgetButton(
                              key: c.searching.value
                                  ? const Key('CloseSearchButton')
                                  : null,
                              onPressed: () {
                                if (c.searching.value) {
                                  if (c.search.value?.search.isEmpty.value ==
                                      false) {
                                    c.search.value?.search.clear();
                                    c.search.value?.query.value = '';
                                    c.search.value?.search.focus.requestFocus();
                                  }
                                } else if (c.selecting.value) {
                                  c.toggleSelecting();
                                } else if (c.groupCreating.value) {
                                  c.closeGroupCreating();
                                } else {
                                  if (onSwitched != null) {
                                    onSwitched?.call();
                                  } else {
                                    c.startGroupCreating();
                                  }
                                }
                              },
                              child: Container(
                                padding: EdgeInsets.only(
                                  left: 12,
                                  right: !c.searching.value &&
                                          !c.groupCreating.value &&
                                          !c.selecting.value
                                      ? 8
                                      : 16,
                                ),
                                height: double.infinity,
                                child: SizedBox(
                                  width: 29.17,
                                  child: AnimatedSwitcher(
                                    duration: 250.milliseconds,
                                    child: child,
                                  ),
                                ),
                                // child: SizedBox(
                                //   // width: 21.77,
                                //   child: AnimatedSizeAndFade(
                                //     fadeDuration: 250.milliseconds,
                                //     sizeDuration: 250.milliseconds,
                                //     child: child,
                                //   ),
                                // ),
                              ),
                            ),
                          if (!c.searching.value &&
                              !c.groupCreating.value &&
                              !c.selecting.value)
                            ContextMenuRegion(
                              selector: c.moreKey,
                              alignment: Alignment.topRight,
                              allowPrimaryButton: true,
                              margin:
                                  const EdgeInsets.only(bottom: 4, right: 0),
                              actions: [
                                ContextMenuButton(
                                  label: 'btn_create_group'.l10n,
                                  onPressed: c.startGroupCreating,
                                  // trailing: const Icon(Icons.group_outlined),
                                ),
                                ContextMenuButton(
                                  key: const Key('SelectChatButton'),
                                  label: 'btn_select_and_delete'.l10n,
                                  onPressed: c.toggleSelecting,
                                  // trailing: const Icon(Icons.select_all),
                                ),
                              ],
                              child: Container(
                                key: c.moreKey,
                                padding:
                                    const EdgeInsets.only(left: 12, right: 18),
                                height: double.infinity,
                                child: Icon(
                                  Icons.more_vert,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      );
                    }),
                  ],
                ),
                body: Obx(() {
                  if (c.status.value.isLoading) {
                    return const Center(child: CustomProgressIndicator());
                  }

                  final Widget? child;

                  if (c.groupCreating.value) {
                    Widget? center;

                    if (c.search.value?.query.isNotEmpty == true &&
                        c.search.value?.recent.isEmpty == true &&
                        c.search.value?.contacts.isEmpty == true &&
                        c.search.value?.users.isEmpty == true) {
                      if (c.search.value?.searchStatus.value.isSuccess ==
                          true) {
                        center = Center(
                          key: UniqueKey(),
                          child: Text('label_nothing_found'.l10n),
                        );
                      } else {
                        center = Center(
                          key: UniqueKey(),
                          child: const ColoredBox(
                            color: Colors.transparent,
                            child: CustomProgressIndicator(),
                          ),
                        );
                      }
                    }

                    if (center != null) {
                      child = Padding(
                        key: UniqueKey(),
                        padding: const EdgeInsets.only(top: 67),
                        child: center,
                      );
                    } else {
                      child = SafeScrollbar(
                        bottom: false,
                        controller: c.search.value!.controller,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(40),
                        ),
                        child: ListView.builder(
                          key: const Key('GroupCreating'),
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
                                        color: style.colors.onPrimary,
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
                                  child: Center(
                                    child: Text(
                                      text,
                                      style: style.systemMessageStyle.copyWith(
                                        color: style.colors.onBackground,
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
                      );
                    }
                  } else if (c.searching.value &&
                      c.search.value?.search.isEmpty.value == false) {
                    if (c.search.value!.searchStatus.value.isLoading &&
                        c.elements.isEmpty) {
                      child = Center(
                        key: UniqueKey(),
                        child: ColoredBox(
                          key: const Key('Loading'),
                          color: style.colors.transparent,
                          child: const CustomProgressIndicator(),
                        ),
                      );
                    } else if (c.elements.isNotEmpty) {
                      child = SafeScrollbar(
                        controller: c.scrollController,
                        child: AnimationLimiter(
                          key: const Key('Search'),
                          child: ListView.builder(
                            key: const Key('SearchScrollable'),
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
                                      myUser: c.myUser.value,
                                      blocked: chat.blacklisted,
                                      getUser: c.getUser,
                                      onJoin: () => c.joinCall(chat.id),
                                      onDrop: () => c.dropCall(chat.id),
                                      inCall: () => c.inCall(chat.id),
                                      onTap: c.selecting.value
                                          ? () => c.selectChat(chat)
                                          : null,
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
                                          color: style.colors.onBackground,
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
                                      child: child,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    } else {
                      child = AnimatedDelayedSwitcher(
                        key: UniqueKey(),
                        delay: const Duration(milliseconds: 300),
                        child: Center(
                          key: const Key('NothingFound'),
                          child: Text('label_nothing_found'.l10n),
                        ),
                      );
                    }
                  } else {
                    if (c.chats.none(
                      (e) {
                        final bool isHidden = e.chat.value.isHidden &&
                            !e.chat.value.isRoute(router.route, c.me);

                        return (!e.id.isLocal || e.chat.value.isMonolog) &&
                            !isHidden;
                      },
                    )) {
                      if (c.status.value.isLoadingMore) {
                        child = Center(
                          key: UniqueKey(),
                          child: ColoredBox(
                            key: const Key('Loading'),
                            color: style.colors.transparent,
                            child: const CustomProgressIndicator(),
                          ),
                        );
                      } else {
                        child = KeyedSubtree(
                          key: UniqueKey(),
                          child: Center(
                            key: const Key('NoChats'),
                            child: Text('label_no_chats'.l10n),
                          ),
                        );
                      }
                    } else {
                      child = SafeScrollbar(
                        controller: c.scrollController,
                        child: AnimationLimiter(
                          key: const Key('Chats'),
                          child: Obx(() {
                            // final List<ListElement> elements = c.chats
                            //     .where((e) =>
                            //         (e is ChatElement &&
                            //             (!e.chat.id.isLocal ||
                            //                 e.chat.messages.isNotEmpty)) ||
                            //         e is! ChatElement)
                            //     .toList();

                            final List<RxChat> calls = [];
                            final List<RxChat> favorites = [];
                            final List<RxChat> chats = [];

                            for (RxChat e in c.chats) {
                              final bool isHidden = e.chat.value.isHidden &&
                                  !e.chat.value.isRoute(router.route, c.me);

                              if ((!e.id.isLocal ||
                                      e.messages.isNotEmpty ||
                                      e.chat.value.isMonolog) &&
                                  !isHidden) {
                                if (e.chat.value.ongoingCall != null) {
                                  calls.add(e);
                                } else if (e.chat.value.favoritePosition !=
                                    null) {
                                  favorites.add(e);
                                } else {
                                  chats.add(e);
                                }
                              }
                            }

                            // Builds a [RecentChatTile] from the provided
                            // [RxChat].
                            Widget tile(
                              RxChat e, {
                              Widget Function(Widget)? avatarBuilder,
                            }) {
                              final bool selected =
                                  c.selectedChats.contains(e.id);

                              return Obx(() {
                                return RecentChatTile(
                                  e,
                                  key: Key('RecentChat_${e.id}'),
                                  me: c.me,
                                  myUser: c.myUser.value,
                                  blocked: e.blacklisted,
                                  selected: selected,
                                  getUser: c.getUser,
                                  avatarBuilder: c.selecting.value
                                      ? (c) => WidgetButton(
                                            onPressed: () => router.chat(e.id),
                                            child: c,
                                          )
                                      : avatarBuilder,
                                  onJoin: () => c.joinCall(e.id),
                                  onDrop: () => c.dropCall(e.id),
                                  onLeave: () => c.leaveChat(e.id),
                                  onHide: () => c.hideChat(e.id),
                                  inCall: () => c.inCall(e.id),
                                  onMute: () => c.muteChat(e.id),
                                  onUnmute: () => c.unmuteChat(e.id),
                                  onFavorite: () => c.favoriteChat(e.id),
                                  onUnfavorite: () => c.unfavoriteChat(e.id),
                                  onSelect: c.toggleSelecting,
                                  onCreateGroup: c.startGroupCreating,
                                  onTap: c.selecting.value
                                      ? () => c.selectChat(e)
                                      : null,
                                  enableContextMenu: !c.selecting.value,
                                  trailing: c.selecting.value
                                      ? [
                                          SelectedDot(
                                            selected: selected,
                                            size: 20,
                                          )
                                        ]
                                      : null,
                                );
                              });
                            }

                            final Widget search = Container(
                              // color: Colors.red,
                              width: double.infinity,
                              height: 40,
                              margin: const EdgeInsets.fromLTRB(0, 1, 0, 1),
                              child: CustomAppBar(
                                safeArea: false,
                                margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                                shadow: false,
                                border: c.search2.search.isFocused.value
                                    ? Border.all(
                                        color: colors.secondary,
                                        width: 2,
                                      )
                                    : null,
                                title: Theme(
                                  data: MessageFieldView.theme(context),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    child: Transform.translate(
                                      offset: const Offset(0, 1),
                                      child: ReactiveTextField(
                                        key: const Key('SearchField'),
                                        state: c.search2.search,
                                        hint: 'label_search'.l10n,
                                        maxLines: 1,
                                        filled: false,
                                        dense: true,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                        ),
                                        style: style.boldBody
                                            .copyWith(fontSize: 15),
                                        onChanged: () => c.search2.query.value =
                                            c.search2.search.text,
                                      ),
                                    ),
                                  ),
                                ),
                                leading: [
                                  WidgetButton(
                                    key: const Key('SearchButton'),
                                    onPressed: c.searching.value
                                        ? null
                                        : c.startSearch,
                                    child: Container(
                                      padding: const EdgeInsets.only(
                                        left: 20,
                                        right: 12,
                                      ),
                                      height: double.infinity,
                                      child: SvgImage.asset(
                                        'assets/icons/search_14.svg',
                                        // width: 17.77,
                                        height: 13.5,
                                      ),
                                    ),
                                  )
                                ],
                                actions: [
                                  Obx(() {
                                    final Widget child;

                                    if (c.search2.search.isEmpty.value) {
                                      child = const SizedBox();
                                    } else {
                                      child = WidgetButton(
                                        key: const Key('CloseSearchButton'),
                                        onPressed: () {
                                          c.search2.search.clear();
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            right: 18,
                                          ),
                                          height: double.infinity,
                                          child: SvgImage.asset(
                                            'assets/icons/close_primary.svg',
                                            key: const Key('CloseSearch'),
                                            height: 12,
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
                            );

                            return CustomScrollView(
                              controller: c.scrollController,
                              slivers: [
                                // SliverPadding(
                                //   padding: const EdgeInsets.only(
                                //     top: CustomAppBar.height,
                                //     left: 10,
                                //     right: 10,
                                //     bottom: 2,
                                //   ),
                                //   sliver: SliverToBoxAdapter(
                                //     child: search,
                                //   ),
                                // ),
                                SliverPadding(
                                  padding: const EdgeInsets.only(
                                    top: CustomAppBar.height,
                                    left: 10,
                                    right: 10,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildListDelegate.fixed(
                                      calls.mapIndexed((i, e) {
                                        return AnimationConfiguration
                                            .staggeredList(
                                          position: i,
                                          duration: const Duration(
                                            milliseconds: 375,
                                          ),
                                          child: SlideAnimation(
                                            horizontalOffset: 50,
                                            child: FadeInAnimation(
                                              child: tile(e),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.only(
                                    left: 10,
                                    right: 10,
                                  ),
                                  sliver: SliverReorderableList(
                                    onReorderStart: (_) =>
                                        c.reordering.value = true,
                                    proxyDecorator: (child, _, animation) {
                                      return AnimatedBuilder(
                                        animation: animation,
                                        builder: (_, Widget? child) {
                                          final double t = Curves.easeInOut
                                              .transform(animation.value);
                                          final double elevation =
                                              lerpDouble(0, 6, t)!;
                                          final Color color = Color.lerp(
                                            style.colors.transparent,
                                            style.colors.onBackgroundOpacity20,
                                            t,
                                          )!;

                                          return Container(
                                            decoration: BoxDecoration(
                                              boxShadow: [
                                                CustomBoxShadow(
                                                  color: color,
                                                  blurRadius: elevation,
                                                ),
                                              ],
                                              borderRadius:
                                                  style.cardRadius.copyWith(
                                                topLeft: Radius.circular(
                                                  style.cardRadius.topLeft.x *
                                                      1.75,
                                                ),
                                              ),
                                            ),
                                            child: child,
                                          );
                                        },
                                        child: child,
                                      );
                                    },
                                    itemBuilder: (_, i) {
                                      final RxChat chat = favorites[i];

                                      return KeyedSubtree(
                                        key: Key(chat.id.val),
                                        child: Obx(() {
                                          final Widget child = tile(
                                            chat,
                                            avatarBuilder: (child) {
                                              if (PlatformUtils.isMobile) {
                                                return ReorderableDelayedDragStartListener(
                                                  key: Key(
                                                    'ReorderHandle_${chat.id.val}',
                                                  ),
                                                  index: i,
                                                  child: child,
                                                );
                                              }

                                              return RawGestureDetector(
                                                gestures: {
                                                  DisableSecondaryButtonRecognizer:
                                                      GestureRecognizerFactoryWithHandlers<
                                                          DisableSecondaryButtonRecognizer>(
                                                    () =>
                                                        DisableSecondaryButtonRecognizer(),
                                                    (_) {},
                                                  ),
                                                },
                                                child:
                                                    ReorderableDragStartListener(
                                                  key: Key(
                                                    'ReorderHandle_${chat.id.val}',
                                                  ),
                                                  index: i,
                                                  child: GestureDetector(
                                                    onLongPress: () {},
                                                    child: child,
                                                  ),
                                                ),
                                              );
                                            },
                                          );

                                          // Ignore the animation, if there's
                                          // an ongoing reordering happening.
                                          if (c.reordering.value) {
                                            return child;
                                          }

                                          return AnimationConfiguration
                                              .staggeredList(
                                            position: i,
                                            duration: const Duration(
                                              milliseconds: 375,
                                            ),
                                            child: SlideAnimation(
                                              horizontalOffset: 50,
                                              child: FadeInAnimation(
                                                child: child,
                                              ),
                                            ),
                                          );
                                        }),
                                      );
                                    },
                                    itemCount: favorites.length,
                                    onReorder: (a, b) {
                                      c.reorderChat(a, b);
                                      c.reordering.value = false;
                                    },
                                  ),
                                ),
                                SliverPadding(
                                  padding: const EdgeInsets.only(
                                    bottom: CustomNavigationBar.height + 5,
                                    left: 10,
                                    right: 10,
                                  ),
                                  sliver: SliverList(
                                    delegate: SliverChildListDelegate.fixed(
                                      chats.mapIndexed((i, e) {
                                        return AnimationConfiguration
                                            .staggeredList(
                                          position: i,
                                          duration: const Duration(
                                            milliseconds: 375,
                                          ),
                                          child: SlideAnimation(
                                            horizontalOffset: 50,
                                            child: FadeInAnimation(
                                              child: tile(e),
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      );
                    }
                  }

                  return ContextMenuInterceptor(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: child,
                    ),
                  );
                }),
                bottomNavigationBar: c.groupCreating.value
                    ? _createGroup(context, c)
                    : c.selecting.value
                        ? _selectButtons(context, c)
                        : null,
              );
            }),
            Obx(() {
              final Widget child;

              if (c.creatingStatus.value.isLoading) {
                child = Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: style.colors.onBackgroundOpacity20,
                  child: const Center(child: CustomProgressIndicator()),
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
    final Style style = Theme.of(context).extension<Style>()!;

    Widget button({
      Key? key,
      Widget? leading,
      required Widget child,
      void Function()? onPressed,
      Color? color,
    }) {
      return Expanded(
        child: OutlinedRoundedButton(
          key: key,
          leading: leading,
          title: child,
          onPressed: onPressed,
          color: color,
          shadows: [
            CustomBoxShadow(
              blurRadius: 8,
              color: style.colors.onBackgroundOpacity13,
              blurStyle: BlurStyle.outer,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        7,
        8,
        PlatformUtils.isMobile && !PlatformUtils.isWeb
            ? router.context!.mediaQuery.padding.bottom + 7
            : 12,
      ),
      child: Row(
        children: [
          button(
            child: Text(
              'btn_cancel'.l10n,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: style.colors.onBackground),
            ),
            onPressed: c.closeGroupCreating,
            color: style.colors.onPrimary,
          ),
          const SizedBox(width: 10),
          button(
            child: Text(
              'btn_create_group'.l10n,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(color: style.colors.onPrimary),
            ),
            onPressed: c.createGroup,
            color: style.colors.primary,
          ),
        ],
      ),
    );
  }

  /// Returns the animated [OutlinedRoundedButton]s for multiple selected
  /// [Chat]s manipulation.
  Widget _selectButtons(BuildContext context, ChatsTabController c) {
    final Style style = Theme.of(context).extension<Style>()!;

    List<CustomBoxShadow> shadows = [
      CustomBoxShadow(
        blurRadius: 8,
        color: style.colors.onBackgroundOpacity13,
        blurStyle: BlurStyle.outer,
      ),
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        8,
        7,
        8,
        PlatformUtils.isMobile && !PlatformUtils.isWeb
            ? router.context!.mediaQuery.padding.bottom + 7
            : 12,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedRoundedButton(
              title: Text(
                'btn_cancel'.l10n,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(color: style.colors.onBackground),
              ),
              onPressed: c.toggleSelecting,
              shadows: shadows,
            ),
          ),
          const SizedBox(width: 10),
          Obx(() {
            return Expanded(
              child: OutlinedRoundedButton(
                key: const Key('DeleteChats'),
                title: Text(
                  'btn_delete_count'.l10nfmt({'count': c.selectedChats.length}),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: TextStyle(
                    color: c.selectedChats.isEmpty
                        ? style.colors.onBackground
                        : style.colors.onPrimary,
                  ),
                ),
                onPressed: c.selectedChats.isEmpty
                    ? null
                    : () => _hideChats(context, c),
                color: style.colors.primary,
                shadows: shadows,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Opens a confirmation popup hiding the selected chats.
  Future<void> _hideChats(BuildContext context, ChatsTabController c) async {
    bool clear = false;

    final bool? result = await MessagePopup.alert(
      'label_delete_chats'.l10n,
      description: [
        TextSpan(
          text: 'alert_chats_will_be_deleted'
              .l10nfmt({'count': c.selectedChats.length}),
        ),
      ],
      additional: [
        const SizedBox(height: 21),
        StatefulBuilder(builder: (context, setState) {
          return FieldButton(
            text: 'btn_clear_history'.l10n,
            onPressed: () => setState(() => clear = !clear),
            trailing: SelectedDot(selected: clear, size: 22, inverted: false),
          );
        })
      ],
    );

    if (result == true) {
      await c.hideChats(clear);
    }
  }
}

/// [OneSequenceGestureRecognizer] rejecting the secondary mouse button events.
class DisableSecondaryButtonRecognizer extends OneSequenceGestureRecognizer {
  @override
  String get debugDescription => 'DisableSecondaryButtonRecognizer';

  @override
  void didStopTrackingLastPointer(int pointer) {
    // No-op.
  }

  @override
  void handleEvent(PointerEvent event) {
    // No-op.
  }

  @override
  void addAllowedPointer(PointerDownEvent event) {
    startTrackingPointer(event.pointer);

    if (event.buttons == kPrimaryButton) {
      resolve(GestureDisposition.rejected);
    } else {
      resolve(GestureDisposition.accepted);
    }
  }
}
