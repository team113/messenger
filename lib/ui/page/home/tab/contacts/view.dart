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
import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/message_field/view.dart';
import '/ui/page/home/page/user/controller.dart';
import '/ui/page/home/tab/chats/widget/search_user_tile.dart';
import '/ui/page/home/tab/chats/widget/slidable_action.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/bottom_padded_row.dart';
import '/ui/page/home/widget/contact_tile.dart';
import '/ui/page/home/widget/navigation_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/page/home/widget/shadowed_rounded_button.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/animated_delayed_switcher.dart';
import '/ui/widget/animated_switcher.dart';
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
import '/util/recognizers.dart';
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
                        style: style.fonts.medium.regular.onBackground,
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
                        style: style.fonts.small.regular.secondary,
                      ),
                    ),
                  );
                } else {
                  synchronization = const SizedBox.shrink();
                }

                child = Align(
                  alignment: Alignment.centerLeft,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('label_contacts'.l10n),
                      AnimatedSizeAndFade(
                        sizeDuration: const Duration(milliseconds: 300),
                        fadeDuration: const Duration(milliseconds: 300),
                        child: synchronization,
                      ),
                    ],
                  ),
                );
              }

              return SafeAnimatedSwitcher(
                duration: 250.milliseconds,
                child: child,
              );
            }),
            actions: [
              Obx(() {
                final Widget? child;

                if (c.search.value != null) {
                  if (c.search.value?.search.isEmpty.value == false) {
                    child = const SvgIcon(
                      SvgIcons.clearSearch,
                      key: Key('CloseSearch'),
                    );
                  } else {
                    child = const SvgIcon(
                      SvgIcons.closePrimary,
                      key: Key('CloseSearch'),
                    );
                  }
                } else {
                  child = c.selecting.value
                      ? const SvgIcon(
                          SvgIcons.closePrimary,
                          key: Key('CloseGroupSearching'),
                        )
                      : null;
                }

                if (child != null) {
                  return AnimatedButton(
                    key: c.search.value != null
                        ? const Key('CloseSearchButton')
                        : c.selecting.value
                        ? const Key('CloseSelectingButton')
                        : null,
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
                    decorator: (child) {
                      return Container(
                        padding: const EdgeInsets.only(left: 12, right: 16),
                        height: double.infinity,
                        child: child,
                      );
                    },
                    child: SizedBox(
                      width: 29.17,
                      child: AnimatedSwitcher(
                        duration: 250.milliseconds,
                        child: child,
                      ),
                    ),
                  );
                }

                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedButton(
                      key: const Key('ChatsButton'),
                      onPressed: () => router.tab = HomeTab.chats,
                      decorator: (child) {
                        return Container(
                          padding: const EdgeInsets.only(left: 20, right: 8),
                          height: double.infinity,
                          child: child,
                        );
                      },
                      child: const SvgIcon(SvgIcons.chatsSwitch),
                    ),
                    AnimatedButton(
                      key: const Key('SearchButton'),
                      onPressed: () => c.toggleSearch(),
                      decorator: (child) => Container(
                        padding: const EdgeInsets.only(left: 20, right: 12),
                        height: double.infinity,
                        child: child,
                      ),
                      child: const SvgIcon(SvgIcons.search, key: Key('Search')),
                    ),
                    ContextMenuRegion(
                      key: const Key('ContactsMenu'),
                      alignment: Alignment.topRight,
                      enablePrimaryTap: true,
                      enableLongTap: false,
                      enableSecondaryTap: false,
                      selector: c.moreKey,
                      margin: const EdgeInsets.only(bottom: 4),
                      actions: [
                        ContextMenuButton(
                          key: const Key('SelectContactsButton'),
                          label: 'btn_select_and_delete'.l10n,
                          onPressed: c.toggleSelecting,
                          trailing: const SvgIcon(SvgIcons.select),
                          inverted: const SvgIcon(SvgIcons.selectWhite),
                        ),
                      ],
                      child: AnimatedButton(
                        decorator: (child) => Container(
                          key: c.moreKey,
                          padding: const EdgeInsets.only(left: 12, right: 18),
                          height: double.infinity,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: child,
                          ),
                        ),
                        child: const SvgIcon(SvgIcons.more),
                      ),
                    ),
                  ],
                );
              }),
            ],
            leading: [
              Obx(() {
                if (c.selecting.value) {
                  final bool selected =
                      c.contacts.isNotEmpty &&
                      c.contacts.every(
                        (e) => c.selectedContacts.any((m) => m == e.id),
                      );

                  return AnimatedButton(
                    onPressed: () {
                      bool selected = c.contacts.every(
                        (e) => c.selectedContacts.any((m) => m == e.id),
                      );

                      if (selected) {
                        c.selectedContacts.clear();
                      } else {
                        for (var e in c.contacts) {
                          if (!c.selectedContacts.contains(e.id)) {
                            c.selectContact(e.rx);
                          }
                        }
                      }
                    },
                    decorator: (child) => Container(
                      padding: const EdgeInsets.only(left: 20, right: 6),
                      height: double.infinity,
                      child: child,
                    ),
                    child: SelectedDot(
                      selected: selected,
                      inverted: false,
                      outlined: !selected,
                      size: 21,
                    ),
                  );
                }

                if (c.search.value == null) {
                  return const SizedBox(width: 21);
                }

                return AnimatedButton(
                  key: const Key('CloseSearchButton'),
                  onPressed: () => c.toggleSearch(false),
                  decorator: (child) {
                    return Container(
                      padding: const EdgeInsets.only(left: 20, right: 6),
                      height: double.infinity,
                      child: child,
                    );
                  },
                  child: const SvgIcon(SvgIcons.search),
                );
              }),
            ],
          ),
          extendBodyBehindAppBar: true,
          body: Obx(() {
            final RxStatus? searchStatus = c.search.value?.searchStatus.value;
            if (c.status.value.isLoading) {
              return const Center(child: CustomProgressIndicator.primary());
            }

            final Widget? child;

            if (c.search.value?.search.isEmpty.value == false) {
              if (c.search.value!.searchStatus.value.isLoading &&
                  c.elements.isEmpty) {
                child = Center(
                  key: UniqueKey(),
                  child: ColoredBox(
                    key: const Key('Loading'),
                    color: style.colors.almostTransparent,
                    child: const CustomProgressIndicator(),
                  ),
                );
              } else if (c.elements.isNotEmpty) {
                child = SafeScrollbar(
                  controller: c.search.value!.scrollController,
                  child: AnimationLimiter(
                    key: const Key('Search'),
                    child: ListView.builder(
                      key: const Key('SearchScrollable'),
                      controller: c.search.value!.scrollController,
                      itemCount: c.elements.length,
                      itemBuilder: (_, i) {
                        ListElement? element;
                        if (i < c.elements.length) {
                          element = c.elements[i];
                        }

                        Widget child;

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
                                  element.category.name.capitalized,
                                  style:
                                      style.fonts.normal.regular.onBackground,
                                ),
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
                                const CustomProgressIndicator(),
                              ],
                            );
                          }
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
                      style: style.fonts.small.regular.onBackground,
                    ),
                  ),
                );
              }
            } else {
              if (c.contacts.isEmpty) {
                child = KeyedSubtree(
                  key: UniqueKey(),
                  child: Center(
                    key: const Key('NoContacts'),
                    child: Text('label_no_contacts'.l10n),
                  ),
                );
              } else {
                final List<ContactEntry> favorites = [];
                final List<ContactEntry> contacts = [];

                for (ContactEntry e in c.contacts) {
                  if (e.contact.value.favoritePosition != null) {
                    favorites.add(e);
                  } else {
                    contacts.add(e);
                  }
                }

                child = AnimationLimiter(
                  key: const Key('Contacts'),
                  child: SafeScrollbar(
                    controller: c.scrollController,
                    child: CustomScrollView(
                      controller: c.scrollController,
                      slivers: [
                        SliverPadding(
                          padding: const EdgeInsets.only(
                            top: CustomAppBar.height - 4,
                            left: 10,
                            right: 10,
                          ),
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
                              if (favorites.isEmpty) {
                                // This builder is invoked for some reason when
                                // deleting all favorite contacts, so put a
                                // guard for that case.
                                return const SizedBox.shrink(key: Key('0'));
                              }

                              final ContactEntry contact = favorites[i];

                              if (contact.hidden.value) {
                                return const SizedBox();
                              }

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
                                                DisableSecondaryButtonRecognizer
                                              >(
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
                            itemCount: favorites.length,
                            onReorder: (a, b) {
                              c.reorderContact(a, b);
                              c.reordering.value = false;
                            },
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.only(
                            bottom: CustomNavigationBar.height,
                            left: 10,
                            right: 10,
                          ),
                          sliver: SliverList(
                            delegate: SliverChildListDelegate.fixed([
                              ...contacts.mapIndexed((i, e) {
                                if (e.hidden.value) {
                                  return const SizedBox();
                                }

                                return AnimationConfiguration.staggeredList(
                                  position: favorites.length + i,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    horizontalOffset: 50,
                                    child: FadeInAnimation(
                                      child: _contact(context, e, c),
                                    ),
                                  ),
                                );
                              }),
                              if (c.hasNext.isTrue)
                                Center(
                                  child: CustomProgressIndicator(
                                    key: const Key('ContactsLoading'),
                                    value: Config.disableInfiniteAnimations
                                        ? 0
                                        : null,
                                  ),
                                ),
                            ]),
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
                        : style.colors.secondaryHighlight.withValues(alpha: 0),
                  );
                }),
                ContextMenuInterceptor(
                  child: SlidableAutoCloseBehavior(
                    child: SafeAnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: child,
                    ),
                  ),
                ),
              ],
            );
          }),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() {
                final Widget child;
                final action = c.dismissed.lastOrNull;

                if (action == null) {
                  child = const SizedBox(key: Key('NoDismissed'));
                } else {
                  child = Padding(
                    key: Key('Dismissed_${action.contact.id}'),
                    padding: EdgeInsets.fromLTRB(
                      10 + 10,
                      0,
                      10 + 10,
                      72 + router.context!.mediaQueryViewPadding.bottom,
                    ),
                    child: WidgetButton(
                      key: const Key('Restore'),
                      onPressed: action.cancel,
                      child: Container(
                        key: Key('${action.contact.id}'),
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
                                'btn_undo_delete'.l10n,
                                style: style.fonts.big.regular.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SafeAnimatedSwitcher(
                  duration: 200.milliseconds,
                  child: child,
                );
              }),
              Obx(() {
                if (c.selecting.value) {
                  return BottomPaddedRow(
                    children: [
                      ShadowedRoundedButton(
                        onPressed: c.toggleSelecting,
                        child: Text(
                          'btn_cancel'.l10n,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: style.fonts.medium.regular.onBackground,
                        ),
                      ),
                      ShadowedRoundedButton(
                        key: const Key('DeleteButton'),
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
                              ? style.fonts.medium.regular.onBackground
                              : style.fonts.medium.regular.onPrimary,
                        ),
                      ),
                    ],
                  );
                }

                return const SizedBox();
              }),
            ],
          ),
        );
      }),
    );
  }

  /// Returns a [ListTile] with [contact]'s information.
  Widget _contact(
    BuildContext context,
    ContactEntry contact,
    ContactsTabController c, {
    Widget Function(Widget)? avatarBuilder,
  }) {
    return Obx(() {
      final style = Theme.of(context).style;

      bool favorite = contact.contact.value.favoritePosition != null;

      final bool selected =
          router.routes
              .lastWhereOrNull((e) => e.startsWith(Routes.user))
              ?.startsWith('${Routes.user}/${contact.user.value?.id}') ==
          true;

      final bool inverted = selected || c.selectedContacts.contains(contact.id);

      return Slidable(
        key: Key(contact.id.val),
        groupTag: 'contact',
        endActionPane: ActionPane(
          extentRatio: 0.33,
          motion: const StretchMotion(),
          dismissible: DismissiblePane(
            onDismissed: () => c.dismiss(contact.rx),
          ),
          children: [
            FadingSlidableAction(
              onPressed: (context) =>
                  _removeFromContacts(c, context, contact.rx),
              icon: const Icon(Icons.delete),
              text: 'btn_delete'.l10n,
            ),
          ],
        ),
        child: ContactTile(
          key: Key('Contact_${contact.id}'),
          contact: contact.rx,
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
              ? () => c.selectContact(contact.rx)
              : contact.contact.value.users.isNotEmpty
              // TODO: Open [Routes.contact] page when it's implemented.
              ? () => router.user(contact.user.value!.id)
              : null,
          actions: [
            favorite
                ? ContextMenuButton(
                    key: const Key('FavoriteButton'),
                    label: 'btn_delete_from_favorites'.l10n,
                    onPressed: () =>
                        c.unfavoriteContact(contact.contact.value.id),
                    trailing: const SvgIcon(SvgIcons.favoriteSmall),
                    inverted: const SvgIcon(SvgIcons.favoriteSmallWhite),
                  )
                : ContextMenuButton(
                    key: const Key('FavoriteButton'),
                    label: 'btn_add_to_favorites'.l10n,
                    onPressed: () =>
                        c.favoriteContact(contact.contact.value.id),
                    trailing: const SvgIcon(SvgIcons.unfavoriteSmall),
                    inverted: const SvgIcon(SvgIcons.unfavoriteSmallWhite),
                  ),
            ContextMenuButton(
              label: 'btn_delete'.l10n,
              onPressed: () => _removeFromContacts(c, context, contact.rx),
              trailing: const SvgIcon(SvgIcons.delete19),
              inverted: const SvgIcon(SvgIcons.delete19White),
            ),
          ],
          subtitle: [
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Obx(() {
                if (contact.user.value == null) {
                  return const SizedBox();
                }

                final subtitle = contact.user.value?.user.value.getStatus(
                  contact.user.value?.lastSeen.value,
                );

                if (subtitle != null) {
                  return Text(
                    subtitle,
                    style: inverted
                        ? style.fonts.small.regular.onPrimary
                        : style.fonts.small.regular.secondary,
                  );
                }

                return const SizedBox();
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
                child: SvgIcon(
                  inverted ? SvgIcons.mutedWhite : SvgIcons.muted,
                  key: Key('MuteIndicator_${contact.id}'),
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
        ),
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
          style: style.fonts.small.regular.onBackground,
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
          text: 'alert_contacts_will_be_deleted'.l10nfmt({
            'count': c.selectedContacts.length,
          }),
        ),
      ],
    );

    if (result == true) {
      await c.deleteContacts();
    }
  }
}
