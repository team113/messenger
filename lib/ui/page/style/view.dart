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
import 'colors/view.dart';
import 'fonts/view.dart';

/// View of the [Routes.style] page.
class StyleView extends StatelessWidget {
  const StyleView({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
        init: StyleController(),
        builder: (StyleController c) {
          return Scaffold(
            body: ColoredBox(
              color: const Color(0xFFFFFFFF),
              child: SafeArea(
                child: Row(
                  children: [
                    Flexible(
                      flex: 1,
                      fit: FlexFit.loose,
                      child: ColoredBox(
                        color: const Color(0xFFFFFFFF),
                        child: Column(
                          children: [
                            Expanded(child: _tabs(c, context)),
                            const SizedBox(height: 10),
                            _mode(c),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 5,
                      child: Container(
                        color: const Color(0xFFF5F5F5),
                        child: CustomScrollView(
                          slivers: [
                            SliverList(
                              delegate: SliverChildListDelegate([
                                Obx(() {
                                  List<Widget> pages = <Widget>[
                                    ColorStyleView(c.inverted.value),
                                    FontsView(c.inverted.value),
                                  ];

                                  return pages.elementAt(
                                    c.selectedTab.value.index,
                                  );
                                }),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
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

              final bool inverted = c.selectedTab.value == tab;

              switch (tab) {
                case StyleTab.colors:
                  return StyleCard(
                    title: 'Color palette',
                    icon: inverted
                        ? Icons.format_paint
                        : Icons.format_paint_outlined,
                    inverted: inverted,
                    onPressed: () => c.toggleTab(tab),
                  );

                case StyleTab.typography:
                  return StyleCard(
                    title: 'Typography',
                    icon: inverted
                        ? Icons.text_snippet
                        : Icons.text_snippet_outlined,
                    inverted: inverted,
                    onPressed: () => c.toggleTab(tab),
                  );

                case StyleTab.multimedia:
                  return StyleCard(
                    title: 'Multimedia',
                    icon: inverted
                        ? Icons.play_lesson
                        : Icons.play_lesson_outlined,
                    inverted: inverted,

                    // TODO: Implement.
                    onPressed: null,
                  );

                case StyleTab.elements:
                  return StyleCard(
                    title: 'Elements',
                    icon: inverted ? Icons.widgets : Icons.widgets_outlined,
                    inverted: inverted,

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

  /// Returns a [CustomSwitcher] switching between the light and dark mode.
  Widget _mode(StyleController c) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final Widget child;

            if (constraints.maxWidth < 130) {
              child = Obx(
                () => Switch.adaptive(
                  value: c.inverted.value,
                  onChanged: c.toggleInverted,
                  activeColor: const Color(0xFF1F3C5D),
                  inactiveTrackColor: const Color(0xFFFFB74D),
                ),
              );
            } else {
              child = Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.light_mode, color: Color(0xFFFFB74D)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Obx(
                      () => Switch.adaptive(
                        value: c.inverted.value,
                        onChanged: c.toggleInverted,
                        activeColor: const Color(0xFF1F3C5D),
                        inactiveTrackColor: const Color(0xFFFFB74D),
                      ),
                    ),
                  ),
                  const Icon(Icons.dark_mode, color: Color(0xFF1F3C5D)),
                ],
              );
            }

            return AnimatedSize(
              curve: Curves.ease,
              duration: const Duration(milliseconds: 200),
              child: child,
            );
          },
        ),
      ],
    );
  }
}
