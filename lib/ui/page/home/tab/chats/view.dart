// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/config.dart';
import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/bottom_padded_row.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/widget/allow_overflow.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/selected_tile.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import '/util/recognizers.dart';
import 'controller.dart';
import 'widget/recent_chat.dart';
import 'widget/search_user_tile.dart';

/// View of the [HomeTab.chats] tab.
class ChatsTabView extends StatelessWidget {
  const ChatsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      key: const Key('ChatsTab'),
      init: ChatsTabController(
        Get.find(),
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
                    : style.colors.secondaryHighlight.withValues(alpha: 0),
              );
            }),
            Obx(() {
              return Scaffold(
                resizeToAvoidBottomInset: false,
                body: Scrollbar(
                  controller: c.scrollController,
                  child: CustomScrollView(
                    controller: c.scrollController,
                    slivers: [
                      SliverAppBar(
                        pinned: true,
                        floating: true,
                        title: CustomAppBar(
                          title: Row(
                            children: [
                              if (c.groupCreating.value)
                                Text('label_create_group'.l10n)
                              else if (c.selecting.value)
                                Text(
                                  'label_selected'.l10nfmt({
                                    'count': c.selectedChats.length,
                                  }),
                                )
                              else
                                Text('label_chats'.l10n),
                              AnimatedButton(
                                key: c.searching.value
                                    ? const Key('HideSearchButton')
                                    : const Key('ShowSearchButton'),
                                onPressed: c.searching.value
                                    ? () =>
                                          c.closeSearch(c.groupCreating.isFalse)
                                    : () => c.startSearch(),
                                decorator: (child) {
                                  return Container(
                                    padding: const EdgeInsets.only(
                                      left: 20,
                                      right: 6,
                                    ),
                                    width: 46,
                                    height: double.infinity,
                                    child: child,
                                  );
                                },
                                child: Center(
                                  child: Icon(
                                    c.searching.value
                                        ? Icons.keyboard_arrow_up
                                        : Icons.keyboard_arrow_down,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            Obx(() {
                              final Widget moreButton = ContextMenuRegion(
                                key: const Key('ChatsMenu'),
                                selector: c.moreKey,
                                alignment: Alignment.topRight,
                                enablePrimaryTap: true,
                                enableSecondaryTap: false,
                                enableLongTap: false,
                                margin: const EdgeInsets.only(
                                  bottom: 4,
                                  right: 0,
                                ),
                                actions: [
                                  ContextMenuButton(
                                    key: const Key('SelectChatsButton'),
                                    label: 'btn_select'.l10n,
                                    onPressed: c.toggleSelecting,
                                    trailing: const SvgIcon(SvgIcons.select),
                                    inverted: const SvgIcon(
                                      SvgIcons.selectWhite,
                                    ),
                                  ),
                                  ContextMenuButton(
                                    label: 'btn_create_group'.l10n,
                                    onPressed: c.startGroupCreating,
                                    trailing: const SvgIcon(SvgIcons.group),
                                    inverted: const SvgIcon(
                                      SvgIcons.groupWhite,
                                    ),
                                  ),
                                  ContextMenuDivider(),
                                  ContextMenuButton(
                                    label: 'label_chat_monolog'.l10n,
                                    onPressed: () => router.chat(c.monolog),
                                    trailing: const SvgIcon(
                                      SvgIcons.notesSmall,
                                    ),
                                    inverted: const SvgIcon(
                                      SvgIcons.notesSmallWhite,
                                    ),
                                  ),
                                ],
                                child: AnimatedButton(
                                  decorator: (child) {
                                    return Container(
                                      key: c.moreKey,
                                      padding: const EdgeInsets.only(
                                        left: 12,
                                        right: 18,
                                      ),
                                      height: double.infinity,
                                      child: Padding(
                                        padding: const EdgeInsets.fromLTRB(
                                          10,
                                          0,
                                          10,
                                          0,
                                        ),
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: const SvgIcon(SvgIcons.more),
                                ),
                              );

                              final Widget closeButton = AnimatedButton(
                                key: const Key('CloseSelectingButton'),
                                onPressed: () {
                                  if (c.selecting.value) {
                                    c.toggleSelecting();
                                  } else if (c.groupCreating.value) {
                                    c.closeGroupCreating();
                                  }
                                },
                                decorator: (child) {
                                  return Container(
                                    padding: const EdgeInsets.only(
                                      left: 9,
                                      right: 16,
                                    ),
                                    height: double.infinity,
                                    child: child,
                                  );
                                },
                                child: SizedBox(
                                  width: 29.17,
                                  child: SafeAnimatedSwitcher(
                                    duration: 250.milliseconds,
                                    child: const SvgIcon(
                                      SvgIcons.closePrimary,
                                      key: Key('CloseSearch'),
                                    ),
                                  ),
                                ),
                              );

                              return Row(
                                children: [
                                  if (c.selecting.value ||
                                      c.groupCreating.value)
                                    closeButton
                                  else
                                    moreButton,
                                ],
                              );
                            }),
                          ],
                        ),
                        expandedHeight: 110,
                        flexibleSpace: FlexibleSpaceBar(
                          collapseMode: CollapseMode.parallax,
                          background: Obx(() {
                            final Widget? searchField = c.search.value == null
                                ? null
                                : Theme(
                                    data: MessageFieldView.theme(context),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: Transform.translate(
                                        offset: const Offset(0, 1),
                                        child: ReactiveTextField(
                                          key: const Key('SearchField'),
                                          prefix: Icon(Icons.search),
                                          state: c.search.value!.search,
                                          hint: 'label_search'.l10n,
                                          maxLines: 1,
                                          style: style
                                              .fonts
                                              .medium
                                              .regular
                                              .onBackground,
                                          onChanged: () =>
                                              c.search.value!.query.value =
                                                  c.search.value!.search.text,
                                        ),
                                      ),
                                    ),
                                  );

                            final Widget synchronization;

                            if (!c.connected.value) {
                              synchronization = Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Center(
                                  child: Text(
                                    'label_waiting_for_connection'.l10n,
                                    style: style.fonts.small.regular.secondary,
                                    key: const Key('NotConnected'),
                                  ),
                                ),
                              );
                            } else if (c.fetching.value == null &&
                                c.status.value.isLoadingMore) {
                              synchronization = Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Center(
                                  child: Text(
                                    'label_synchronization'.l10n,
                                    style: style.fonts.small.regular.secondary,
                                    key: const Key('Synchronization'),
                                  ),
                                ),
                              );
                            } else {
                              synchronization = const SizedBox.shrink(
                                key: Key('Connected'),
                              );
                            }

                            return ColoredBox(
                              color: Colors.red,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  searchField ?? SizedBox(),
                                  SafeAnimatedSwitcher(
                                    duration: 250.milliseconds,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: AllowOverflow(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            AnimatedSizeAndFade(
                                              sizeDuration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              fadeDuration: const Duration(
                                                milliseconds: 300,
                                              ),
                                              child: synchronization,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      Obx(() {
                        final Widget? child;

                        if (c.status.value.isLoading) {
                          child = Center(
                            child: CustomProgressIndicator.primary(),
                          );
                        } else if (c.groupCreating.isTrue) {
                          child = _groupCreating(context, c);
                        } else if (c.searching.value &&
                            c.search.value?.search.isEmpty.value == false) {
                          child = _searchResult(context, c);
                        } else {
                          return _chats(context, c);
                        }

                        return SliverFillRemaining(
                          child: ContextMenuInterceptor(
                            margin: const EdgeInsets.fromLTRB(0, 64, 0, 0),
                            child: SlidableAutoCloseBehavior(
                              child: SafeAnimatedSwitcher(
                                duration: const Duration(milliseconds: 250),
                                child: child,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
            Positioned(
              left: 0,
              right: 0,
              bottom: 72,
              child: Obx(() {
                final action = c.dismissed.lastOrNull;

                if (action != null) {
                  return SafeAnimatedSwitcher(
                    duration: 200.milliseconds,
                    child: Padding(
                      key: Key('Dismissed_${action.chat.id}'),
                      padding: EdgeInsets.fromLTRB(
                        10,
                        0,
                        10,
                        MediaQuery.of(context).viewPadding.bottom,
                      ),
                      child: WidgetButton(
                        key: const Key('Restore'),
                        onPressed: action.cancel,
                        child: Container(
                          key: Key('${action.chat.id}'),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: style.colors.primary.withValues(alpha: .9),
                            boxShadow: [
                              CustomBoxShadow(
                                blurRadius: 8,
                                color: style.colors.onBackgroundOpacity13,
                                blurStyle: BlurStyle.outer.workaround,
                              ),
                            ],
                          ),
                          height: CustomNavigationBar.height,
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          child: Stack(
                            alignment: Alignment.centerLeft,
                            children: [
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      value: action.remaining.value / 5000,
                                      color: style.colors.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  Text(
                                    '${action.remaining.value ~/ 1000 + 1}',
                                    style: style.fonts.small.regular.onPrimary,
                                  ),
                                ],
                              ),
                              Center(
                                child: Text(
                                  'btn_cancel'.l10n,
                                  style: style.fonts.medium.regular.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return const SizedBox(key: Key('NoDismissed'));
              }),
            ),
            Obx(() {
              if (c.creatingStatus.value.isLoading) {
                return SafeAnimatedSwitcher(
                  duration: 200.milliseconds,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    color: style.colors.onBackgroundOpacity20,
                    child: const Center(child: CustomProgressIndicator()),
                  ),
                );
              }

              return const SizedBox();
            }),
          ],
        );
      },
    );
  }

  /// Todo: add docs
  Widget _searchResult(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;
    final RxStatus? searchStatus = c.search.value?.searchStatus.value;

    if (((searchStatus?.isLoading ?? false) ||
            (searchStatus?.isLoadingMore ?? false)) &&
        c.elements.isEmpty) {
      return Center(
        key: UniqueKey(),
        child: ColoredBox(
          key: const Key('Loading'),
          color: style.colors.almostTransparent,
          child: const CustomProgressIndicator(),
        ),
      );
    }

    if (c.elements.isEmpty) {
      return AnimatedDelayedSwitcher(
        key: UniqueKey(),
        delay: const Duration(milliseconds: 300),
        child: Center(
          key: const Key('NothingFound'),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'label_nothing_found'.l10n,
              style: style.fonts.small.regular.onBackground,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scrollbar(
      controller: c.search.value!.scrollController,
      child: AnimationLimiter(
        key: const Key('Search'),
        child: ListView.builder(
          key: const Key('SearchScrollable'),
          controller: c.search.value!.scrollController,
          itemCount: c.elements.length,
          itemBuilder: (_, i) {
            final ListElement element = c.elements[i];
            Widget child;

            if (element is ChatElement) {
              final RxChat chat = element.chat;
              child = Padding(
                padding: const EdgeInsets.only(left: 10, right: 10),
                child: Obx(() {
                  return RecentChatTile(
                    chat,
                    key: Key('SearchChat_${chat.id}'),
                    me: c.me,
                    blocked: chat.blocked,
                    getUser: c.getUser,
                    onJoin: () => c.joinCall(chat.id),
                    onDrop: () => c.dropCall(chat.id),
                    hasCall: c.status.value.isLoadingMore ? false : null,
                    onPerformDrop: (e) => c.sendFiles(chat.id, e),
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
              child = Container(
                margin: EdgeInsets.fromLTRB(8, i == 0 ? 0 : 8, 8, 3),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                width: double.infinity,
                child: Center(
                  child: Text(
                    element.category.name.capitalized,
                    style: style.fonts.normal.regular.onBackground,
                  ),
                ),
              );
            } else {
              child = const SizedBox();
            }

            if (i == c.elements.length - 1) {
              if ((searchStatus?.isLoadingMore ?? false) ||
                  (searchStatus?.isLoading ?? false)) {
                child = Column(
                  children: [
                    child,
                    const CustomProgressIndicator(key: Key('SearchLoading')),
                  ],
                );
              }
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
      ),
    );
  }

  /// Todo: add docs
  Widget _groupCreating(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;
    final RxStatus? searchStatus = c.search.value?.searchStatus.value;

    if (c.search.value?.query.isNotEmpty == true &&
        c.search.value?.recent.isEmpty == true &&
        c.search.value?.contacts.isEmpty == true &&
        c.search.value?.users.isEmpty == true) {
      if ((searchStatus?.isSuccess ?? false) &&
          !(searchStatus?.isLoadingMore ?? false)) {
        return Center(
          key: UniqueKey(),
          child: Text(
            'label_nothing_found'.l10n,
            style: style.fonts.small.regular.onBackground,
          ),
        );
      }

      return Center(
        key: UniqueKey(),
        child: ColoredBox(
          color: style.colors.almostTransparent,
          child: const CustomProgressIndicator(),
        ),
      );
    }

    return Scrollbar(
      controller: c.search.value!.scrollController,
      child: ListView.builder(
        key: const Key('GroupCreating'),
        controller: c.search.value!.scrollController,
        itemCount: c.elements.length,
        itemBuilder: (context, i) {
          final ListElement element = c.elements[i];
          Widget child;

          if (element is RecentElement) {
            child = Obx(() {
              return SelectedTile(
                user: element.user,
                selected:
                    c.search.value?.selectedRecent.contains(element.user) ??
                    false,
                onTap: () => c.search.value?.select(recent: element.user),
              );
            });
          } else if (element is ContactElement) {
            child = Obx(() {
              return SelectedTile(
                contact: element.contact,
                selected:
                    c.search.value?.selectedContacts.contains(
                      element.contact,
                    ) ??
                    false,
                onTap: () => c.search.value?.select(contact: element.contact),
              );
            });
          } else if (element is UserElement) {
            child = Obx(() {
              return SelectedTile(
                user: element.user,
                selected:
                    c.search.value?.selectedUsers.contains(element.user) ??
                    false,
                onTap: () => c.search.value?.select(user: element.user),
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
                    'label_you'.l10n,
                    style: style.fonts.small.regular.onPrimary,
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
                text = 'label_user'.l10n;
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
                margin: const EdgeInsets.fromLTRB(0, 2, 0, 2),
                padding: const EdgeInsets.fromLTRB(0, 10, 0, 6),
                width: double.infinity,
                child: Center(
                  child: Text(
                    text,
                    style: style.fonts.normal.regular.onBackground,
                  ),
                ),
              ),
            );
          } else {
            child = const SizedBox();
          }

          if (i == c.elements.length - 1 &&
              ((searchStatus?.isLoadingMore ?? false) ||
                  (searchStatus?.isLoading ?? false))) {
            child = Column(children: [child, const CustomProgressIndicator()]);
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
            child: child,
          );
        },
      ),
    );
  }

  /// Todo: add docs
  Widget _chats(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;

    final bool isCheck = c.chats.none((e) {
      return (!e.id.isLocal || e.chat.value.isMonolog) &&
          !e.chat.value.isHidden &&
          !e.hidden.value;
    });

    if (isCheck) {
      if (c.status.value.isLoadingMore) {
        return SliverFillRemaining(
          child: Center(
            key: UniqueKey(),
            child: ColoredBox(
              key: const Key('Loading'),
              color: style.colors.almostTransparent,
              child: const CustomProgressIndicator(),
            ),
          ),
        );
      }

      return SliverFillRemaining(
        child: KeyedSubtree(
          key: UniqueKey(),
          child: Center(
            key: const Key('NoChats'),
            child: Text('label_no_chats'.l10n),
          ),
        ),
      );
    }

    return AnimationLimiter(
      key: const Key('Chats'),
      child: Obx(() {
        final List<RxChat> calls = [];
        final List<RxChat> favorites = [];
        final List<RxChat> chats = [];

        for (var e in c.chats) {
          if ((!e.id.isLocal ||
                  e.messages.isNotEmpty ||
                  e.chat.value.isMonolog) &&
              !e.chat.value.isHidden &&
              !e.hidden.value) {
            if (e.chat.value.ongoingCall != null) {
              calls.add(e.rx);
            } else if (e.chat.value.favoritePosition != null) {
              favorites.add(e.rx);
            } else {
              chats.add(e.rx);
            }
          }
        }

        // Builds a [RecentChatTile] from the provided
        // [RxChat].
        Widget tile(RxChat e, {Widget Function(Widget)? avatarBuilder}) {
          final bool selected = c.selectedChats.contains(e.id);

          return RecentChatTile(
            e,
            key: e.chat.value.isMonolog
                ? const Key('ChatMonolog')
                : Key('RecentChat_${e.id}'),
            me: c.me,
            blocked: e.blocked,
            selected: c.selecting.value ? selected : null,
            getUser: c.getUser,
            avatarBuilder: c.selecting.value
                ? (child) => WidgetButton(
                    onPressed: () => router.dialog(e.chat.value, c.me),
                    child: child,
                  )
                : avatarBuilder,
            onJoin: () => c.joinCall(e.id),
            onDrop: () => c.dropCall(e.id),
            onLeave: e.chat.value.isMonolog ? null : () => c.leaveChat(e.id),
            onHide: () => c.hideChat(e.id),
            onMute: e.chat.value.isMonolog || e.chat.value.id.isLocal
                ? null
                : () => c.muteChat(e.id),
            onUnmute: e.chat.value.isMonolog || e.chat.value.id.isLocal
                ? null
                : () => c.unmuteChat(e.id),
            onFavorite: e.chat.value.id.isLocal && !e.chat.value.isMonolog
                ? null
                : () => c.favoriteChat(e.id),
            onUnfavorite: e.chat.value.id.isLocal && !e.chat.value.isMonolog
                ? null
                : () => c.unfavoriteChat(e.id),
            onSelect: c.toggleSelecting,

            // TODO: Uncomment, when contacts are implemented.
            // onContact: (b) => b
            //     ? c.addToContacts(e)
            //     : c.removeFromContacts(e),
            // inContacts: e.chat.value.isDialog
            //     ? () => c.inContacts(e)
            //     : null,
            onTap: c.selecting.value ? () => c.selectChat(e) : null,
            onDismissed: () => c.dismiss(e),
            enableContextMenu: !c.selecting.value,
            trailing: c.selecting.value
                ? [SelectedDot(selected: selected, size: 20)]
                : null,
            hasCall: c.status.value.isLoadingMore ? false : null,
            onPerformDrop: (f) => c.sendFiles(e.id, f),
          );
        }

        return SliverMainAxisGroup(
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(top: 4, left: 10, right: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed(
                  calls.mapIndexed((i, e) {
                    return AnimationConfiguration.staggeredList(
                      position: i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        horizontalOffset: 50,
                        child: FadeInAnimation(child: tile(e)),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              sliver: SliverReorderableList(
                onReorderStart: (_) => c.reordering.value = true,
                proxyDecorator: (child, _, animation) {
                  return AnimatedBuilder(
                    animation: animation,
                    builder: (_, Widget? child) {
                      final double t = Curves.easeInOut.transform(
                        animation.value,
                      );
                      final double elevation = lerpDouble(0, 6, t)!;
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
                          borderRadius: style.cardRadius.copyWith(
                            topLeft: Radius.circular(
                              style.cardRadius.topLeft.x * 1.75,
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
                              key: Key('ReorderHandle_${chat.id.val}'),
                              index: i,
                              child: child,
                            );
                          }

                          return RawGestureDetector(
                            gestures: {
                              DisableSecondaryButtonRecognizer:
                                  GestureRecognizerFactoryWithHandlers<
                                    DisableSecondaryButtonRecognizer
                                  >(
                                    () => DisableSecondaryButtonRecognizer(),
                                    (_) {},
                                  ),
                            },
                            child: ReorderableDragStartListener(
                              key: Key('ReorderHandle_${chat.id.val}'),
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

                      return AnimationConfiguration.staggeredList(
                        position: calls.length + i,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          horizontalOffset: 50,
                          child: FadeInAnimation(child: child),
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
              padding: EdgeInsets.only(bottom: 4, left: 10, right: 10),
              sliver: SliverList(
                delegate: SliverChildListDelegate.fixed([
                  ...chats.mapIndexed((i, e) {
                    return AnimationConfiguration.staggeredList(
                      position: calls.length + favorites.length + i,
                      duration: const Duration(milliseconds: 375),
                      child: SlideAnimation(
                        horizontalOffset: 50,
                        child: FadeInAnimation(child: tile(e)),
                      ),
                    );
                  }),
                  if (c.hasNext.isTrue || c.status.value.isLoadingMore)
                    Center(
                      child: CustomProgressIndicator(
                        key: const Key('ChatsLoading'),
                        value: Config.disableInfiniteAnimations ? 0 : null,
                      ),
                    ),
                ]),
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Builds a [BottomPaddedRow] for selecting the [Chat]s.
  static Widget selectingBuilder(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;

    return BottomPaddedRow(
      spacer: (_) {
        return Container(
          decoration: BoxDecoration(color: style.colors.onBackgroundOpacity13),
          width: 1,
          height: 24,
        );
      },
      children: [
        WidgetButton(
          onPressed: c.readAll,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_read_all'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        WidgetButton(
          onPressed: c.selectedChats.isEmpty
              ? null
              : () => _hideChats(context, c),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_hide'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        WidgetButton(
          key: const Key('DeleteChatsButton'),
          onPressed: c.selectedChats.isEmpty
              ? null
              : () => _hideChats(context, c),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_delete'.l10n,
                style: style.fonts.normal.regular.danger,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Builds a [BottomPaddedRow] for creating a [Chat]-group.
  static Widget createGroupBuilder(BuildContext context, ChatsTabController c) {
    final style = Theme.of(context).style;

    return BottomPaddedRow(
      spacer: (_) {
        return Container(
          decoration: BoxDecoration(color: style.colors.onBackgroundOpacity13),
          width: 1,
          height: 24,
        );
      },
      children: [
        WidgetButton(
          onPressed: c.closeGroupCreating,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_cancel'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        WidgetButton(
          onPressed: c.createGroup,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6.5, 10, 6.5),
              child: Text(
                'btn_create'.l10n,
                style: style.fonts.normal.regular.primary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Opens a confirmation popup hiding the selected chats.
  static Future<void> _hideChats(
    BuildContext context,
    ChatsTabController c,
  ) async {
    final bool? result = await MessagePopup.alert(
      'label_delete_chats'.l10n,
      description: [TextSpan(text: 'label_to_restore_chats_use_search'.l10n)],
      button: MessagePopup.deleteButton,
    );

    if (result == true) {
      await c.hideChats();
    }
  }
}
