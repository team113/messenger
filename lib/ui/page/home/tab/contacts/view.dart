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
import 'package:messenger/themes.dart';

import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/tab/chats/controller.dart';
import '/ui/page/home/tab/chats/widget/search_user_tile.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
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
      builder: (ContactsTabController c) => Obx(() {
        return Scaffold(
          appBar: CustomAppBar(
            border: c.search.value == null
                ? null
                : Border.all(
                    color: Theme.of(context).extension<Style>()!.secondary,
                    width: 2,
                  ),
            title: Obx(() {
              final Widget child;

              if (c.search.value != null) {
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
                  child = SvgLoader.asset(
                    key: const Key('CloseSearch'),
                    'assets/icons/close_primary.svg',
                    height: 15,
                    width: 15,
                  );
                } else {
                  child = SvgLoader.asset(
                    'assets/icons/sort_${c.sortByName ? 'abc' : 'time'}.svg',
                    key: Key('SortBy${c.sortByName ? 'Abc' : 'Time'}'),
                    width: 29.69,
                    height: 21,
                  );
                }

                return WidgetButton(
                  onPressed: () {
                    if (c.search.value != null) {
                      c.toggleSearch(false);
                    } else {
                      c.toggleSorting();
                    }
                  },
                  child: Container(
                    alignment: Alignment.center,
                    width: 29.69 + 12 + 18,
                    height: double.infinity,
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: child,
                      ),
                    ),
                  ),
                );
              }),
            ],
            leading: [
              Obx(() {
                return WidgetButton(
                  key: const Key('SearchButton'),
                  onPressed: c.search.value != null ? null : c.toggleSearch,
                  child: Container(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    height: double.infinity,
                    child: SvgLoader.asset(
                      'assets/icons/search.svg',
                      width: 17.77,
                    ),
                  ),
                );
              }),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Obx(() {
            if (!c.contactsReady.value) {
              return const Center(child: CustomProgressIndicator());
            }

            final Widget? child;

            if (c.search.value?.search.isEmpty.value == false) {
              if (c.search.value!.searchStatus.value.isLoading &&
                  c.elements.isEmpty) {
                child = Center(
                  key: UniqueKey(),
                  child: ColoredBox(
                    key: const Key('Loading'),
                    color: Theme.of(context).extension<Style>()!.transparent,
                    child: const CustomProgressIndicator(),
                  ),
                );
              } else if (c.elements.isNotEmpty) {
                child = SafeScrollbar(
                  controller: c.scrollController,
                  child: AnimationLimiter(
                    key: const Key('Search'),
                    child: ListView.builder(
                      controller: c.scrollController,
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
                                    color: Theme.of(context)
                                        .extension<Style>()!
                                        .onBackground,
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
                  ),
                );
              } else {
                child = KeyedSubtree(
                  key: UniqueKey(),
                  child: Center(
                    key: const Key('NothingFound'),
                    child: Text('label_nothing_found'.l10n),
                  ),
                );
              }
            } else {
              if (c.contacts.isEmpty && c.favorites.isEmpty) {
                child = KeyedSubtree(
                  key: UniqueKey(),
                  child: Center(
                    key: const Key('NoContacts'),
                    child: Text('label_no_contacts'.l10n),
                  ),
                );
              } else {
                child = AnimationLimiter(
                  child: SafeScrollbar(
                    controller: c.scrollController,
                    child: CustomScrollView(
                      controller: c.scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(
                            top: CustomAppBar.height,
                            left: 10,
                            right: 10,
                          ),
                          sliver: SliverReorderableList(
                            onReorderStart: (_) => c.reordering.value = true,
                            proxyDecorator: (child, _, animation) {
                              return AnimatedBuilder(
                                animation: animation,
                                builder: (_, Widget? child) {
                                  final double t = Curves.easeInOut
                                      .transform(animation.value);
                                  final double elevation = lerpDouble(0, 6, t)!;
                                  final Color color = Color.lerp(
                                    Theme.of(context)
                                        .extension<Style>()!
                                        .transparent,
                                    Theme.of(context)
                                        .extension<Style>()!
                                        .transparentOpacity81,
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
                                            'ReorderHandle_${contact.id.val}',
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
                                        child: ReorderableDragStartListener(
                                          key: Key(
                                            'ReorderHandle_${contact.id.val}',
                                          ),
                                          index: i,
                                          child: child,
                                        ),
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
                  ),
                );
              }
            }

            return Stack(
              children: [
                Obx(() {
                  return AnimatedContainer(
                    duration: 200.milliseconds,
                    color: c.search.value != null
                        ? const Color(0xFFEBEBEB)
                        : const Color(0x00EBEBEB),
                  );
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ContextMenuInterceptor(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          }),
        );
      }),
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
                trailing: const Icon(Icons.star_border),
              )
            : ContextMenuButton(
                key: const Key('FavoriteContactButton'),
                label: 'btn_add_to_favorites'.l10n,
                onPressed: () => c.favoriteContact(contact.contact.value.id),
                trailing: const Icon(Icons.star),
              ),
        ContextMenuButton(
          label: 'btn_delete'.l10n,
          onPressed: () => _removeFromContacts(c, context, contact),
          trailing: const Icon(Icons.delete),
        ),
        ContextMenuButton(
          label: 'btn_select'.l10n,
          trailing: const Icon(Icons.select_all),
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
                style: TextStyle(
                    color: Theme.of(context).extension<Style>()!.primary),
              );
            }

            return Container();
          }),
        ),
      ],
      trailing: [
        Obx(() {
          final dialog = contact.user.value?.dialog.value;

          if (dialog?.chat.value.muted == null) {
            return const SizedBox();
          }

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: SvgLoader.asset(
              'assets/icons/muted.svg',
              key: Key('MuteIndicator_${contact.id}'),
              width: 19.99,
              height: 15,
            ),
          );
        }),
        Obx(() {
          if (contact.user.value?.user.value.isBlacklisted == null) {
            return const SizedBox();
          }

          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 5),
            child: Icon(
              Icons.block,
              color: Color(0xFFC0C0C0),
              size: 20,
            ),
          );
        }),
      ],
    );
  }

  /// Opens a confirmation popup deleting the provided [contact] from address
  /// book.
  Future<void> _removeFromContacts(
    ContactsTabController c,
    BuildContext context,
    RxChatContact contact,
  ) async {
    final bool? result = await MessagePopup.alert(
      'label_delete_contact'.l10n,
      description: [
        TextSpan(text: 'alert_contact_will_be_removed1'.l10n),
        TextSpan(
          text: contact.contact.value.name.val,
          style: TextStyle(
              color: Theme.of(context).extension<Style>()!.onBackground),
        ),
        TextSpan(text: 'alert_contact_will_be_removed2'.l10n),
      ],
    );

    if (result == true) {
      await c.deleteFromContacts(contact.contact.value);
    }
  }
}
