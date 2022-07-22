// Copyright © 2022 IT ENGINEERING MANAGEMENT INC, <https://github.com/team113>
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

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import '/routes.dart';
import '/util/platform_utils.dart';
import '/util/scoped_dependencies.dart';
import 'controller.dart';
import '/l10n/l10n.dart';
import 'overlay/controller.dart';
import 'router.dart';
import 'tab/chats/controller.dart';
import 'tab/contacts/controller.dart';
import 'tab/menu/controller.dart';
import 'widget/keep_alive.dart';
import 'widget/navigation_bar.dart';

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
class _HomeViewState extends State<HomeView>
    with SingleTickerProviderStateMixin {
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
    if (_deps == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return GetBuilder(
      init: HomeController(Get.find(), Get.find()),
      builder: (HomeController c) {
        /// Claim priority of the "Back" button dispatcher.
        _backButtonDispatcher.takePriority();

        /// Side bar uses a little trick to be responsive:
        ///
        /// 1. On mobile, side bar is full-width and the navigator's first page
        ///    is transparent, both visually and tactile. As soon as a new page
        ///    populates the route stack, it becomes reactive to touches.
        ///    Navigator is drawn above the side bar in this case.
        ///
        /// 2. On desktop/tablet side bar is always shown and occupies the space
        ///    stated by `Config` variables (`maxSideBarExpandWidth` and
        ///    `sideBarWidthPercentage`).
        ///    Navigator is drawn under the side bar (so the page animation is
        ///    correct).
        final sideBar = Row(
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: context.isMobile
                    ? context.width
                    : context.width > HomeController.maxSideBarExpandWidth
                        ? HomeController.maxSideBarExpandWidth *
                            HomeController.sideBarWidthPercentage
                        : context.width * HomeController.sideBarWidthPercentage,
              ),
              child: Scaffold(
                body: Listener(
                  onPointerSignal: (s) {
                    if (s is PointerScrollEvent) {
                      if (s.scrollDelta.dx.abs() < 3 &&
                          (s.scrollDelta.dy.abs() > 3 ||
                              c.verticalScrollTimer.value != null)) {
                        _resetVerticalScroll(c);
                      }
                    }
                  },
                  child: Obx(() {
                    return PageView(
                      physics: c.verticalScrollTimer.value == null
                          ? null
                          : const NeverScrollableScrollPhysics(),
                      controller: c.pages,
                      onPageChanged: (i) => router.tab = HomeTab.values[i],

                      /// [KeepAlivePage] used to keep the tabs' states.
                      children: const [
                        KeepAlivePage(child: ContactsTabView()),
                        KeepAlivePage(child: ChatsTabView()),
                        KeepAlivePage(child: MenuTabView()),
                      ],
                    );
                  }),
                ),
                bottomNavigationBar: SafeArea(
                  child: Obx(
                    () => CustomNavigationBar(
                      selectedColor: Colors.blue,
                      unselectedColor: const Color(0xA6818181),
                      size: 20,
                      items: [
                        CustomNavigationBarItem(
                          key: const Key('ContactsButton'),
                          icon: FontAwesomeIcons.solidCircleUser,
                          label: 'label_tab_contacts'.l10n,
                        ),
                        CustomNavigationBarItem(
                            key: const Key('ChatsButton'),
                            icon: FontAwesomeIcons.solidComment,
                            label: 'label_tab_chats'.l10n,
                            badge: c.unreadChatsCount.value == 0
                                ? null
                                : '${c.unreadChatsCount.value}'),
                        CustomNavigationBarItem(
                          key: const Key('MenuButton'),
                          icon: FontAwesomeIcons.bars,
                          label: 'label_tab_menu'.l10n,
                        ),
                      ],
                      currentIndex: router.tab.index,
                      onTap: (i) => c.pages.jumpToPage(i),
                    ),
                  ),
                ),
              ),
            ),
            if (!context.isMobile)
              const VerticalDivider(
                width: 0.5,
                thickness: 0.5,
                color: Color(0xFFE0E0E0),
              )
          ],
        );

        /// Nested navigation widget that displays [navigator] in an [Expanded]
        /// to take all the remaining from the [sideBar] space.
        Widget navigation = IgnorePointer(
          ignoring: router.route == Routes.home && context.isMobile,
          child: LayoutBuilder(
            builder: (context, constraints) => Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.isMobile
                        ? 0
                        : context.width > HomeController.maxSideBarExpandWidth
                            ? HomeController.maxSideBarExpandWidth *
                                HomeController.sideBarWidthPercentage
                            : context.width *
                                HomeController.sideBarWidthPercentage,
                  ),
                  child: Container(),
                ),
                Expanded(
                  child: Router(
                    routerDelegate: _routerDelegate,
                    backButtonDispatcher: _backButtonDispatcher,
                  ),
                ),
              ],
            ),
          ),
        );

        /// Navigator should be drawn under or above the [sideBar] for the
        /// animations to look correctly.
        ///
        /// [Container]s are required for the [sideBar] to keep its state.
        /// Otherwise, [Stack] widget will be updated, which will lead its
        /// children to be updated as well.
        return CallOverlayView(
          child: Obx(() => c.authStatus.value.isSuccess
              ? Stack(
                  key: const Key('HomeView'),
                  children: [
                    Container(child: context.isMobile ? null : navigation),
                    sideBar,
                    Container(child: context.isMobile ? navigation : null),
                  ],
                )
              : const Scaffold(
                  body: Center(child: CircularProgressIndicator()))),
        );
      },
    );
  }

  /// Cancels a [_verticalScrollTimer] and starts it again with the provided
  /// [duration].
  ///
  /// Defaults to 150 milliseconds if no [duration] is provided.
  void _resetVerticalScroll(HomeController c, [Duration? duration]) {
    c.verticalScrollTimer.value?.cancel();
    c.verticalScrollTimer.value = Timer(duration ?? 150.milliseconds, () {
      c.verticalScrollTimer.value = null;
    });
  }
}
