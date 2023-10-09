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
import '/ui/widget/svg/svg.dart';
import '/ui/widget/widget_button.dart';
import '/util/platform_utils.dart';
import 'page/colors/view.dart';
import 'page/icons/view.dart';
import 'page/typography/view.dart';
import 'page/widgets/view.dart';

/// View of the [Routes.style] page.
class StyleView extends StatelessWidget {
  const StyleView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    return GetBuilder(
      init: StyleController(),
      builder: (StyleController c) {
        return Scaffold(
          backgroundColor: style.colors.background,
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            leading: [
              StyledBackButton(
                onPressed: ModalRoute.of(context)?.canPop == true
                    ? Navigator.of(context).pop
                    : router.home,
              ),
            ],
            title: Center(
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: StyleTab.values.map((e) => _button(c, e)).toList(),
              ),
            ),
            actions: [
              Obx(() {
                return WidgetButton(
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
                );
              }),
            ],
          ),
          body: _page(c, context),
        );
      },
    );
  }

  /// Returns the [StyleTab] pages view.
  Widget _page(StyleController c, BuildContext context) {
    final style = Theme.of(context).style;

    return Stack(
      children: [
        // For web, background color is displayed in `index.html` file.
        if (!PlatformUtils.isWeb)
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
        Padding(
          padding: const EdgeInsets.only(top: 12),
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
                  StyleTab.icons => const SelectionArea(child: IconsView()),
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Returns a button representing the provided [StyleTab].
  Widget _button(StyleController c, StyleTab tab) {
    return Obx(() {
      final bool selected = c.tab.value == tab;

      return switch (tab) {
        StyleTab.colors => StyleCard(
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(tab.index),
            child: const SvgImage.asset(
              'assets/icons/palette.svg',
              width: 20.8,
              height: 20.8,
            ),
          ),
        StyleTab.typography => StyleCard(
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(tab.index),
            child: const SvgImage.asset(
              'assets/icons/typography.svg',
              width: 24.02,
              height: 16,
            ),
          ),
        StyleTab.widgets => StyleCard(
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(tab.index),
            child: const SvgImage.asset(
              'assets/icons/widgets.svg',
              width: 18.78,
              height: 18.78,
            ),
          ),
        StyleTab.icons => StyleCard(
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(tab.index),
            child: const SvgImage.asset(
              'assets/icons/icons.svg',
              width: 20.95,
              height: 18.8,
            ),
          ),
      };
    });
  }
}
