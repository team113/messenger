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

import 'dart:async';
import 'dart:ui';

import 'package:animated_size_and_fade/animated_size_and_fade.dart';
import 'package:collection/collection.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:messenger/domain/repository/chat.dart';
import 'package:messenger/domain/repository/user.dart';
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/user/controller.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/page/home/widget/contact_tile.dart';
import 'package:messenger/ui/widget/modal_popup.dart';
import 'package:messenger/ui/widget/progress_indicator.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';
import 'package:sticky_headers/sticky_headers.dart';

import '/domain/repository/contact.dart';
import '/l10n/l10n.dart';
import '/routes.dart';
import '/ui/page/home/widget/avatar.dart';
import '/ui/page/home/widget/user_search_bar/view.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/menu_interceptor/menu_interceptor.dart';
import '/ui/widget/text_field.dart';
import 'controller.dart';
import 'search/view.dart';

/// View of the `HomeTab.contacts` tab.
class ContactsTabView extends StatelessWidget {
  const ContactsTabView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> divider = [
      const SizedBox(height: 10),
      Container(
        width: double.infinity,
        color: const Color(0xFFE0E0E0),
        height: 0.5,
      ),
      const SizedBox(height: 10),
    ];

    return GetBuilder(
      key: const Key('ContactsTab'),
      init: ContactsTabController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (ContactsTabController c) {
        Widget tile({
          RxUser? user,
          RxChatContact? contact,
          void Function()? onTap,
          bool selected = false,
        }) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: ContactTile(
              contact: contact,
              user: user,
              darken: 0,
              onTap: onTap,
              selected: selected,
            ),
          );
        }

        return Scaffold(
          appBar: CustomAppBar(
            title: Obx(() {
              Widget child;

              if (c.searching.value) {
                Style style = Theme.of(context).extension<Style>()!;
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
                    child: ReactiveTextField(
                      state: c.search,
                      hint: 'Search',
                      maxLines: 1,
                      filled: false,
                      dense: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      style: style.boldBody.copyWith(fontSize: 17),
                      onChanged: () => c.query.value = c.search.text,
                    ),
                  ),
                );
              } else {
                child = Text('label_contacts'.l10n);
              }

              return AnimatedSwitcher(
                duration: 250.milliseconds,
                child: child,
              );
            }),
            actions: [
              Obx(() {
                Widget child;

                if (c.searching.value) {
                  child = WidgetButton(
                    key: const Key('CloseSearch'),
                    onPressed: () {
                      c.search.clear();
                      c.query.value = null;
                      c.searchResults.value = null;
                      c.searchStatus.value = RxStatus.empty();
                      c.searching.value = false;
                    },
                    child: Padding(
                      padding:
                          const EdgeInsets.only(left: 12, right: 14, top: 2),
                      child: SizedBox(
                        width: 29.69,
                        child: SvgLoader.asset(
                          'assets/icons/close_primary.svg',
                          width: 15,
                          height: 15,
                        ),
                      ),
                    ),
                  );
                } else {
                  child = Obx(() {
                    return WidgetButton(
                      key: Key('${c.sorting.value}'),
                      onPressed: c.sorting.toggle,
                      child: Padding(
                        padding:
                            const EdgeInsets.only(left: 12, right: 14, top: 2),
                        child: SizedBox(
                          width: 29.69,
                          height: 21,
                          child: c.sorting.value
                              ? SvgLoader.asset(
                                  'assets/icons/sort_abc.svg',
                                  width: 30,
                                  height: 21,
                                )
                              : SvgLoader.asset(
                                  'assets/icons/sort_time.svg',
                                  width: 30,
                                  height: 21,
                                ),
                        ),
                      ),
                    );
                  });
                }

                return AnimatedSwitcher(
                  duration: 250.milliseconds,
                  child: child,
                );
              }),
            ],
            leading: [
              Obx(() {
                return WidgetButton(
                  onPressed: c.searching.value
                      ? null
                      : () {
                          if (c.searching.isFalse) {
                            c.searching.value = true;
                            Future.delayed(
                              Duration.zero,
                              c.search.focus.requestFocus,
                            );
                          }
                        },
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20, right: 12),
                    child: SvgLoader.asset(
                      'assets/icons/search.svg',
                      width: 17.77,
                    ),
                  ),
                );
              }),
            ],
          ),
          body: Obx(() {
            Widget? center;

            if (c.query.isNotEmpty == true &&
                c.favorites.isEmpty &&
                c.contacts.isEmpty &&
                c.users.isEmpty) {
              if (c.searchStatus.value.isSuccess) {
                center = Center(child: Text('No user found'.l10n));
              } else {
                center = const Center(child: CustomProgressIndicator());
              }
            }

            bool isSearching = c.searching.value && c.query.isNotEmpty == true;

            ThemeData theme = Theme.of(context);
            final TextStyle? thin =
                theme.textTheme.bodyLarge?.copyWith(color: Colors.black);

            return Column(
              children: [
                AnimatedSizeAndFade.showHide(
                  fadeDuration: 300.milliseconds,
                  sizeDuration: 300.milliseconds,
                  show: c.searching.value && c.query.isNotEmpty == true,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(2, 12, 2, 2),
                    height: 15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        WidgetButton(
                          onPressed: () => c.jumpTo(0),
                          child: Obx(() {
                            return Text(
                              'Chats',
                              style: thin?.copyWith(
                                fontSize: 15,
                                color: c.selected.value == 0
                                    ? const Color(0xFF63B4FF)
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 20),
                        WidgetButton(
                          onPressed: () => c.jumpTo(1),
                          child: Obx(() {
                            return Text(
                              'Contacts',
                              style: thin?.copyWith(
                                fontSize: 15,
                                color: c.selected.value == 1
                                    ? const Color(0xFF63B4FF)
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 20),
                        WidgetButton(
                          onPressed: () => c.jumpTo(2),
                          child: Obx(() {
                            return Text(
                              'Users',
                              style: thin?.copyWith(
                                fontSize: 15,
                                color: c.selected.value == 2
                                    ? const Color(0xFF63B4FF)
                                    : null,
                              ),
                            );
                          }),
                        ),
                        const SizedBox(width: 20),
                        WidgetButton(
                          onPressed: () => c.jumpTo(2),
                          child: Obx(() {
                            return Text(
                              'Messages',
                              style: thin?.copyWith(
                                fontSize: 15,
                                color: c.selected.value == 3
                                    ? const Color(0xFF63B4FF)
                                    : null,
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: center ??
                      ContextMenuInterceptor(
                        child: Obx(() {
                          return CustomScrollView(
                            slivers: [
                              const SliverPadding(
                                padding: EdgeInsets.only(top: 3),
                              ),
                              if (!isSearching) ...[
                                // SliverToBoxAdapter(
                                //   child: Padding(
                                //     padding: const EdgeInsets.symmetric(
                                //       horizontal: 10,
                                //       vertical: 8,
                                //     ),
                                //     child: ContactTile(
                                //       darken: 0,
                                //       myUser: c.myUser.value,
                                //       onTap: router.me,
                                //       radius: 26 + 7,
                                //       subtitle: const [
                                //         SizedBox(height: 5),
                                //         Text(
                                //           'В сети',
                                //           style: TextStyle(
                                //             color: Color(0xFF888888),
                                //           ),
                                //         ),
                                //       ],
                                //     ),
                                //   ),
                                // ),
                                SliverReorderableList(
                                  itemBuilder: (context, i) {
                                    RxChatContact contact =
                                        c.allFavorites.values.elementAt(i);
                                    return MyReorderableDelayedDragStartListener(
                                      key: Key(contact.id.val),
                                      index: i,
                                      child: _contact(context, contact, c),
                                    );
                                  },
                                  itemCount: c.allFavorites.length,
                                  onReorder: (int i, int j) {},
                                ),
                              ],
                              SliverList(
                                delegate: SliverChildListDelegate.fixed(
                                  c.favorites.values.mapIndexed((i, e) {
                                    return _contact(
                                      context,
                                      e,
                                      c,
                                    );
                                  }).toList(),
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildListDelegate.fixed(
                                  c.contacts.values.mapIndexed((i, e) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: i == 0 && c.allFavorites.isEmpty
                                            ? 3
                                            : 0,
                                      ),
                                      child: _contact(
                                        context,
                                        e,
                                        c,
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              SliverList(
                                delegate: SliverChildListDelegate.fixed(
                                  c.users.values.mapIndexed((i, e) {
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        top: i == 0 && c.allFavorites.isEmpty
                                            ? 3
                                            : 0,
                                      ),
                                      child: tile(
                                        user: e,
                                        onTap: () => router.user(e.id),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SliverPadding(
                                padding: EdgeInsets.only(top: 4),
                              ),
                            ],
                          );
                        }),
                      ),
                ),
              ],
            );
          }),
        );
      },
    );
  }

  /// Returns a [ListTile] with [contact]'s information.
  Widget _contact(
    BuildContext context,
    RxChatContact contact,
    ContactsTabController c, {
    bool enlarge = false,
  }) {
    bool favorite = c.allFavorites.values.contains(contact);

    return FutureBuilder<RxChat?>(
      future: c.getChat(contact.user.value!.user.value.dialog?.id),
      builder: (context, snapshot) {
        return Padding(
          key: Key(contact.id.val),
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: ContactTile(
            radius: enlarge ? 30 + 7 : 30,
            // radius: enlarge ? 26 + 7 : 26,
            contact: contact,
            darken: 0,
            folded: favorite,
            onTap: contact.contact.value.users.isNotEmpty
                // TODO: Open [Routes.contact] page when it's implemented.
                ? () => router.user(contact.user.value!.id)
                : null,
            actions: [
              if (favorite)
                ContextMenuButton(
                  label: 'Unfavorite'.l10n,
                  onPressed: () => c.unfavorite(contact),
                )
              else
                ContextMenuButton(
                  label: 'Favorite'.l10n,
                  onPressed: () => c.favorite(contact),
                ),
              if (contact.user.value?.user.value.dialog != null) ...[
                if (snapshot.data?.chat.value.muted != null)
                  ContextMenuButton(
                    label: 'Mute'.l10n,
                    onPressed: () =>
                        c.muteChat(contact.user.value!.user.value.dialog!.id),
                  )
                else
                  ContextMenuButton(
                    label: 'Unmute'.l10n,
                    onPressed: () =>
                        c.unmuteChat(contact.user.value!.user.value.dialog!.id),
                  ),
              ],
              ContextMenuButton(
                label: 'btn_delete_from_contacts'.l10n,
                onPressed: () => c.deleteFromContacts(contact.contact.value),
              ),
            ],
            subtitle: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 5),
                        Obx(() {
                          final subtitle =
                              contact.user.value?.user.value.getStatus();
                          if (subtitle != null) {
                            return Text(
                              subtitle,
                              style: const TextStyle(color: Color(0xFF888888)),
                            );
                          }

                          return Container();
                        }),
                      ],
                    ),
                  ),
                  if (contact.user.value?.user.value.dialog != null &&
                      snapshot.data != null)
                    Obx(() {
                      if (snapshot.data!.chat.value.muted != null) {
                        return Row(
                          children: [
                            const SizedBox(width: 5),
                            SvgLoader.asset(
                              'assets/icons/muted.svg',
                              width: 19.99,
                              height: 15,
                            ),
                            const SizedBox(width: 5),
                          ],
                        );
                      }

                      return const SizedBox();
                    }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class SectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String title;
  final double height;

  SectionHeaderDelegate(this.title, [this.height = 42]);

  @override
  Widget build(context, double shrinkOffset, bool overlapsContent) {
    Style style = Theme.of(context).extension<Style>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: Center(
        child: Container(
          width: double.infinity,
          height: height,
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: style.systemMessageBorder,
            color: style.systemMessageColor.withOpacity(0.99),
          ),
          child: Center(
            child: Text(
              title,
              style: const TextStyle(color: Color(0xFF888888)),
            ),
          ),
        ),
      ),
    );
  }

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(SliverPersistentHeaderDelegate oldDelegate) => false;
}

class MyReorderableDelayedDragStartListener
    extends ReorderableDragStartListener {
  const MyReorderableDelayedDragStartListener({
    super.key,
    required super.child,
    required super.index,
    super.enabled,
  });

  @override
  MultiDragGestureRecognizer createRecognizer() {
    return MyVerticalMultiDragGestureRecognizer(debugOwner: this);
  }
}

class MyVerticalMultiDragGestureRecognizer extends MultiDragGestureRecognizer {
  MyVerticalMultiDragGestureRecognizer({
    super.debugOwner,
    @Deprecated(
      'Migrate to supportedDevices. '
      'This feature was deprecated after v2.3.0-1.0.pre.',
    )
        super.kind,
    super.supportedDevices,
  });

  @override
  MultiDragPointerState createNewPointerState(PointerDownEvent event) {
    return _MyVerticalPointerState(
      event.position,
      event.kind == PointerDeviceKind.touch
          ? 200.milliseconds
          : 10.milliseconds,
      event.kind,
      gestureSettings,
    );
  }

  @override
  String get debugDescription => 'vertical multidrag';
}

class _MyVerticalPointerState extends MultiDragPointerState {
  _MyVerticalPointerState(
    super.initialPosition,
    Duration delay,
    super.kind,
    super.deviceGestureSettings,
  ) {
    _timer = Timer(delay, _delayPassed);
  }

  Timer? _timer;
  GestureMultiDragStartCallback? _starter;

  void _delayPassed() {
    assert(_timer != null);
    _timer = null;

    HapticFeedback.lightImpact();
  }

  void _ensureTimerStopped() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void checkForResolutionAfterMove() {
    assert(pendingDelta != null);

    if (pendingDelta!.dy.abs() > computeHitSlop(kind, gestureSettings) &&
        (_timer == null || kind != PointerDeviceKind.touch)) {
      resolve(GestureDisposition.accepted);
    }
  }

  @override
  void accepted(GestureMultiDragStartCallback starter) {
    assert(_starter == null);
    if ((_timer == null)) {
      starter(initialPosition);
    } else {
      _starter = starter;
    }
  }

  @override
  void dispose() {
    _ensureTimerStopped();
    super.dispose();
  }
}

class MyLongPressDraggable extends Draggable {
  const MyLongPressDraggable({
    super.key,
    required super.child,
    required super.feedback,
    super.data,
    super.axis,
    super.childWhenDragging,
    super.feedbackOffset,
    super.dragAnchorStrategy,
    super.maxSimultaneousDrags,
    super.onDragStarted,
    super.onDragUpdate,
    super.onDraggableCanceled,
    super.onDragEnd,
    super.onDragCompleted,
    super.ignoringFeedbackSemantics,
    super.ignoringFeedbackPointer,
  });

  @override
  MyVerticalMultiDragGestureRecognizer createRecognizer(
      GestureMultiDragStartCallback onStart) {
    return MyVerticalMultiDragGestureRecognizer()
      ..onStart = (Offset position) {
        final Drag? result = onStart(position);
        if (result != null) {
          HapticFeedback.selectionClick();
        }
        return result;
      };
  }
}
