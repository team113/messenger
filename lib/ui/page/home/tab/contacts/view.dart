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
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:get/get.dart';

import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/tab/chats/controller.dart';
import '/ui/page/home/tab/chats/widget/search_user_tile.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/bottom_padded_row.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/page/home/widget/shadowed_rounded_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/selected_dot.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/text_field.dart';
import '/ui/widget/widget_button.dart';
import '/util/message_popup.dart';
import '/util/platform_utils.dart';
import 'controller.dart';

/// View of the `HomeTab.contacts` tab.
class ContactsTabView extends StatelessWidget {
  const ContactsTabView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

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
            border: c.search.value != null || c.selecting.value
                ? Border.all(color: style.colors.primary, width: 2)
                : null,
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
                        style: style.fonts.bodyLarge,
                        onChanged: () => c.search.value?.query.value =
                            c.search.value?.search.text ?? '',
                      ),
                    ),
                  ),
                );
              } else if (c.selecting.value) {
                child = Text('label_select_contacts'.l10n);
              } else {
                final Widget synchronization;

                if (c.fetching.value == null && c.status.value.isLoadingMore) {
                  synchronization = Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Center(
                      child: Text(
                        'label_synchronization'.l10n,
                        style: style.fonts.labelMediumSecondary,
                      ),
                    ),
                  );
                } else {
                  synchronization = const SizedBox.shrink();
                }

                child = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('label_contacts'.l10n),
                    AnimatedSizeAndFade(
                      sizeDuration: const Duration(milliseconds: 300),
                      fadeDuration: const Duration(milliseconds: 300),
                      child: synchronization,
                    ),
                  ],
                );
              }

              return AnimatedSwitcher(duration: 250.milliseconds, child: child);
            }),
            actions: [
              Obx(() {
                Widget? child;

                if (c.search.value != null) {
                  if (c.search.value?.search.isEmpty.value == false) {
                    child = const SvgImage.asset(
                      'assets/icons/search_exit.svg',
                      key: Key('CloseSearch'),
                      height: 11,
                    );
                  }
                } else {
                  if (c.selecting.value) {
                    child = SvgImage.asset(
                      c.search.value != null
                          ? 'assets/icons/search_exit.svg'
                          : 'assets/icons/close_primary.svg',
                      key: const Key('CloseGroupSearching'),
                      height: c.search.value != null ? 11 : 15,
                    );
                  }
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (child != null)
                      AnimatedButton(
                        onPressed: () {
                          if (c.search.value != null) {
                            if (c.search.value?.search.isEmpty.value == false) {
                              c.search.value?.search.clear();
                              c.search.value?.query.value = '';
                              c.search.value?.search.focus.requestFocus();
                            }
                          } else if (c.selecting.value) {
                            c.toggleSelecting();
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
                      ),
                    if (c.search.value == null && !c.selecting.value)
                      ContextMenuRegion(
                        key: const Key('ContactsMenu'),
                        alignment: Alignment.topRight,
                        enablePrimaryTap: true,
                        enableSecondaryTap: false,
                        selector: c.moreKey,
                        margin: const EdgeInsets.only(bottom: 4, right: 0),
                        actions: [
                          ContextMenuButton(
                            label: c.sortByName
                                ? 'label_sort_by_visit'.l10n
                                : 'label_sort_by_name'.l10n,
                            onPressed: c.toggleSorting,
                          ),
                          ContextMenuButton(
                            key: const Key('SelectContactsButton'),
                            label: 'btn_select_and_delete'.l10n,
                            onPressed: c.toggleSelecting,
                          ),
                        ],
                        child: AnimatedButton(
                          decorator: (child) => Container(
                            key: c.moreKey,
                            padding: const EdgeInsets.only(left: 12, right: 18),
                            height: double.infinity,
                            child: child,
                          ),
                          child: Icon(
                            Icons.more_vert,
                            color: style.colors.primary,
                          ),
                        ),
                      ),
                  ],
                );
              }),
            ],
            leading: [
              Obx(() {
                if (c.selecting.value) {
                  final bool selected = c.contacts.isNotEmpty &&
                      c.contacts.every(
                        (e) => c.selectedContacts.any((m) => m == e.id),
                      );

                  return WidgetButton(
                    onPressed: () {
                      bool selected = c.contacts.every(
                        (e) => c.selectedContacts.any((m) => m == e.id),
                      );

                      if (selected) {
                        c.selectedContacts.clear();
                      } else {
                        for (var e in c.contacts) {
                          if (!c.selectedContacts.contains(e.id)) {
                            c.selectContact(e);
                          }
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.only(left: 20, right: 6),
                      height: double.infinity,
                      child: SelectedDot(
                        selected: selected,
                        inverted: false,
                        outlined: !selected,
                        size: 21,
                      ),
                    ),
                  );
                }

                return AnimatedButton(
                  key: c.search.value == null
                      ? const Key('SearchButton')
                      : const Key('CloseSearchButton'),
                  onPressed: c.search.value == null
                      ? () => c.toggleSearch(true)
                      : () => c.toggleSearch(false),
                  decorator: (child) {
                    return Container(
                      padding: const EdgeInsets.only(left: 20, right: 6),
                      height: double.infinity,
                      child: child,
                    );
                  },
                  child: AnimatedSwitcher(
                    duration: 250.milliseconds,
                    child: c.search.value != null
                        ? Icon(
                            key: const Key('ArrowBack'),
                            Icons.arrow_back_ios_new,
                            size: 20,
                            color: style.colors.primary,
                          )
                        : const SvgImage.asset(
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
            if (c.status.value.isLoading) {
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
                        ListElement? element;
                        if (i < c.elements.length) {
                          element = c.elements[i];
                        }

                        final Widget child;

                        if (element is ContactElement) {
                          child = SearchUserTile(
                            key: Key('SearchContact_${element.contact.id}'),
                            contact: element.contact,
                            onTap: () => router.user(
                              (element as ContactElement)
                                  .contact
                                  .user
                                  .value!
                                  .id,
                            ),
                          );
                        } else if (element is UserElement) {
                          child = SearchUserTile(
                            key: Key('SearchUser_${element.user.id}'),
                            user: element.user,
                            onTap: () =>
                                router.user((element as UserElement).user.id),
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
                                  style: style.fonts.labelLarge,
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
                child = AnimatedDelayedSwitcher(
                  key: UniqueKey(),
                  delay: const Duration(milliseconds: 300),
                  child: Center(
                    key: const Key('NothingFound'),
                    child: Text(
                      'label_nothing_found'.l10n,
                      style: style.fonts.labelMedium,
                    ),
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
                              if (c.favorites.isEmpty) {
                                // This builder is invoked for some reason when
                                // deleting all favorite contacts, so put a
                                // guard for that case.
                                return const SizedBox.shrink(key: Key('0'));
                              }

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
                                          enabled: !c.selecting.value,
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
                                          enabled: !c.selecting.value,

                                          // Use a dummy
                                          // [GestureDetector.onLongPress]
                                          // callback for discarding long
                                          // presses on the [child].
                                          child: GestureDetector(
                                            onLongPress: () {},
                                            child: child,
                                          ),
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
                        ? style.colors.secondaryHighlight
                        : style.colors.secondaryHighlight.withOpacity(0),
                  );
                }),
                ContextMenuInterceptor(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    layoutBuilder: (current, previous) => Stack(
                      alignment: Alignment.center,
                      children: [
                        if (previous.isNotEmpty) previous.first,
                        if (current != null) current,
                      ],
                    ),
                    child: child,
                  ),
                ),
              ],
            );
          }),
          bottomNavigationBar: Obx(() {
            if (c.selecting.value) {
              return BottomPaddedRow(
                children: [
                  ShadowedRoundedButton(
                    onPressed: c.toggleSelecting,
                    child: Text(
                      'btn_cancel'.l10n,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: style.fonts.titleLarge,
                    ),
                  ),
                  ShadowedRoundedButton(
                    key: const Key('DeleteContacts'),
                    onPressed: c.selectedContacts.isEmpty
                        ? null
                        : () => _removeContacts(context, c),
                    color: style.colors.primary,
                    child: Text(
                      'btn_delete_count'.l10nfmt({
                        'count': c.selectedContacts.length,
                      }),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: c.selectedContacts.isEmpty
                          ? style.fonts.titleLarge
                          : style.fonts.titleLargeOnPrimary,
                    ),
                  )
                ],
              );
            }

            return const SizedBox();
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
    return Obx(() {
      final style = Theme.of(context).style;

      bool favorite = c.favorites.contains(contact);

      final bool selected = router.routes
              .lastWhereOrNull((e) => e.startsWith(Routes.user))
              ?.startsWith('${Routes.user}/${contact.user.value?.id}') ==
          true;

      final bool inverted = selected || c.selectedContacts.contains(contact.id);

      return ContactTile(
        key: Key('Contact_${contact.id}'),
        contact: contact,
        folded: favorite,
        selected: inverted,
        enableContextMenu: !c.selecting.value,
        avatarBuilder: c.selecting.value
            ? (child) => WidgetButton(
                  // TODO: Open [Routes.contact] page when it's implemented.
                  onPressed: () => router.user(contact.user.value!.id),
                  child: avatarBuilder?.call(child) ?? child,
                )
            : avatarBuilder,
        onTap: c.selecting.value
            ? () => c.selectContact(contact)
            : contact.contact.value.users.isNotEmpty
                // TODO: Open [Routes.contact] page when it's implemented.
                ? () => router.user(contact.user.value!.id)
                : null,
        actions: [
          favorite
              ? ContextMenuButton(
                  key: const Key('UnfavoriteContactButton'),
                  label: 'btn_delete_from_favorites'.l10n,
                  onPressed: () =>
                      c.unfavoriteContact(contact.contact.value.id),
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
        ],
        subtitle: [
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Obx(() {
              final subtitle = contact.user.value?.user.value.getStatus();
              if (subtitle != null) {
                return Text(
                  subtitle,
                  style: inverted
                      ? style.fonts.labelMediumOnPrimary
                      : style.fonts.labelMediumSecondary,
                );
              }

              return Container();
            }),
          ),
        ],
        trailing: [
          Obx(() {
            final dialog = contact.user.value?.dialog.value;

            if (dialog?.chat.value.muted == null ||
                contact.user.value?.user.value.isBlocked != null) {
              return const SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: SvgImage.asset(
                inverted
                    ? 'assets/icons/muted_light.svg'
                    : 'assets/icons/muted.svg',
                key: Key('MuteIndicator_${contact.id}'),
                width: 19.99,
                height: 15,
              ),
            );
          }),
          Obx(() {
            if (contact.user.value?.user.value.isBlocked == null) {
              return const SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Icon(
                Icons.block,
                color: inverted
                    ? style.colors.onPrimary
                    : style.colors.secondaryHighlightDarkest,
                size: 20,
              ),
            );
          }),
          Obx(() {
            if (!c.selecting.value) {
              return const SizedBox();
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: SelectedDot(
                selected: c.selectedContacts.contains(contact.id),
                size: 22,
              ),
            );
          }),
        ],
      );
    });
  }

  /// Opens a confirmation popup deleting the provided [contact] from address
  /// book.
  Future<void> _removeFromContacts(
    ContactsTabController c,
    BuildContext context,
    RxChatContact contact,
  ) async {
    final style = Theme.of(context).style;

    final bool? result = await MessagePopup.alert(
      'label_delete_contact'.l10n,
      description: [
        TextSpan(text: 'alert_contact_will_be_removed1'.l10n),
        TextSpan(
          text: contact.contact.value.name.val,
          style: style.fonts.bodySmall,
        ),
        TextSpan(text: 'alert_contact_will_be_removed2'.l10n),
      ],
    );

    if (result == true) {
      await c.deleteFromContacts(contact.contact.value);
    }
  }

  /// Opens a confirmation popup deleting the selected contacts.
  Future<void> _removeContacts(
    BuildContext context,
    ContactsTabController c,
  ) async {
    final bool? result = await MessagePopup.alert(
      'label_delete_contacts'.l10n,
      description: [
        TextSpan(
          text: 'alert_contacts_will_be_deleted'
              .l10nfmt({'count': c.selectedContacts.length}),
        ),
      ],
    );

    if (result == true) {
      await c.deleteContacts();
    }
  }
}
