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
    return GetBuilder(
      init: StyleController(),
      builder: (StyleController c) {
        return Scaffold(
          backgroundColor: const Color(0xFFFFFFFF),
          body: SafeArea(
            child: Column(
              children: [
                _appBar(c, context),
                Expanded(child: _page(c)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns [Row] of [StyleCard]s and [IconButton]s meant to be an app bar.
  Widget _appBar(StyleController c, BuildContext context) {
    final style = Theme.of(context).style;

    final bool canPop = ModalRoute.of(context)?.canPop == true;

    return Row(
      children: [
        const SizedBox(width: 5),
        if (canPop) const StyledBackButton(canPop: true),
        Expanded(
          child: SizedBox(
            height: 50,
            child: Center(
              child: CustomScrollView(
                shrinkWrap: canPop,
                scrollDirection: Axis.horizontal,
                slivers: [
                  SliverList.builder(
                    itemCount: StyleTab.values.length,
                    itemBuilder: (context, i) => _button(c, i),
                  ),
                ],
              ),
            ),
          ),
        ),
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
            child: Icon(Icons.more_vert, color: style.colors.primary, size: 27),
          );
        }),
        // Obx(
        //   () => IconButton(
        //     onPressed: c.dense.toggle,
        //     icon: Icon(
        //       c.dense.value ? Icons.layers_clear_rounded : Icons.layers_rounded,
        //       color: const Color(0xFF1F3C5D),
        //     ),
        //   ),
        // ),
        // const SizedBox(width: 5),
        // Obx(
        //   () => IconButton(
        //     onPressed: c.inverted.toggle,
        //     icon: Icon(
        //       c.inverted.value
        //           ? Icons.dark_mode_rounded
        //           : Icons.light_mode_rounded,
        //       color: c.inverted.value
        //           ? const Color(0xFF1F3C5D)
        //           : const Color(0xFFFFB74D),
        //     ),
        //   ),
        // ),
        const SizedBox(width: 15),
      ],
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

  Widget _navigation(StyleController c, BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ...StyleTab.values.mapIndexed((i, _) => _button(c, i)),
      ],
    );
  }

  Widget _button(StyleController c, int i) {
    return Obx(() {
      final StyleTab tab = StyleTab.values[i];
      final bool selected = c.tab.value == tab;

      return switch (tab) {
        StyleTab.colors => StyleCard(
            icon: selected ? Icons.format_paint : Icons.format_paint_outlined,
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(i),
          ),
        StyleTab.typography => StyleCard(
            icon: selected ? Icons.text_snippet : Icons.text_snippet_outlined,
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(i),
          ),
        StyleTab.widgets => StyleCard(
            icon: selected ? Icons.widgets : Icons.widgets_outlined,
            inverted: selected,
            onPressed: () => c.pages.jumpToPage(i),
          ),
      };
    });
  }
}
