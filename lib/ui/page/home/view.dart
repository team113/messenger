// Copyright © 2022-2024 IT ENGINEERING MANAGEMENT INC,
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
import 'package:messenger/domain/model/user.dart';
import 'package:messenger/ui/widget/context_menu/tile.dart';
import 'package:messenger/util/get.dart';

import '/api/backend/schema.dart' show Presence;
import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/call/widget/scaler.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/context_menu/menu.dart';
import '/ui/widget/context_menu/region.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import '/util/scoped_dependencies.dart';
import 'controller.dart';
import 'overlay/controller.dart';
import 'router.dart';
import 'tab/chats_contacts/controller.dart';
import 'tab/chats_contacts/view.dart';
import 'tab/menu/controller.dart';
import 'tab/balance/view.dart';
import 'tab/publics/view.dart';
import 'tab/work/view.dart';
import 'widget/animated_slider.dart';
import 'widget/avatar.dart';
import 'widget/keep_alive.dart';
import 'widget/navigation_bar.dart';
import 'widget/wallet.dart';

/// View of the [Routes.home] page.
class HomeView extends StatefulWidget {
  const HomeView(
    this._depsFactory, {
    super.key,
    this.signedUp = false,
    this.link,
  });

  /// Indicator whether the [IntroductionView] should be displayed with
  /// [IntroductionViewStage.signUp] initial stage.
  ///
  /// Should also mean that sign up operation just has been occurred.
  final bool signedUp;

  /// [ChatDirectLinkSlug] to display [IntroductionView] with.
  final ChatDirectLinkSlug? link;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backButtonDispatcher = Router.of(context)
        .backButtonDispatcher!
        .createChildBackButtonDispatcher();
  }

  @override
  Widget build(context) {
    final style = Theme.of(context).style;

    if (_deps == null) {
      return Scaffold(
        // For web, background color is displayed in `index.html` file.
        backgroundColor: PlatformUtils.isWeb
            ? style.colors.transparent
            : style.colors.onPrimary,
        body: const Stack(
          children: [
            SvgImage.asset(
              'assets/images/background_light.svg',
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
            ),
            Center(child: CustomProgressIndicator.primary()),
          ],
        ),
      );
    }

    return GetBuilder(
      init: HomeController(
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        Get.find(),
        signedUp: widget.signedUp,
        link: widget.link,
      ),
      builder: (HomeController c) {
        // Claim priority of the "Back" button dispatcher.
        _backButtonDispatcher.takePriority();

        if (!context.isNarrow) {
          c.sideBarWidth.value = c.applySideBarWidth(c.sideBarAllowedWidth);
        }

        // Side bar uses a little trick to be responsive:
        //
        // 1. On mobile, side bar is full-width and the navigator's first page
        //    is transparent, both visually and tactile. As soon as a new page
        //    populates the route stack, it becomes reactive to touches.
        //    Navigator is drawn above the side bar in this case.
        //
        // 2. On desktop/tablet side bar is always shown and occupies the space
        //    determined by the `sideBarWidth` value.
        //    Navigator is drawn under the side bar (so the page animation is
        //    correct).
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
                      child: PageView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: c.pages,
                        onPageChanged: (int i) {
                          router.tab = HomeTab.values[i];
                          c.page.value = router.tab;

                          if (!context.isNarrow) {
                            switch (router.tab) {
                              case HomeTab.menu:
                                router.me();
                                break;

                              default:
                                if (router.route == Routes.me) {
                                  router.home();
                                }
                                break;
                            }
                          }
                        },
                        // [KeepAlivePage] used to keep the tabs' states.
                        children: [
                          // if (c.settings.value?.balanceTabEnabled != false)
                          KeepAlivePage(
                            key: c.keys[HomeTab.balance],
                            child: const BalanceTabView(),
                          ),
                          // if (c.settings.value?.workWithUsTabEnabled != false)
                          KeepAlivePage(
                            key: c.keys[HomeTab.work],
                            child: const WorkTabView(),
                          ),
                          // if (c.settings.value?.publicsTabEnabled != false)
                          KeepAlivePage(
                            key: c.keys[HomeTab.public],
                            child: const PublicsTabView(),
                          ),
                          KeepAlivePage(
                            key: c.keys[HomeTab.chats],
                            child: const ChatsContactsTabView(),
                          ),
                          KeepAlivePage(
                            key: c.keys[HomeTab.menu],
                            child: const MenuTabView(),
                          ),
                        ],
                      ),
                    ),
                    extendBody: true,
                    bottomNavigationBar: SafeArea(
                      child: Obx(() {
                        return AnimatedSlider(
                          duration: 300.milliseconds,
                          isOpen: router.navigation.value,
                          beginOffset: const Offset(0.0, 5),
                          translate: false,
                          child: Obx(() {
                            return CustomNavigationBar(
                              key: c.panelKey,
                              items: c.tabs.map((e) {
                                switch (e) {
                                  case HomeTab.balance:
                                    return CustomNavigationBarItem(
                                      key: const Key('BalanceButton'),
                                      child: ContextMenuRegion(
                                        selector: c.balanceKey,
                                        alignment: Alignment.bottomLeft,
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                          right: 32 + 16,
                                        ),
                                        actions: [
                                          ContextMenuTile(
                                            label: c.displayFunds
                                                ? 'btn_hide_balance'.l10n
                                                : 'btn_display_balance'.l10n,
                                            pinnable: false,
                                            onPressed: (context) {
                                              c.setDisplayFunds(
                                                  !c.displayFunds);
                                              Navigator.of(context).pop();
                                            },
                                            asset: c.displayFunds
                                                ? SvgIcons.showBalance
                                                : SvgIcons.hideBalance,
                                          ),
                                        ],
                                        child: WalletWidget(
                                          key: c.balanceKey,
                                          balance: c.balance.value,
                                          visible: c.displayFunds,
                                        ),
                                      ),
                                    );

                                  case HomeTab.work:
                                    return CustomNavigationBarItem(
                                      key: const Key('PartnerButton'),
                                      badge: c.displayTransactions
                                          ? '${c.transactions.length}'
                                          : null,
                                      child: ContextMenuRegion(
                                        selector: c.partnerKey,
                                        alignment: Alignment.bottomCenter,
                                        margin:
                                            const EdgeInsets.only(bottom: 10),
                                        actions: [
                                          // ...top,
                                          ContextMenuTile(
                                            label: c.displayTransactions
                                                ? 'btn_hide_transactions'.l10n
                                                : 'btn_display_transactions'
                                                    .l10n,
                                            pinnable: false,
                                            onPressed: (context) {
                                              c.setDisplayTransactions(
                                                !c.displayTransactions,
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            asset: c.displayTransactions
                                                ? SvgIcons.showBalance
                                                : SvgIcons.hideBalance,
                                          ),
                                        ],
                                        child: SvgIcon(
                                          SvgIcons.partner,
                                          key: c.partnerKey,
                                        ),
                                      ),
                                    );

                                  case HomeTab.public:
                                    return CustomNavigationBarItem(
                                      key: const Key('PublicButton'),
                                      child: ContextMenuRegion(
                                        selector: c.publicsKey,
                                        alignment: Alignment.bottomCenter,
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        actions: [
                                          // ...top,
                                          ContextMenuTile(
                                            label: c.publicsToggle.value
                                                ? 'btn_unmute_chats'.l10n
                                                : 'btn_mute_chats'.l10n,
                                            pinnable: false,
                                            onPressed: (context) {
                                              c.publicsToggle.toggle();
                                              Navigator.of(context).pop();
                                            },
                                            asset: c.publicsToggle.value
                                                ? SvgIcons.muted22
                                                : SvgIcons.unmuted22,
                                          ),
                                        ],
                                        child: Transform.translate(
                                          key: c.publicsKey,
                                          offset: const Offset(0, 1),
                                          child: Obx(() {
                                            return SvgIcon(
                                              c.publicsToggle.value
                                                  ? SvgIcons.publicsMuted
                                                  : SvgIcons.publics,
                                            );
                                          }),
                                        ),
                                      ),
                                    );

                                  case HomeTab.chats:
                                    return CustomNavigationBarItem(
                                      badge: c.unreadChats.value == 0
                                          ? null
                                          : '${c.unreadChats.value}',
                                      badgeColor: c.myUser.value?.muted != null
                                          ? style
                                              .colors.secondaryHighlightDarkest
                                          : style.colors.danger,
                                      onPressed: () {
                                        if (Get.isRegistered<
                                            ChatsContactsTabController>()) {
                                          Get.find<ChatsContactsTabController>()
                                              .switched
                                              .value = false;
                                        }
                                      },
                                      child: ContextMenuRegion(
                                        key: const Key('ChatsButton'),
                                        selector: c.chatsKey,
                                        alignment: Alignment.bottomCenter,
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        actions: [
                                          // ...top,
                                          ContextMenuBuilder((p) {
                                            final c = Get.findOrNull<
                                                ChatsContactsTabController>();

                                            if (c == null) {
                                              return const SizedBox();
                                            }

                                            return ContextMenuTile(
                                              label: c.switched.value
                                                  ? 'label_chats'.l10n
                                                  : 'label_contacts'.l10n,
                                              onPressed: (_) =>
                                                  c.switched.toggle(),
                                              asset: c.switched.value
                                                  ? SvgIcons.chatsSwitch
                                                  : SvgIcons.contactsSwitch,
                                              pinnable: false,
                                            );
                                          }),
                                          const ContextMenuDivider(),
                                          ContextMenuTile(
                                            label: c.myUser.value?.muted != null
                                                ? 'btn_unmute_chats'.l10n
                                                : 'btn_mute_chats'.l10n,
                                            pinnable: false,
                                            onPressed: (context) {
                                              c.toggleMute(
                                                c.myUser.value?.muted != null,
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            // trailing: true,
                                            asset: c.myUser.value?.muted != null
                                                ? SvgIcons.muted22
                                                : SvgIcons.unmuted22,
                                          ),
                                        ],
                                        child: Obx(() {
                                          final Widget child;

                                          if (c.myUser.value?.muted != null) {
                                            child = const SvgIcon(
                                              SvgIcons.chatsMuted,
                                              key: Key('Muted'),
                                            );
                                          } else {
                                            child = Transform.translate(
                                              offset: const Offset(0, 0.5),
                                              child: const SvgIcon(
                                                SvgIcons.chats,
                                                key: Key('Unmuted'),
                                              ),
                                            );
                                          }

                                          return SafeAnimatedSwitcher(
                                            key: c.chatsKey,
                                            duration: 200.milliseconds,
                                            child: child,
                                          );
                                        }),
                                      ),
                                    );

                                  case HomeTab.menu:
                                    return CustomNavigationBarItem(
                                      child: ContextMenuRegion(
                                        key: const Key('MenuButton'),
                                        selector: c.panelKey,
                                        alignment: Alignment.bottomRight,
                                        margin: const EdgeInsets.only(
                                          bottom: 4,
                                          left: 8,
                                        ),
                                        actions: [
                                          ContextMenuTile(
                                            asset: SvgIcons.addAccount,
                                            label: 'Добавить аккаунт'.l10n,
                                            pinnable: false,
                                          ),
                                          const ContextMenuDivider(),
                                          ContextMenuTile(
                                            label:
                                                'label_presence_present'.l10n,
                                            pinnable: false,
                                            onPressed: (context) {
                                              c.setPresence(Presence.present);
                                              // Navigator.of(context).pop();
                                            },
                                            trailing: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: style
                                                    .colors.acceptAuxiliary,
                                              ),
                                            ),
                                          ),
                                          ContextMenuTile(
                                            label: 'label_presence_away'.l10n,
                                            pinnable: false,
                                            onPressed: (context) {
                                              c.setPresence(Presence.away);
                                              // Navigator.of(context).pop();
                                            },
                                            trailing: Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: style.colors.warning,
                                              ),
                                            ),
                                          ),
                                        ],
                                        child: AvatarWidget.fromMyUser(
                                          c.myUser.value,
                                          key: c.profileKey,
                                          radius: AvatarRadius.medium,
                                        ),
                                      ),
                                    );
                                }
                              }).toList(),
                              currentIndex: router.tab.index,
                              onTap: c.pages.jumpToPage,
                            );
                          }),
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

        // Nested navigation widget that displays [navigator] in an [Expanded]
        // to take all the remaining from the [sideBar] space.
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

        // Navigator should be drawn under or above the [sideBar] for the
        // animations to look correctly.
        //
        // [SizedBox]es are required for the [sideBar] to keep its state.
        // Otherwise, [Stack] widget will be updated, which will lead its
        // children to be updated as well.
        return CallOverlayView(
          child: Obx(() {
            return Stack(
              key: const Key('HomeView'),
              children: [
                _background(c),
                if (c.authStatus.value.isSuccess) ...[
                  SizedBox(child: context.isNarrow ? null : navigation),
                  sideBar,
                  SizedBox(child: context.isNarrow ? navigation : null),
                ] else
                  const Scaffold(
                    body: Center(child: CustomProgressIndicator.primary()),
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
    final style = Theme.of(context).style;

    return Positioned.fill(
      child: IgnorePointer(
        child: Obx(() {
          final Widget image;
          if (c.background.value != null) {
            image = Image.memory(
              c.background.value!,
              width: double.infinity,
              height: double.infinity,
              key: Key('Background_${c.background.value?.lengthInBytes}'),
              fit: BoxFit.cover,
            );
          } else {
            image = const SizedBox();
          }

          return Stack(
            children: [
              const Positioned.fill(
                child: SvgImage.asset(
                  'assets/images/background_light.svg',
                  key: Key('DefaultBackground'),
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: SafeAnimatedSwitcher(
                  duration: 250.milliseconds,
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
