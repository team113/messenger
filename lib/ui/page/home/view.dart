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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/api/backend/schema.dart' show Presence;
import 'package:messenger/l10n/l10n.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';

import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/call/widget/scaler.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/scoped_dependencies.dart';
import 'controller.dart';
import 'overlay/controller.dart';
import 'router.dart';
import 'tab/chats_contacts/controller.dart';
import 'tab/chats_contacts/view.dart';
import 'tab/partner/view.dart';
import 'tab/menu/controller.dart';
import 'tab/balance/view.dart';
import 'tab/publics/view.dart';
import 'widget/animated_slider.dart';
import 'widget/avatar.dart';
import 'widget/keep_alive.dart';
import 'widget/navigation_bar.dart';
import 'widget/wallet.dart';

/// View of the [Routes.home] page.
class HomeView extends StatefulWidget {
  const HomeView(this._depsFactory, {Key? key}) : super(key: key);

  /// [ScopedDependencies] factory of [Routes.home] page.
  final Future<ScopedDependencies> Function() _depsFactory;

  @override
  State<HomeView> createState() => _HomeViewState();
}

/// State of the [Routes.home] page.
///
/// State is required for [BuildContext] to be acquired.
class _HomeViewState extends State<HomeView> {
  /// [HomeRouterDelegate] for the nested [Router].
  final HomeRouterDelegate _routerDelegate = HomeRouterDelegate(router);

  /// [Routes.home] page dependencies.
  ScopedDependencies? _deps;

  /// [ChildBackButtonDispatcher] to get "Back" button in the nested [Router].
  late ChildBackButtonDispatcher _backButtonDispatcher;

  @override
  void initState() {
    super.initState();
    widget._depsFactory().then((v) => setState(() => _deps = v));
  }

  @override
  void dispose() {
    super.dispose();
    _deps?.dispose();
  }

  /// Called when a dependency of this [State] object changes.
  ///
  /// Used to get the [Router] widget from context.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backButtonDispatcher = Router.of(context)
        .backButtonDispatcher!
        .createChildBackButtonDispatcher();
  }

  @override
  Widget build(context) {
    final Style style = Theme.of(context).extension<Style>()!;

    if (_deps == null) {
      return Scaffold(
        backgroundColor: style.colors.onPrimary,
        body: const Center(child: CustomProgressIndicator()),
      );
    }

    return GetBuilder(
      init: HomeController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
      ),
      builder: (HomeController c) {
        /// Claim priority of the "Back" button dispatcher.
        _backButtonDispatcher.takePriority();

        if (!context.isNarrow) {
          c.sideBarWidth.value = c.applySideBarWidth(c.sideBarAllowedWidth);
        }

        /// Side bar uses a little trick to be responsive:
        ///
        /// 1. On mobile, side bar is full-width and the navigator's first page
        ///    is transparent, both visually and tactile. As soon as a new page
        ///    populates the route stack, it becomes reactive to touches.
        ///    Navigator is drawn above the side bar in this case.
        ///
        /// 2. On desktop/tablet side bar is always shown and occupies the space
        ///    determined by the `sideBarWidth` value.
        ///    Navigator is drawn under the side bar (so the page animation is
        ///    correct).
        final sideBar = AnimatedOpacity(
          duration: 200.milliseconds,
          opacity: context.isNarrow && router.route != Routes.home ? 0 : 1,
          child: Row(
            children: [
              Obx(() {
                double width = c.sideBarWidth.value;
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.isNarrow ? context.width : width,
                  ),
                  child: Scaffold(
                    backgroundColor: style.sidebarColor,
                    body: Listener(
                      onPointerSignal: (s) {
                        if (s is PointerScrollEvent) {
                          if (s.scrollDelta.dx.abs() < 3 &&
                              (s.scrollDelta.dy.abs() > 3 ||
                                  c.verticalScrollTimer.value != null)) {
                            c.verticalScrollTimer.value?.cancel();
                            c.verticalScrollTimer.value = Timer(
                              300.milliseconds,
                              () => c.verticalScrollTimer.value = null,
                            );
                          }
                        }
                      },
                      child: Obx(() {
                        return PageView(
                          physics: c.verticalScrollTimer.value == null &&
                                  router.navigation.value
                              ? null
                              : const NeverScrollableScrollPhysics(),
                          controller: c.pages,
                          onPageChanged: (int i) {
                            router.tab = HomeTab.values[i];
                            c.page.value = router.tab;
                          },

                          // [KeepAlivePage] used to keep the tabs' states.
                          children: const [
                            KeepAlivePage(child: BalanceTabView()),
                            KeepAlivePage(child: PartnerTabView()),
                            KeepAlivePage(child: PublicsTabView()),
                            KeepAlivePage(child: ChatsContactsTabView()),
                            KeepAlivePage(child: MenuTabView()),
                          ],
                        );
                      }),
                    ),
                    extendBody: true,
                    bottomNavigationBar: SafeArea(
                      child: Obx(() {
                        return AnimatedSlider(
                          duration: 300.milliseconds,
                          isOpen: router.navigation.value,
                          beginOffset: const Offset(0.0, 5),
                          translate: false,
                          child: CustomNavigationBar(
                            items: [
                              CustomNavigationBarItem(
                                key: const Key('BalanceButton'),
                                // child: RmbDetector(
                                //   onPressed: () =>
                                //       BalanceMoreView.show(context),
                                child: ContextMenuRegion(
                                  selector: c.balanceKey,
                                  alignment: Alignment.bottomLeft,
                                  margin: const EdgeInsets.only(
                                    bottom: 4,
                                    right: 32 + 8,
                                  ),
                                  actions: [
                                    if (c.displayFunds)
                                      ContextMenuButton(
                                        label: 'btn_hide_balance'.l10n,
                                        onPressed: () {
                                          c.setDisplayFunds(false);
                                        },
                                      )
                                    else
                                      ContextMenuButton(
                                        label: 'btn_display_balance'.l10n,
                                        onPressed: () {
                                          c.setDisplayFunds(true);
                                        },
                                      ),
                                  ],
                                  child: WalletWidget(
                                    key: c.balanceKey,
                                    balance: c.balance.value,
                                    visible: c.displayFunds,
                                  ),
                                ),
                              ),
                              CustomNavigationBarItem(
                                key: const Key('PartnerButton'),
                                badge: c.displayTransactions
                                    ? '${c.transactions.length}'
                                    : null,
                                // child: RmbDetector(
                                //   onPressed: () =>
                                //       PartnerMoreView.show(context),
                                //   child:
                                child: ContextMenuRegion(
                                  selector: c.partnerKey,
                                  alignment: Alignment.bottomCenter,
                                  margin: const EdgeInsets.only(
                                    bottom: 4,
                                    right: 40,
                                  ),
                                  actions: [
                                    if (c.displayTransactions)
                                      ContextMenuButton(
                                        label: 'btn_hide_transactions'.l10n,
                                        onPressed: () {
                                          c.setDisplayTransactions(false);
                                        },
                                      )
                                    else
                                      ContextMenuButton(
                                        label: 'btn_display_transactions'.l10n,
                                        onPressed: () {
                                          c.setDisplayTransactions(true);
                                        },
                                      ),
                                  ],
                                  child: SvgImage.asset(
                                    'assets/icons/partner16.svg',
                                    key: c.partnerKey,
                                    width: 36,
                                    height: 28,
                                  ),
                                ),
                              ),
                              CustomNavigationBarItem(
                                key: const Key('PublicButton'),
                                // child: RmbDetector(
                                //   onPressed: () =>
                                //       PublicsMoreView.show(context),
                                //   child:
                                child: ContextMenuRegion(
                                  selector: c.publicsKey,
                                  alignment: Alignment.bottomCenter,
                                  margin: const EdgeInsets.only(
                                    bottom: 4,
                                    right: 40,
                                  ),
                                  actions: [
                                    if (c.publicsToggle.value)
                                      ContextMenuButton(
                                        label: 'btn_unmute_chats'.l10n,
                                        onPressed: () {
                                          c.publicsToggle.toggle();
                                        },
                                      )
                                    else
                                      ContextMenuButton(
                                        label: 'btn_mute_chats'.l10n,
                                        onPressed: () {
                                          c.publicsToggle.toggle();
                                        },
                                      ),
                                  ],
                                  child: Transform.translate(
                                    key: c.publicsKey,
                                    offset: const Offset(0, 1),
                                    child: Obx(() {
                                      return SvgImage.asset(
                                        c.publicsToggle.value
                                            ? 'assets/icons/publics_muted6.svg'
                                            : 'assets/icons/publics13.svg',
                                        width: 32,
                                        height: 31,
                                      );
                                    }),
                                  ),
                                ),
                              ),
                              CustomNavigationBarItem(
                                key: const Key('ChatsButton'),
                                badge: c.unreadChatsCount.value == 0
                                    ? null
                                    : '${c.unreadChatsCount.value}',
                                badgeColor: c.myUser.value?.muted != null
                                    ? style.colors.secondaryHighlightDarkest
                                    : style.colors.dangerColor,
                                onPressed: () {
                                  if (Get.isRegistered<
                                      ChatsContactsTabController>()) {
                                    Get.find<ChatsContactsTabController>()
                                        .switched
                                        .value = false;
                                  }
                                },
                                child:
                                    // RmbDetector(
                                    //   onPressed: context.isMobile
                                    //       ? () {
                                    //           HapticFeedback.lightImpact();
                                    //           ChatsMoreView.show(context);
                                    //         }
                                    //       : null,
                                    ContextMenuRegion(
                                  selector: c.chatsKey,
                                  alignment: Alignment.bottomCenter,
                                  margin: const EdgeInsets.only(
                                    bottom: 4,
                                    right: 0,
                                  ),
                                  actions: [
                                    if (c.myUser.value?.muted != null)
                                      ContextMenuButton(
                                        label: 'btn_unmute_chats'.l10n,
                                        onPressed: () {
                                          c.toggleMute(true);
                                        },
                                        // trailing: const Icon(Icons.group_outlined),
                                      )
                                    else
                                      ContextMenuButton(
                                        label: 'btn_mute_chats'.l10n,
                                        onPressed: () {
                                          c.toggleMute(false);
                                        },
                                        // trailing: const Icon(Icons.select_all),
                                      ),
                                  ],
                                  child: Obx(() {
                                    final Widget child;

                                    if (c.myUser.value?.muted != null) {
                                      child = SvgImage.asset(
                                        'assets/icons/chats_muted5.svg',
                                        key: const Key('Muted'),
                                        width: 39.26,
                                        height: 33.5,
                                      );
                                    } else {
                                      child = Transform.translate(
                                        offset: const Offset(0, 0.5),
                                        child: SvgImage.asset(
                                          'assets/icons/chats6.svg',
                                          key: const Key('Unmuted'),
                                          width: 39.26,
                                          height: 33.5,
                                        ),
                                      );
                                    }

                                    return AnimatedSwitcher(
                                      key: c.chatsKey,
                                      duration: 200.milliseconds,
                                      layoutBuilder: (child, previous) {
                                        return Stack(
                                          alignment: Alignment.center,
                                          children: [
                                            ...previous,
                                            if (child != null) child,
                                          ],
                                        );
                                      },
                                      child: child,
                                    );
                                  }),
                                ),
                                // ),
                              ),
                              CustomNavigationBarItem(
                                key: const Key('MenuButton'),
                                // child: RmbDetector(
                                //   onPressed: context.isMobile
                                //       ? () {
                                //           HapticFeedback.lightImpact();
                                //           StatusView.show(context);
                                //         }
                                //       : null,
                                child: ContextMenuRegion(
                                  selector: c.profileKey,
                                  alignment: Alignment.bottomRight,
                                  margin: const EdgeInsets.only(
                                    bottom: 4,
                                    right: 0,
                                  ),
                                  actions: [
                                    ContextMenuButton(
                                      label: 'label_presence_present'.l10n,
                                      withTrailing: true,
                                      onPressed: () {
                                        c.setPresence(Presence.present);
                                      },
                                      trailing: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.green,
                                        ),
                                      ),
                                      // trailing: const Icon(Icons.group_outlined),
                                    ),
                                    ContextMenuButton(
                                      label: 'label_presence_away'.l10n,
                                      withTrailing: true,
                                      onPressed: () {
                                        c.setPresence(Presence.away);
                                      },
                                      trailing: Container(
                                        width: 10,
                                        height: 10,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      // trailing: const Icon(Icons.select_all),
                                    ),
                                  ],
                                  child: AvatarWidget.fromMyUser(
                                    c.myUser.value,
                                    key: c.profileKey,
                                    radius: 16,
                                  ),
                                ),
                                // ),
                              ),
                            ],
                            currentIndex: router.tab.index,
                            onTap: c.pages.jumpToPage,
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }),
              if (!context.isNarrow)
                MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Scaler(
                    onDragStart: (_) => c.sideBarWidth.value =
                        c.applySideBarWidth(c.sideBarWidth.value),
                    onDragUpdate: (dx, _) => c.sideBarWidth.value =
                        c.applySideBarWidth(c.sideBarWidth.value + dx),
                    onDragEnd: (_) => c.setSideBarWidth(),
                    width: 7,
                    height: context.height,
                  ),
                ),
            ],
          ),
        );

        /// Nested navigation widget that displays [navigator] in an [Expanded]
        /// to take all the remaining from the [sideBar] space.
        Widget navigation = IgnorePointer(
          ignoring: router.route == Routes.home && context.isNarrow,
          child: LayoutBuilder(builder: (context, constraints) {
            return Row(
              children: [
                Obx(() {
                  double width = c.sideBarWidth.value;
                  return ConstrainedBox(
                    constraints:
                        BoxConstraints(maxWidth: context.isNarrow ? 0 : width),
                    child: Container(),
                  );
                }),
                Expanded(
                  child: Router(
                    routerDelegate: _routerDelegate,
                    backButtonDispatcher: _backButtonDispatcher,
                  ),
                ),
              ],
            );
          }),
        );

        /// Navigator should be drawn under or above the [sideBar] for the
        /// animations to look correctly.
        ///
        /// [Container]s are required for the [sideBar] to keep its state.
        /// Otherwise, [Stack] widget will be updated, which will lead its
        /// children to be updated as well.
        return CallOverlayView(
          child: Obx(() {
            return Stack(
              key: const Key('HomeView'),
              children: [
                Container(
                  color: style.colors.onPrimary,
                  width: double.infinity,
                  height: double.infinity,
                ),
                _background(c),
                if (c.authStatus.value.isSuccess) ...[
                  Container(child: context.isNarrow ? null : navigation),
                  sideBar,
                  Container(child: context.isNarrow ? navigation : null),
                ] else
                  const Scaffold(
                    body: Center(child: CustomProgressIndicator()),
                  )
              ],
            );
          }),
        );
      },
    );
  }

  /// Builds the [HomeController.background] visual representation.
  Widget _background(HomeController c) {
    final Style style = Theme.of(context).extension<Style>()!;

    return Positioned.fill(
      child: IgnorePointer(
        child: Obx(() {
          final Widget image;
          if (c.background.value != null) {
            image = Image.memory(
              c.background.value!,
              key: Key('Background_${c.background.value?.lengthInBytes}'),
              fit: BoxFit.cover,
            );
          } else {
            image = const SizedBox();
          }

          return Stack(
            children: [
              Positioned.fill(
                child: SvgImage.asset(
                  'assets/images/background_light.svg',
                  key: const Key('DefaultBackground'),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: AnimatedSwitcher(
                  duration: 250.milliseconds,
                  layoutBuilder: (child, previous) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [...previous, if (child != null) child]
                          .map((e) => Positioned.fill(child: e))
                          .toList(),
                    );
                  },
                  child: image,
                ),
              ),
              Positioned.fill(
                child: ColoredBox(color: style.colors.onBackgroundOpacity7),
              ),
              if (!context.isNarrow) ...[
                Row(
                  children: [
                    ConditionalBackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                      child: Obx(() {
                        double width = c.sideBarWidth.value;
                        return ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: context.isNarrow ? 0 : width,
                          ),
                          child: const SizedBox.expand(),
                        );
                      }),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: style.colors.onBackgroundOpacity2,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        }),
      ),
    );
  }
}
