// Copyright © 2022-2025 IT ENGINEERING MANAGEMENT INC,
//                       <https://github.com/team113>
// Copyright © 2025 Ideas Networks Solutions S.A.,
//                       <https://github.com/tapopa>
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

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '/domain/model/user.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/call/widget/conditional_backdrop.dart';
import '/ui/page/call/widget/scaler.dart';
import '/ui/widget/animated_switcher.dart';
import '/ui/widget/progress_indicator.dart';
import '/ui/widget/svg/svg.dart';
import '/ui/widget/upgrade_available_button.dart';
import '/ui/worker/upgrade.dart';
import '/util/platform_utils.dart';
import '/util/scoped_dependencies.dart';
import 'controller.dart';
import 'overlay/controller.dart';
import 'router.dart';
import 'tab/chats/controller.dart';
import 'tab/menu/controller.dart';
import 'tab/partner/view.dart';
import 'tab/wallet/view.dart';
import 'widget/animated_slider.dart';
import 'widget/keep_alive.dart';
import 'widget/navigation_bar.dart';

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
  final Future<ScopedDependencies?> Function() _depsFactory;

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

  /// [Sentry] transaction monitoring this [HomeView] readiness.
  final ISentrySpan _ready = Sentry.startTransaction(
    'ui.home.ready',
    'ui',
    autoFinishAfter: const Duration(minutes: 2),
  )..startChild('ready');

  @override
  void initState() {
    super.initState();

    widget._depsFactory().then((v) {
      setState(() => _deps = v);
      SchedulerBinding.instance.addPostFrameCallback((_) => _ready.finish());

      if (v == null) {
        router.auth();
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _deps?.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _backButtonDispatcher = Router.of(
      context,
    ).backButtonDispatcher!.createChildBackButtonDispatcher();
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
        signedUp: widget.signedUp,
        link: widget.link,
        context: context,
      ),
      builder: (HomeController c) {
        // Claim priority of the "Back" button dispatcher.
        _backButtonDispatcher.takePriority();

        if (!context.isNarrow) {
          c.sideBarWidth.value = c.applySideBarWidth(
            context,
            c.sideBarAllowedWidth,
          );
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
                    body: PageView(
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
                      children: const [
                        KeepAlivePage(child: WalletTabView()),
                        KeepAlivePage(child: PartnerTabView()),
                        KeepAlivePage(child: ChatsTabView()),
                        KeepAlivePage(child: MenuTabView()),
                      ],
                    ),
                    bottomNavigationBar: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _upgradePopup(context, c),
                        _navigation(context, c),
                      ],
                    ),
                  ),
                );
              }),
              if (!context.isNarrow)
                MouseRegion(
                  cursor: SystemMouseCursors.resizeLeftRight,
                  child: Scaler(
                    onDragStart: (_) => c.sideBarWidth.value = c
                        .applySideBarWidth(context, c.sideBarWidth.value),
                    onDragUpdate: (dx, _) => c.sideBarWidth.value = c
                        .applySideBarWidth(context, c.sideBarWidth.value + dx),
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
        final Widget navigation = IgnorePointer(
          ignoring: router.route == Routes.home && context.isNarrow,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Row(
                children: [
                  Obx(() {
                    final double width = c.sideBarWidth.value;
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: context.isNarrow ? 0 : width,
                      ),
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
            },
          ),
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
                  ),
              ],
            );
          }),
        );
      },
    );
  }

  /// Builds a [CustomNavigationBar].
  Widget _navigation(BuildContext context, HomeController c) {
    final style = Theme.of(context).style;

    return Obx(() {
      final List<HomeTab> tabs = c.tabs;

      return Stack(
        children: [
          AnimatedSlider(
            duration: 300.milliseconds,
            isOpen: router.navigation.value,
            beginOffset: const Offset(0.0, 5),
            translate: false,
            child: CustomNavigationBar(
              key: c.panelKey,
              items: tabs.map((e) {
                switch (e) {
                  case HomeTab.wallet:
                    return Obx(() {
                      return CustomNavigationBarItem.wallet(
                        balance: c.purse.value,
                      );
                    });

                  case HomeTab.partner:
                    return CustomNavigationBarItem.partner(
                      balance: c.income.value,
                    );

                  case HomeTab.chats:
                    return Obx(() {
                      return CustomNavigationBarItem.chats(
                        unread: c.unreadChats.value.toString(),
                        danger: c.myUser.value?.muted == null,
                        selector: c.chatsKey,
                        onMute: c.toggleMute,
                      );
                    });

                  case HomeTab.menu:
                    return Obx(() {
                      return CustomNavigationBarItem.menu(
                        acceptAuxiliary: style.colors.acceptAuxiliary,
                        warning: style.colors.warning,
                        onPresence: c.setPresence,
                        onAvatar: c.updateAvatar,
                        selector: c.panelKey,
                        myUser: c.myUser.value,
                      );
                    });
                }
              }).toList(),
              currentIndex: tabs.indexOf(router.tab),
              onTap: (i) {
                c.pages.jumpToPage(tabs[i].index);
              },
            ),
          ),
          ?router.navigator.value?.call(context),
        ],
      );
    });
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

  /// Builds an upgrade available popup displaying the latest [Release], if any.
  Widget _upgradePopup(BuildContext context, HomeController c) {
    return Obx(() {
      if (c.scheduled.value == null) {
        return SizedBox();
      }

      return Padding(
        key: Key('UpgradeAlert'),
        padding: const EdgeInsets.only(bottom: 6),
        child: UpgradeAvailableButton(
          scheduled: c.scheduled.value!,
          download: c.activeDownload.value,
          onClose: () => c.scheduled.value = null,
        ),
      );
    });
  }
}
