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

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '/routes.dart';
import '/themes.dart';
import '/ui/page/style/controller.dart';
import '/ui/page/style/widget/style_card.dart';
import '/util/platform_utils.dart';
import 'page/colors/view.dart';
import 'page/typography/view.dart';

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
          bottomNavigationBar: context.isNarrow
              ? Obx(
                  () => BottomNavigationBar(
                    type: BottomNavigationBarType.shifting,
                    backgroundColor: const Color(0xFFFFFFFF),
                    items: const <BottomNavigationBarItem>[
                      BottomNavigationBarItem(
                        icon: Icon(Icons.format_paint_outlined),
                        activeIcon: Icon(Icons.format_paint),
                        label: 'Colors',
                      ),
                      BottomNavigationBarItem(
                        icon: Icon(Icons.text_snippet_outlined),
                        activeIcon: Icon(Icons.text_snippet),
                        label: 'Typography',
                      ),
                    ],
                    currentIndex: c.tab.value.index,
                    selectedItemColor: const Color(0xFF1F3C5D),
                    onTap: (index) => c.tab.value = StyleTab.values[index],
                  ),
                )
              : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!context.isNarrow)
                  SizedBox(width: 100, child: _sideBar(c, context)),
                Expanded(child: _page(c)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns a corresponding [StyleController.tab] page switcher.
  Widget _page(StyleController c) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Obx(() {
        return switch (c.tab.value) {
          StyleTab.colors => ColorsView(c.inverted.value),
          StyleTab.typography => TypographyView(c.inverted.value),

          // TODO: Implement.
          StyleTab.multimedia => Container(),

          // TODO: Implement.
          StyleTab.elements => Container(),
        };
      }),
    );
  }

  /// Returns the [Column] of [_tabs] and [_mode] meant to be a side bar.
  Widget _sideBar(StyleController c, BuildContext context) {
    return Column(
      children: [
        Expanded(child: _tabs(c, context)),
        _mode(c),
        const SizedBox(height: 20),
      ],
    );
  }

  /// Returns the list of [StyleCard]s representing the [StyleTab]s.
  Widget _tabs(StyleController c, BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 60,
          leadingWidth: double.infinity,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Style',
              textAlign: TextAlign.center,
              style: fonts.headlineLarge!.copyWith(
                color: const Color(0xFF1F3C5D),
              ),
            ),
          ),
        ),
        SliverList.builder(
          itemCount: StyleTab.values.length,
          itemBuilder: (context, i) {
            return Obx(() {
              final StyleTab tab = StyleTab.values[i];
              final bool selected = c.tab.value == tab;

              switch (tab) {
                case StyleTab.colors:
                  return StyleCard(
                    icon: selected
                        ? Icons.format_paint
                        : Icons.format_paint_outlined,
                    inverted: selected,
                    onPressed: () => c.tab.value = tab,
                  );

                case StyleTab.typography:
                  return StyleCard(
                    icon: selected
                        ? Icons.text_snippet
                        : Icons.text_snippet_outlined,
                    inverted: selected,
                    onPressed: () => c.tab.value = tab,
                  );

                case StyleTab.multimedia:
                  return StyleCard(
                    icon: selected
                        ? Icons.play_lesson
                        : Icons.play_lesson_outlined,
                    inverted: selected,

                    // TODO: Implement.
                    onPressed: null,
                  );

                case StyleTab.elements:
                  return StyleCard(
                    icon: selected ? Icons.widgets : Icons.widgets_outlined,
                    inverted: selected,

                    // TODO: Implement.
                    onPressed: null,
                  );
              }
            });
          },
        ),
      ],
    );
  }

  /// Returns a [Switch] switching the [StyleController.inverted] indicator.
  Widget _mode(StyleController c) {
    return Column(
      children: [
        const Divider(color: Color(0xFFE8E8E8)),
        const SizedBox(height: 10),
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Obx(() {
              return Switch(
                value: c.inverted.value,
                onChanged: (b) => c.inverted.value = b,
                activeColor: const Color(0xFF1F3C5D),
                inactiveTrackColor: const Color(0xFFFFB74D),
              );
            }),
          ],
        ),
      ],
    );
  }
}
