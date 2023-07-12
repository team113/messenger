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
import 'package:messenger/themes.dart';
import 'package:messenger/ui/page/style/widget/custom_switcher.dart';

import '../../../routes.dart';
import '../../widget/outlined_rounded_button.dart';
import 'colors/view.dart';
import 'element/view.dart';
import 'fonts/view.dart';
import 'media/view.dart';

/// View of the [Routes.style] page.
class StyleView extends StatefulWidget {
  const StyleView({super.key});

  @override
  State<StyleView> createState() => _StyleViewState();
}

class _StyleViewState extends State<StyleView> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

  ///
  StyleTab selectedTab = StyleTab.colors;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return SafeArea(
      child: Scaffold(
        body: Row(
          children: [
            Flexible(
              flex: 1,
              child: Container(
                color: style.colors.onPrimary,
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 80,
                            leadingWidth: double.infinity,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(
                                'Style by Gapopa',
                                style: fonts.headlineLarge!.copyWith(
                                  color: const Color(0xFF1F3C5D),
                                ),
                              ),
                            ),
                          ),
                          SliverList.builder(
                              itemCount: StyleTab.values.length,
                              itemBuilder: (context, i) {
                                final StyleTab tab = StyleTab.values[i];

                                final bool inverted =
                                    tab == router.styleSection.value &&
                                        router.route == Routes.style;

                                Widget card({
                                  required String title,
                                  required IconData? icon,
                                }) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 15,
                                      vertical: 5,
                                    ),
                                    child: OutlinedRoundedButton(
                                      color: inverted
                                          ? const Color(0xFF1F3C5D)
                                          : style.colors.onPrimary,
                                      onPressed: () {
                                        selectedTab = tab;

                                        if (router.styleSection.value == tab) {
                                          router.styleSection.refresh();
                                        } else {
                                          router.styleSection.value = tab;
                                        }
                                        router.me();
                                        setState(() {});
                                      },
                                      title: Row(
                                        children: [
                                          Icon(
                                            icon,
                                            color: inverted
                                                ? style.colors.onPrimary
                                                : const Color(0xFF1F3C5D),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            title,
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: inverted
                                                  ? style.colors.onPrimary
                                                  : const Color(0xFF1F3C5D),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                switch (tab) {
                                  case StyleTab.colors:
                                    return card(
                                      title: 'Color palette',
                                      icon: Icons.format_paint_rounded,
                                    );

                                  case StyleTab.typography:
                                    return card(
                                        icon: Icons.text_fields_rounded,
                                        title: 'Typography');

                                  case StyleTab.multimedia:
                                    return card(
                                      icon: Icons.play_lesson_rounded,
                                      title: 'Multimedia',
                                    );

                                  case StyleTab.elements:
                                    return card(
                                      icon: Icons.widgets_rounded,
                                      title: 'Elements',
                                    );
                                }
                              }),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20, top: 10),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.light_mode,
                                  color: style.colors.warningColor),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: CustomSwitcher(
                                  onChanged: (b) =>
                                      setState(() => isDarkMode = b),
                                ),
                              ),
                              const Icon(Icons.dark_mode,
                                  color: Color(0xFF1F3C5D)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Flexible(
              flex: 4,
              child: Container(
                color: const Color(0xFFF5F5F5),
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate([
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 70),
                          child: Column(
                            children: [
                              if (selectedTab == StyleTab.colors)
                                ColorStyleView(isDarkMode: isDarkMode),
                              if (selectedTab == StyleTab.typography)
                                FontsView(isDarkMode: isDarkMode),
                              if (selectedTab == StyleTab.multimedia)
                                MultimediaView(isDarkMode: isDarkMode),
                              if (selectedTab == StyleTab.elements)
                                ElementStyleTabView(isDarkMode: isDarkMode),
                            ],
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
