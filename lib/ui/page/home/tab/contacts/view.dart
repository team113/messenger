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
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/tab/chats/controller.dart';
import '/ui/page/home/tab/chats/widget/search_user_tile.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the `HomeTab.contacts` tab.
class ContactsTabView extends StatelessWidget {
  const ContactsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Style style = Theme.of(context).extension<Style>()!;

    return GetBuilder(
      key: const Key('ContactsTab'),
      init: ContactsTabController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (ContactsTabController c) => Scaffold(
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
              child = Text('label_contacts'.l10n);
            }

            return AnimatedSwitcher(duration: 250.milliseconds, child: child);
          }),
          actions: [
            Obx(() {
              final Widget child;

              if (c.search.value != null) {
                child = WidgetButton(
                  key: const Key('CloseSearch'),
                  onPressed: () => c.toggleSearch(false),
                  child: SvgLoader.asset(
                    'assets/icons/close_primary.svg',
                    height: 15,
                    width: 15,
                  ),
                );
              } else {
                child = WidgetButton(
                  key: Key('SortBy${c.sortByName ? 'Abc' : 'Time'}'),
                  onPressed: c.toggleSorting,
                  child: SvgLoader.asset(
                    'assets/icons/sort_${c.sortByName ? 'abc' : 'time'}.svg',
                    width: 29.69,
                    height: 21,
                  ),
                );
              }
              return Container(
                alignment: Alignment.center,
                width: 29.69,
                height: 21,
                margin: const EdgeInsets.only(left: 12, right: 18),
                child: AnimatedSwitcher(
                  duration: 250.milliseconds,
                  child: child,
                ),
              );
            }),
          ],
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
        ),
        extendBodyBehindAppBar: true,
        body: Obx(() {
          if (!c.contactsReady.value) {
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
                key: const Key('Search'),
                child: ListView.builder(
                  controller: ScrollController(),
                  itemCount: c.elements.length,
                  itemBuilder: (_, i) {
                    final ListElement element = c.elements[i];
                    final Widget child;

                    if (element is ContactElement) {
                      child = SearchUserTile(
                        key: Key('SearchContact_${element.contact.id}'),
                        contact: element.contact,
                        onTap: () =>
                            router.user(element.contact.user.value!.id),
                      );
                    } else if (element is UserElement) {
                      child = SearchUserTile(
                        key: Key('SearchUser_${element.user.id}'),
                        user: element.user,
                        onTap: () => router.user(element.user.id),
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
                        child: FadeInAnimation(child: child),
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
            if (c.contacts.isEmpty && c.favorites.isEmpty) {
              child = Center(
                key: const Key('NoContacts'),
                child: Text('label_no_contacts'.l10n),
              );
            } else {
              child = AnimationLimiter(
                child: CustomScrollView(
                  controller: ScrollController(),
                  slivers: [
                    SliverPadding(
                      padding: EdgeInsets.only(
                        top: CustomAppBar.height +
                            MediaQuery.of(context).viewPadding.top,
                        left: 10,
                        right: 10,
                      ),
                      sliver: SliverReorderableList(
                        onReorderStart: (_) => c.reordering.value = true,
                        proxyDecorator: (child, _, animation) {
                          return AnimatedBuilder(
                            animation: animation,
                            builder: (_, Widget? child) {
                              final double t =
                                  Curves.easeInOut.transform(animation.value);
                              final double elevation = lerpDouble(0, 6, t)!;
                              final Color color = Color.lerp(
                                const Color(0x00000000),
                                const Color(0x33000000),
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
                          RxChatContact contact = c.favorites.elementAt(i);
                          return KeyedSubtree(
                            key: Key(contact.id.val),
                            child: Obx(() {
                              final Widget child = _contact(
                                context,
                                contact,
                                c,
                                avatarBuilder: (child) {
                                  if (PlatformUtils.isMobile) {
                                    return ReorderableDelayedDragStartListener(
                                      key: Key(
                                          'ReorderHandle_${contact.id.val}'),
                                      index: i,
                                      child: child,
                                    );
                                  }

                                  return ReorderableDragStartListener(
                                    key: Key('ReorderHandle_${contact.id.val}'),
                                    index: i,
                                    child: child,
                                  );
                                },
                              );

                              // Ignore the animation, if there's an ongoing
                              // reordering happening.
                              if (c.reordering.value) {
                                return child;
                              }

                              return AnimationConfiguration.staggeredList(
                                position: i,
                                duration: const Duration(milliseconds: 375),
                                child: SlideAnimation(
                                  horizontalOffset: 50,
                                  child: FadeInAnimation(child: child),
                                ),
                              );
                            }),
                          );
                        },
                        itemCount: c.favorites.length,
                        onReorder: (a, b) {
                          c.reorderContact(a, b);
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
                          c.contacts.mapIndexed((i, e) {
                            return AnimationConfiguration.staggeredList(
                              position: i,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                horizontalOffset: 50,
                                child: FadeInAnimation(
                                  child: _contact(context, e, c),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
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
        }),
      ),
    );
  }

  /// Returns a [ListTile] with [contact]'s information.
  Widget _contact(
    BuildContext context,
    RxChatContact contact,
    ContactsTabController c, {
    Widget Function(Widget)? avatarBuilder,
  }) {
    bool favorite = c.favorites.contains(contact);

    final bool selected = router.routes
            .lastWhereOrNull((e) => e.startsWith(Routes.user))
            ?.startsWith('${Routes.user}/${contact.user.value?.id}') ==
        true;

    return ContactTile(
      key: Key('Contact_${contact.id}'),
      contact: contact,
      folded: favorite,
      selected: selected,
      avatarBuilder: avatarBuilder,
      onTap: contact.contact.value.users.isNotEmpty
          // TODO: Open [Routes.contact] page when it's implemented.
          ? () => router.user(contact.user.value!.id)
          : null,
      actions: [
        favorite
            ? ContextMenuButton(
                key: const Key('UnfavoriteContactButton'),
                label: 'btn_delete_from_favorites'.l10n,
                onPressed: () => c.unfavoriteContact(contact.contact.value.id),
              )
            : ContextMenuButton(
                key: const Key('FavoriteContactButton'),
                label: 'btn_add_to_favorites'.l10n,
                onPressed: () => c.favoriteContact(contact.contact.value.id),
              ),
        ContextMenuButton(
          label: 'btn_delete_from_contacts'.l10n,
          onPressed: () => c.deleteFromContacts(contact.contact.value),
        ),
      ],
      subtitle: [
        Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Obx(() {
            final subtitle = contact.user.value?.user.value.getStatus();
            if (subtitle != null) {
              return Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              );
            }

            return Container();
          }),
        ),
      ],
    );
  }
}
