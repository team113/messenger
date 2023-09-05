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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/home/page/chat/widget/back_button.dart';
import 'package:messenger/ui/page/home/widget/app_bar.dart';
import 'package:messenger/ui/widget/animated_button.dart';
import 'package:messenger/ui/widget/context_menu/menu.dart';
import 'package:messenger/ui/widget/context_menu/region.dart';
import 'package:messenger/util/platform_utils.dart';

import '/routes.dart';
import '/ui/page/home/widget/keep_alive.dart';
import '/ui/page/style/controller.dart';
import '/ui/page/style/widget/style_card.dart';
import 'page/colors/view.dart';
import 'page/elements/view.dart';
import 'page/multimedia/view.dart';
import 'page/typography/view.dart';
import 'page/widgets/view.dart';

/// View of the [Routes.style] page.
class StyleView extends StatelessWidget {
  const StyleView({super.key});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).style;

    final bool canPop = ModalRoute.of(context)?.canPop == true;

    return GetBuilder(
      init: StyleController(),
      builder: (StyleController c) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          extendBodyBehindAppBar: true,
          appBar: CustomAppBar(
            leading: canPop
                ? const [StyledBackButton(canPop: true)]
                : const [SizedBox(width: 8)],
            title: Center(
              child: ListView(
                shrinkWrap: canPop,
                scrollDirection: Axis.horizontal,
                children: [
                  ...StyleTab.values.mapIndexed((i, e) => _button(c, i)),
                ],
              ),
            ),
            actions: [
              Obx(() {
                return ContextMenuRegion(
                  enablePrimaryTap: true,
                  enableSecondaryTap: false,
                  actions: [
                    ContextMenuButton(
                      label: c.dense.value ? 'Paddings on' : 'Paddings off',
                      onPressed: c.dense.toggle,
                    ),
                    ContextMenuButton(
                      label: c.inverted.value ? 'Light theme' : 'Dark theme',
                      onPressed: c.inverted.toggle,
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.only(right: 12),
                    child: Icon(
                      Icons.more_vert,
                      color: style.colors.primary,
                      size: 27,
                    ),
                  ),
                );
              }),
            ],
          ),
          body: SafeArea(child: _page(c)),
          extendBody: true,
        );
      },
    );
  }

  /// Returns a corresponding [StyleController.tab] page switcher.
  Widget _page(StyleController c) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: PageView(
        controller: c.pages,
        onPageChanged: (i) => c.tab.value = StyleTab.values[i],
        physics: const NeverScrollableScrollPhysics(),
        children: StyleTab.values.map((e) {
          return KeepAlivePage(
            child: switch (e) {
              StyleTab.colors => Obx(() {
                  return ColorsView(
                    inverted: c.inverted.value,
                    dense: c.dense.value,
                  );
                }),
              StyleTab.typography => Obx(() {
                  return TypographyView(
                    inverted: c.inverted.value,
                    dense: c.dense.value,
                  );
                }),
              StyleTab.widgets => Obx(() {
                  return WidgetsView(
                    inverted: c.inverted.value,
                    dense: c.dense.value,
                  );
                }),
            },
          );
        }).toList(),
      ),
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
            asset: 'typography2',
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
