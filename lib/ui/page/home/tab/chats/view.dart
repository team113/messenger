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
import 'package:messenger/ui/page/home/page/my_profile/widget/field_button.dart';
import 'package:messenger/ui/page/home/widget/avatar.dart';
import 'package:messenger/ui/page/home/widget/navigation_bar.dart';
import 'package:messenger/ui/widget/animated_delayed_switcher.dart';
import 'package:messenger/ui/widget/animated_size_and_fade.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/util/message_popup.dart';
import 'package:skeletons/skeletons.dart';

import '/domain/repository/chat.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/search/controller.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
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
              return AnimatedContainer(
                duration: 200.milliseconds,
                color: c.search.value != null || c.searching.value
                    ? const Color(0xFFEBEBEB)
                    : const Color(0x00EBEBEB),
              );
            }),
            Obx(() {
              return Scaffold(
                extendBodyBehindAppBar: true,
                resizeToAvoidBottomInset: false,
                appBar: CustomAppBar(
                  border: c.search.value == null &&
                          !c.searching.value &&
                          !c.selecting.value
                      ? null
                      : Border.all(
                          color: Theme.of(context).colorScheme.secondary,
                          width: 2,
                        ),
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
                    } else if (c.selecting.value) {
                      child = WidgetButton(
                        onPressed: c.startSearch,
                        child: SizedBox(
                          width: double.infinity,
                          height: double.infinity,
                          child: Center(
                            child: Text(
                              'Select chats'.l10n,
                              key: const Key('3'),
                            ),
                          ),
                        ),
                      );
                    } else {
                      final bool isLoading = c.timer.value == null &&
                          (c.status.value.isLoadingMore ||
                              !c.status.value.isSuccess);

                      child = Column(
                        key: const Key('2'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('label_chats'.l10n),
                          AnimatedSizeAndFade(
                            sizeDuration: const Duration(milliseconds: 300),
                            fadeDuration: const Duration(milliseconds: 300),
                            child: isLoading
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Center(
                                      child: Text(
                                        'Синхронизация...',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: double.infinity),
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
                      return AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: WidgetButton(
                          key: const Key('SearchButton'),
                          onPressed: c.searching.value ? null : c.startSearch,
                          child: Container(
                            padding: const EdgeInsets.only(left: 20, right: 12),
                            height: double.infinity,
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
                      final Widget child;

                      if (c.searching.value) {
                        child = SvgLoader.asset(
                          'assets/icons/close_primary.svg',
                          key: const Key('CloseSearch'),
                          height: 15,
                        );
                      } else {
                        child = c.groupCreating.value || c.selecting.value
                            ? SvgLoader.asset(
                                'assets/icons/close_primary.svg',
                                height: 15,
                              )
                            : SvgLoader.asset(
                                'assets/icons/group.svg',
                                width: 21.77,
                                height: 18.44,
                              );
                      }

                      return WidgetButton(
                        onPressed: () {
                          if (c.searching.value) {
                            c.closeSearch(!c.groupCreating.value);
                          } else {
                            if (c.selecting.value) {
                              c.toggleSelecting();
                            } else if (c.groupCreating.value) {
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
                  // if (!c.chatsReady.value || c.loader.value) {
                  //   return const Center(child: CustomProgressIndicator());
                  // }

                  Widget dot(bool selected) {
                    return SizedBox(
                      width: 30,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: selected
                            ? CircleAvatar(
                                backgroundColor:
                                    Theme.of(context).colorScheme.secondary,
                                radius: 11,
                                child: const Icon(
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
                                width: 22,
                                height: 22,
                              ),
                      ),
                    );
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
                        center =
                            Center(child: Text('label_nothing_found'.l10n));
                      } else {
                        center = const Center(child: CustomProgressIndicator());
                      }
                    }

                    if (center != null) {
                      child = Padding(
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
                          controller: c.search.value!.controller,
                          itemCount: c.elements.length,
                          itemBuilder: (context, i) {
                            final Widget child;

                            final ListElement element = c.elements[i];

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
                      );
                    }
                  } else if (c.searching.value &&
                      c.search.value?.search.isEmpty.value == false) {
                    if (c.search.value!.searchStatus.value.isLoading &&
                        c.elements.isEmpty) {
                      child = const Center(
                        key: Key('Loading'),
                        child: CustomProgressIndicator(),
                      );
                    } else if (c.elements.isNotEmpty) {
                      child = SafeScrollbar(
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
                                  final bool selected =
                                      c.selectedChats.contains(chat.id);
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
                                    trailing: c.selecting.value
                                        ? [dot(selected)]
                                        : [],
                                    onTap: c.selecting.value
                                        ? () => c.selectChat(chat)
                                        : null,
                                    selected: selected,
                                    avatarBuilder: c.selecting.value
                                        ? (c) => WidgetButton(
                                              onPressed: () =>
                                                  router.chat(chat.id),
                                              child: c,
                                            )
                                        : null,
                                  );
                                }),
                              );
                            } else if (element is ContactElement) {
                              child = SearchUserTile(
                                key: Key('SearchContact_${element.contact.id}'),
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
                      );
                    } else {
                      child = AnimatedDelayedSwitcher(
                        key: const Key('NothingFound'),
                        delay: const Duration(milliseconds: 300),
                        child: Center(child: Text('label_nothing_found'.l10n)),
                      );
                    }
                  } else {
                    child = SafeScrollbar(
                      controller: c.scrollController,
                      child: AnimationLimiter(
                        key: const Key('Chats'),
                        child: ListView.builder(
                          controller: c.scrollController,
                          itemCount: c.chats.length,
                          itemBuilder: (_, i) {
                            final ListElement element = c.chats[i];

                            if (element is LoaderElement) {
                              return Center(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 12, 0, 12),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints.tight(
                                      const Size.square(40),
                                    ),
                                    child: const Center(
                                      child: CustomProgressIndicator(),
                                    ),
                                  ),
                                ),
                              );
                            } else if (element is ChatElement) {
                              final RxChat chat = element.chat;

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
                                        final bool selected =
                                            c.selectedChats.contains(chat.id);
                                        return RecentChatTile(
                                          chat,
                                          key: Key('RecentChat_${chat.id}'),
                                          me: c.me,
                                          myUser: c.myUser.value,
                                          blocked: chat.blacklisted,
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
                                          onSelect: c.toggleSelecting,
                                          trailing: c.selecting.value
                                              ? [dot(selected)]
                                              : [],
                                          onTap: c.selecting.value
                                              ? () => c.selectChat(chat)
                                              : null,
                                          selected: selected,
                                          avatarBuilder: c.selecting.value
                                              ? (c) => WidgetButton(
                                                    onPressed: () =>
                                                        router.chat(chat.id),
                                                    child: c,
                                                  )
                                              : null,
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                              );
                            }

                            return const SizedBox();
                          },
                        ),
                      ),
                    );
                  }

                  return ContextMenuInterceptor(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      // switchInCurve: Curves.easeInExpo,
                      // switchOutCurve: Curves.easeOutExpo,
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
                  color: const Color(0x33000000),
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
          shadows: const [
            CustomBoxShadow(
              blurRadius: 8,
              color: Color(0x22000000),
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
  }

  /// Returns an animated [OutlinedRoundedButton]s for creating a group.
  Widget _selectButtons(BuildContext context, ChatsTabController c) {
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
          shadows: const [
            CustomBoxShadow(
              blurRadius: 8,
              color: Color(0x22000000),
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
              'btn_close'.l10n,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: const TextStyle(color: Colors.black),
            ),
            onPressed: c.toggleSelecting,
            color: Colors.white,
          ),
          const SizedBox(width: 10),
          Obx(() {
            return button(
              child: Text(
                'Delete (${c.selectedChats.length})',
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                    color:
                        c.selectedChats.isEmpty ? Colors.black : Colors.white),
              ),
              onPressed:
                  c.selectedChats.isEmpty ? null : () => _hideChats(context, c),
              color: Theme.of(context).colorScheme.secondary,
            );
          }),
        ],
      ),
    );
  }

  Future<void> _hideChats(BuildContext context, ChatsTabController c) async {
    final Style style = Theme.of(context).extension<Style>()!;
    bool clear = false;

    Widget dot(bool selected) {
      return SizedBox(
        width: 30,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: selected
              ? CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  radius: 11,
                  child: const Icon(
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
                  width: 22,
                  height: 22,
                ),
        ),
      );
    }

    final bool? result = await MessagePopup.alert(
      'label_delete_chats'.l10n,
      description: [
        TextSpan(
          text: 'Чаты (${c.selectedChats.length}) будут удалены. Продолжить?'
              .l10n,
        ),
      ],
      additional: [
        const SizedBox(height: 21),
        StatefulBuilder(builder: (context, setState) {
          return FieldButton(
            text: 'Очистить чаты',
            onPressed: () => setState(() => clear = !clear),
            trailing: dot(clear),
          );

          return Material(
            type: MaterialType.card,
            borderRadius: style.cardRadius,
            color: clear
                ? style.cardSelectedColor.withOpacity(0.8)
                : style.cardColor.darken(0.05),
            child: InkWell(
              onTap: () => setState(() => clear = !clear),
              borderRadius: style.cardRadius,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: DefaultTextStyle.merge(
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge
                            ?.copyWith(color: Colors.black),
                        child: const Text(
                          'Очистить чаты',
                          // style: thin,
                        ),
                      ),
                    ),
                    IgnorePointer(
                      child: dot(clear),
                      // child: Radio<ConfirmDialogVariant>(
                      //   value: variant,
                      //   groupValue: _variant,
                      //   onChanged: null,
                      // ),
                    ),
                  ],
                ),
              ),
            ),
          );
        })
      ],
    );

    if (result == true) {}
  }
}
