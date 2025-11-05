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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/l10n/l10n.dart';
import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/safe_scrollbar.dart';
import '/ui/widget/animated_button.dart';
import '/ui/widget/svg/svg.dart';
import '/util/platform_utils.dart';
import 'controller.dart';
import 'router.dart';
import 'widget/vacancy_button.dart';

/// View of the [Routes.work] page.
class WorkView extends StatefulWidget {
  const WorkView({super.key});

  @override
  State<WorkView> createState() => _WorkViewState();
}

/// State of the [Routes.work] page.
///
/// State is required for [_backButtonDispatcher] to be acquired.
class _WorkViewState extends State<WorkView> {
  /// [WorkRouterDelegate] for the nested [Router].
  final WorkRouterDelegate _routerDelegate = WorkRouterDelegate(router);

  /// [ChildBackButtonDispatcher] to get "Back" button in the nested [Router].
  late ChildBackButtonDispatcher _backButtonDispatcher;

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

    return GetBuilder(
      init: WorkController(),
      builder: (WorkController c) {
        // Claim priority of the "Back" button dispatcher.
        _backButtonDispatcher.takePriority();

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
        final sideBar = Obx(() {
          final bool isWork = router.routes.lastOrNull == Routes.work;
          return AnimatedOpacity(
            duration: 200.milliseconds,
            opacity: context.isNarrow && !isWork ? 0 : 1,
            child: Row(
              children: [
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: context.isNarrow ? context.width : 350,
                  ),
                  child: Scaffold(
                    backgroundColor: style.sidebarColor,
                    appBar: CustomAppBar(
                      leading: [
                        AnimatedButton(
                          decorator: (child) => Container(
                            margin: const EdgeInsets.only(left: 18),
                            height: double.infinity,
                            child: Center(child: child),
                          ),
                          onPressed: router.auth,
                          child: const Center(child: SvgIcon(SvgIcons.home)),
                        ),
                      ],
                      title: Text('label_work_with_us'.l10n),
                      actions: [
                        AnimatedButton(
                          decorator: (child) => Container(
                            padding: const EdgeInsets.only(right: 18),
                            height: double.infinity,
                            child: Center(child: child),
                          ),
                          onPressed: () {
                            // No-op.
                          },
                          child: const Padding(
                            padding: EdgeInsets.fromLTRB(10, 0, 10, 0),
                            child: SvgIcon(SvgIcons.more),
                          ),
                        ),
                      ],
                    ),
                    body: SafeScrollbar(
                      controller: c.scrollController,
                      child: ListView.builder(
                        controller: c.scrollController,
                        itemCount: WorkTab.values.length,
                        itemBuilder: (_, i) {
                          final WorkTab e = WorkTab.values[i];

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 1.5),
                            child: VacancyWorkButton(e),
                          );
                        },
                      ),
                    ),
                    extendBody: true,
                    extendBodyBehindAppBar: true,
                  ),
                ),
              ],
            ),
          );
        });

        // Nested navigation widget that displays [navigator] in an [Expanded]
        // to take all the remaining from the [sideBar] space.
        Widget navigation = Obx(() {
          final bool isWork = router.routes.lastOrNull == Routes.work;
          return IgnorePointer(
            ignoring: isWork && context.isNarrow,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: context.isNarrow ? 0 : 350,
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
                );
              },
            ),
          );
        });

        // Navigator should be drawn under or above the [sideBar] for the
        // animations to look correctly.
        //
        // [Container]s are required for the [sideBar] to keep its state.
        // Otherwise, [Stack] widget will be updated, which will lead its
        // children to be updated as well.
        return Stack(
          key: const Key('WorkView'),
          children: [
            Container(
              color: style.colors.onPrimary,
              width: double.infinity,
              height: double.infinity,
            ),
            _background(),
            Container(child: context.isNarrow ? null : navigation),
            sideBar,
            Container(child: context.isNarrow ? navigation : null),
          ],
        );
      },
    );
  }

  /// Builds the background of [Routes.work] page.
  Widget _background() {
    final style = Theme.of(context).style;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
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
              child: ColoredBox(color: style.colors.onBackgroundOpacity7),
            ),
            if (!context.isNarrow) ...[
              Row(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: context.isNarrow ? 0 : 350,
                    ),
                    child: const SizedBox.expand(),
                  ),
                  Expanded(
                    child: ColoredBox(color: style.colors.onBackgroundOpacity2),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
