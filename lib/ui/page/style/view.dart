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
import '/ui/page/style/controller.dart';
import '/ui/page/style/widget/style_card.dart';
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
          body: SafeArea(
            child: Column(
              children: [
                _appBar(c),
                Expanded(child: _page(c)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns [Row] of [StyleCard]s and [IconButton]s meant to be an app bar.
  Widget _appBar(StyleController c) {
    return Row(
      children: [
        const SizedBox(width: 5),
        Expanded(
          child: SizedBox(
            height: 50,
            child: CustomScrollView(
              scrollDirection: Axis.horizontal,
              slivers: [
                SliverList.builder(
                  itemCount: StyleTab.values.length,
                  itemBuilder: (context, i) {
                    return Obx(() {
                      final StyleTab tab = StyleTab.values[i];
                      final bool selected = c.tab.value == tab;

                      return switch (tab) {
                        StyleTab.colors => StyleCard(
                            icon: selected
                                ? Icons.format_paint
                                : Icons.format_paint_outlined,
                            inverted: selected,
                            onPressed: () => c.tab.value = tab,
                          ),
                        StyleTab.typography => StyleCard(
                            icon: selected
                                ? Icons.text_snippet
                                : Icons.text_snippet_outlined,
                            inverted: selected,
                            onPressed: () => c.tab.value = tab,
                          ),
                        StyleTab.multimedia => StyleCard(
                            icon: selected
                                ? Icons.play_lesson
                                : Icons.play_lesson_outlined,
                            inverted: selected,

                            // TODO: Implement.
                            onPressed: null,
                          ),
                        StyleTab.elements => StyleCard(
                            icon: selected
                                ? Icons.widgets
                                : Icons.widgets_outlined,
                            inverted: selected,

                            // TODO: Implement.
                            onPressed: null,
                          ),
                      };
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        Obx(
          () => IconButton(
            onPressed: c.dense.toggle,
            icon: Icon(
              c.dense.value ? Icons.layers_clear_rounded : Icons.layers_rounded,
              color: const Color(0xFF1F3C5D),
            ),
          ),
        ),
        const SizedBox(width: 5),
        Obx(
          () => IconButton(
            onPressed: c.inverted.toggle,
            icon: Icon(
              c.inverted.value
                  ? Icons.dark_mode_rounded
                  : Icons.light_mode_rounded,
              color: c.inverted.value
                  ? const Color(0xFF1F3C5D)
                  : const Color(0xFFFFB74D),
            ),
          ),
        ),
        const SizedBox(width: 15),
      ],
    );
  }

  /// Returns a corresponding [StyleController.tab] page switcher.
  Widget _page(StyleController c) {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Obx(() {
        return switch (c.tab.value) {
          StyleTab.colors => ColorsView(
              inverted: c.inverted.value,
              dense: c.dense.value,
            ),
          StyleTab.typography => TypographyView(
              inverted: c.inverted.value,
              dense: c.dense.value,
            ),

          // TODO: Implement.
          StyleTab.multimedia => Container(),

          // TODO: Implement.
          StyleTab.elements => Container(),
        };
      }),
    );
  }
}
