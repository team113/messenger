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

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:messenger/ui/widget/svg/svg.dart';
import 'package:messenger/ui/widget/widget_button.dart';
import 'package:messenger/util/platform_utils.dart';

import '/routes.dart';
import '/themes.dart';
import '/ui/page/home/page/chat/widget/back_button.dart';
import '/ui/page/home/widget/app_bar.dart';
import '/ui/page/home/widget/keep_alive.dart';
import '/ui/page/style/controller.dart';
import '/ui/page/style/widget/style_card.dart';
import 'page/colors/view.dart';
import 'page/typography/view.dart';
import 'page/widgets/view.dart';

/// View of the [Routes.style] page.
class StyleView extends StatelessWidget {
  const StyleView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    // final bool canPop = ModalRoute.of(context)?.canPop == true;

    return GetBuilder(
      init: StyleController(),
      builder: (StyleController c) {
        return Scaffold(
          backgroundColor: style.colors.background,
          // backgroundColor: const Color(0xFFFFFFFF),
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            // decoration: Container(
            //   decoration: BoxDecoration(
            //     gradient: LinearGradient(
            //       begin: Alignment.topCenter,
            //       end: Alignment.bottomCenter,
            //       stops: const [0.2, 1],
            //       colors: [
            //         style.colors.background,
            //         style.colors.background.withOpacity(0),
            //       ],
            //     ),
            //   ),
            // ),
            leading: [
              StyledBackButton(
                canPop: true,
                onPressed: ModalRoute.of(context)?.canPop == true
                    ? Navigator.of(context).pop
                    : router.home,
              ),
            ],
            title: Center(
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: [
                  ...StyleTab.values.mapIndexed((i, e) => _button(c, i)),
                ],
              ),
            ),
            actions: [
              Obx(() {
                return
                    // AnimatedOpacity(
                    // duration: 300.milliseconds,
                    // curve: Curves.ease,
                    // opacity: c.tab.value == StyleTab.typography ? 0 : 1,
                    // child
                    WidgetButton(
                  onPressed: c.inverted.toggle,
                  child: Container(
                    padding: const EdgeInsets.only(right: 12),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        width: 23,
                        key: c.inverted.value
                            ? const Key('Dark')
                            : const Key('Light'),
                        child: c.inverted.value
                            ? const SvgImage.asset(
                                'assets/icons/dark_mode.svg',
                                width: 20.8,
                                height: 20.8,
                              )
                            : const SvgImage.asset(
                                'assets/icons/light_mode.svg',
                                width: 23,
                                height: 23,
                              ),
                      ),
                    ),
                  ),
                  // ),
                );

                // return ContextMenuRegion(
                //   enablePrimaryTap: true,
                //   enableSecondaryTap: false,
                //   actions: [
                //     ContextMenuButton(
                //       label: c.dense.value ? 'Paddings on' : 'Paddings off',
                //       onPressed: c.dense.toggle,
                //     ),
                //     ContextMenuButton(
                //       label: c.inverted.value ? 'Light theme' : 'Dark theme',
                //       onPressed: c.inverted.toggle,
                //     ),
                //   ],
                //   child: Container(
                //     padding: const EdgeInsets.only(right: 12),
                //     child: Icon(
                //       Icons.more_vert,
                //       color: style.colors.primary,
                //       size: 27,
                //     ),
                //   ),
                // );
              }),
            ],
          ),
          body: _page(c, context),
          // extendBody: true,
        );
      },
    );
  }

  /// Returns a corresponding [StyleController.tab] page switcher.
  Widget _page(StyleController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Stack(
      children: [
        if (PlatformUtils.isWeb)
          IgnorePointer(
            child: Container(
              width: double.infinity,
              height: double.infinity,
              color: style.colors.background,
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: Obx(() {
              return AnimatedSwitcher(
                duration: 200.milliseconds,
                child: SvgImage.asset(
                  key: Key(c.inverted.value ? 'dark' : 'light'),
                  'assets/images/background_${c.inverted.value ? 'dark' : 'light'}.svg',
                  width: double.infinity,
                  height: double.infinity,
                  fit: BoxFit.cover,
                ),
              );
            }),
          ),
        ),
        MediaQuery.removePadding(
          removeTop: true,
          context: context,
          child: PageView(
            controller: c.pages,
            onPageChanged: (i) => c.tab.value = StyleTab.values[i],
            physics: const NeverScrollableScrollPhysics(),
            children: StyleTab.values.map((e) {
              return KeepAlivePage(
                child: switch (e) {
                  StyleTab.colors => Obx(() {
                      return ColorsView(inverted: c.inverted.value);
                    }),
                  StyleTab.typography => const TypographyView(),
                  StyleTab.widgets => const SelectionArea(child: WidgetsView()),
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _button(StyleController c, int i) {
    return Obx(() {
      final StyleTab tab = StyleTab.values[i];
      final bool selected = c.tab.value == tab;

      return switch (tab) {
        StyleTab.colors => StyleCard(
            asset: 'palette',
            assetWidth: 20.8,
            assetHeight: 20.8,
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(i),
          ),
        StyleTab.typography => StyleCard(
            asset: 'typography',
            assetWidth: 24.02,
            assetHeight: 16,
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(i),
          ),
        StyleTab.widgets => StyleCard(
            asset: 'widgets',
            assetWidth: 18.78,
            assetHeight: 18.78,
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(i),
          ),
      };
    });
  }
}
