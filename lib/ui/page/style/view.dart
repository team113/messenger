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
            child: Row(
              children: [
                Flexible(flex: 1, child: _sideBar(c, context)),
                Flexible(flex: 5, child: _page(c)),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Returns a corresponding [StyleController.selected] page switcher.
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
        const SizedBox(height: 10),
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
          expandedHeight: 75,
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
                    title: 'Color palette',
                    icon: selected
                        ? Icons.format_paint
                        : Icons.format_paint_outlined,
                    inverted: selected,
                    onPressed: () => c.tab.value = tab,
                  );

                case StyleTab.typography:
                  return StyleCard(
                    title: 'Typography',
                    icon: selected
                        ? Icons.text_snippet
                        : Icons.text_snippet_outlined,
                    inverted: selected,
                    onPressed: () => c.tab.value = tab,
                  );

                case StyleTab.multimedia:
                  return StyleCard(
                    title: 'Multimedia',
                    icon: selected
                        ? Icons.play_lesson
                        : Icons.play_lesson_outlined,
                    inverted: selected,

                    // TODO: Implement.
                    onPressed: null,
                  );

                case StyleTab.elements:
                  return StyleCard(
                    title: 'Elements',
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
        const Divider(),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.ease,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (constraints.maxWidth >= 130) ...[
                    const Icon(Icons.light_mode, color: Color(0xFFFFB74D)),
                    const SizedBox(width: 10),
                  ],
                  Obx(() {
                    return Switch(
                      value: c.inverted.value,
                      onChanged: (b) => c.inverted.value = b,
                      activeColor: const Color(0xFF1F3C5D),
                      inactiveTrackColor: const Color(0xFFFFB74D),
                    );
                  }),
                  if (constraints.maxWidth >= 130) ...[
                    const SizedBox(width: 10),
                    const Icon(Icons.dark_mode, color: Color(0xFF1F3C5D)),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
