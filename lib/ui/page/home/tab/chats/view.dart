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

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/repository/chat.dart';
import '/domain/service/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/field_button.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/widget/animated_delayed_switcher.dart';
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
              return AnimatedContainer(
                duration: 200.milliseconds,
                color: c.search.value != null || c.searching.value
                    ? style.colors.secondaryHighlight
                    : style.colors.secondaryHighlight.withOpacity(0),
              );
            }),
            Obx(() {
              return Scaffold(
                extendBodyBehindAppBar: true,
                resizeToAvoidBottomInset: false,
                appBar: CustomAppBar(
                  border: c.search.value != null || c.selecting.value
                      ? Border.all(color: style.colors.primary, width: 2)
                      : null,
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
                              style: style.bodyLarge,
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
                    } else if (c.selecting.value) {
                      child =
                          Text('label_select_chats'.l10n, key: const Key('3'));
                    } else {
                      final Widget synchronization;

                      if (c.fetching.value == null &&
                          c.status.value.isLoadingMore) {
                        synchronization = Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Center(
                            child: Text(
                              'label_synchronization'.l10n,
                              style: style.labelMedium.copyWith(
                                color: style.colors.secondary,
                                fontWeight: FontWeight.w300,
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
                          Text('label_chats'.l10n),
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
                      if (c.selecting.value) {
                        return const SizedBox(width: 49.77);
                      }

                      return AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: WidgetButton(
                          key: const Key('SearchButton'),
                          onPressed: c.searching.value ? null : c.startSearch,
                          child: Container(
                            padding: const EdgeInsets.only(left: 20, right: 12),
                            height: double.infinity,
                            child: SvgImage.asset(
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
                      final Widget child;

                      if (c.searching.value) {
                        child = SvgImage.asset(
                          'assets/icons/close_primary.svg',
                          key: const Key('CloseSearch'),
                          height: 15,
                        );
                      } else {
                        child = c.groupCreating.value || c.selecting.value
                            ? SvgImage.asset(
                                'assets/icons/close_primary.svg',
                                key: const Key('CloseGroupSearching'),
                                height: 15,
                              )
                            : SvgImage.asset(
                                'assets/icons/group.svg',
                                key: const Key('CreateGroup'),
                                width: 21.77,
                                height: 18.44,
                              );
                      }

                      return WidgetButton(
                        key: c.searching.value
                            ? const Key('CloseSearchButton')
                            : null,
                        onPressed: () {
                          if (c.searching.value) {
                            c.closeSearch(!c.groupCreating.value);
                          } else if (c.selecting.value) {
                            c.toggleSelecting();
                          } else {
                            if (c.groupCreating.value) {
                              c.closeGroupCreating();
                            } else {
                              c.startGroupCreating();
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.only(left: 12, right: 18),
                          height: double.infinity,
                          child: SizedBox(
                            width: 21.77,
                            child: AnimatedSwitcher(
                              duration: 250.milliseconds,
                              child: child,
                            ),
                          ),
                        ),
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
                          child: ColoredBox(
                            color: style.colors.transparent,
                            child: const CustomProgressIndicator(),
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
                                      style: style.bodySmall.copyWith(
                                        color: style.colors.onPrimary,
                                        fontWeight: FontWeight.w300,
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
                                      style: style.labelLarge.copyWith(
                                        fontWeight: FontWeight.w300,
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
                                        style: style.labelLarge.copyWith(
                                          fontWeight: FontWeight.w300,
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

                              return RecentChatTile(
                                e,
                                key: e.chat.value.isMonolog
                                    ? const Key('ChatMonolog')
                                    : Key('RecentChat_${e.id}'),
                                me: c.me,
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
                                onLeave: e.chat.value.isMonolog
                                    ? null
                                    : () => c.leaveChat(e.id),
                                onHide: () => c.hideChat(e.id),
                                inCall: () => c.inCall(e.id),
                                onMute: e.chat.value.isMonolog
                                    ? null
                                    : () => c.muteChat(e.id),
                                onUnmute: e.chat.value.isMonolog
                                    ? null
                                    : () => c.unmuteChat(e.id),
                                onFavorite: () => c.favoriteChat(e.id),
                                onUnfavorite: () => c.unfavoriteChat(e.id),
                                onSelect: c.toggleSelecting,
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
                            }

                            return CustomScrollView(
                              controller: c.scrollController,
                              slivers: [
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

        child = Padding(
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
                  style: style.bodyLarge.copyWith(
                    fontWeight: FontWeight.w300,
                  ),
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
                  style: style.bodyLarge.copyWith(
                    color: style.colors.onPrimary,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                onPressed: c.createGroup,
                color: style.colors.primary,
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
                style: style.bodyLarge.copyWith(fontWeight: FontWeight.w300),
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
                  style: style.bodyLarge.copyWith(
                    color: c.selectedChats.isEmpty
                        ? style.colors.onBackground
                        : style.colors.onPrimary,
                    fontWeight: FontWeight.w300,
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
