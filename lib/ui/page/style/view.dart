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

import '/routes.dart';
import '/themes.dart';
import '/ui/widget/outlined_rounded_button.dart';
import '/util/message_popup.dart';
import 'colors/view.dart';
import 'fonts/view.dart';
import 'widget/custom_switcher.dart';

/// View of the [Routes.style] page.
class StyleView extends StatefulWidget {
  const StyleView({super.key});

  @override
  State<StyleView> createState() => _StyleViewState();
}

/// State of an [StyleView] maintaining the [isDarkMode] and [selectedTab].
class _StyleViewState extends State<StyleView> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

  /// Initial and current [StyleTab] page.
  StyleTab selectedTab = StyleTab.colors;

  @override
  Widget build(BuildContext context) {
    final fonts = Theme.of(context).fonts;

    return SafeArea(
      child: Scaffold(
        body: Row(
          children: [
            Flexible(
              flex: 1,
              child: Container(
                color: const Color(0xFFFFFFFF),
                child: Column(
                  children: [
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverAppBar(
                            expandedHeight: 75,
                            leadingWidth: double.infinity,
                            flexibleSpace: FlexibleSpaceBar(
                              title: Text(
                                'Style by Gapopa',
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
                                final StyleTab tab = StyleTab.values[i];

                                final bool inverted = selectedTab == tab;

                                Widget card({
                                  required String title,
                                  required IconData? icon,
                                  void Function()? onPressed,
                                }) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    child: OutlinedRoundedButton(
                                      color: inverted
                                          ? const Color(0xFF1F3C5D)
                                          : const Color(0xFFFFFFFF),
                                      onPressed: onPressed ??
                                          () {
                                            selectedTab = tab;
                                            setState(() {});
                                          },
                                      title: Row(
                                        children: [
                                          Icon(
                                            icon,
                                            color: inverted
                                                ? const Color(0xFFFFFFFF)
                                                : const Color(0xFF1F3C5D),
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            title,
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: inverted
                                                  ? const Color(0xFFFFFFFF)
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
                                      title: 'Typography',
                                    );

                                  case StyleTab.multimedia:
                                    return card(
                                      icon: Icons.play_lesson_rounded,
                                      title: 'Multimedia',
                                      onPressed: () {
                                        // TODO: Implement Multimedia page.
                                        MessagePopup.error(
                                          'Not implemented yet',
                                        );
                                      },
                                    );

                                  case StyleTab.elements:
                                    return card(
                                      icon: Icons.widgets_rounded,
                                      title: 'Elements',
                                      onPressed: () {
                                        // TODO: Implement Elements page.
                                        MessagePopup.error(
                                          'Not implemented yet',
                                        );
                                      },
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
                              const Icon(
                                Icons.light_mode,
                                color: Color(0xFFFFB74D),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10),
                                child: CustomSwitcher(
                                  onChanged: (b) => setState(
                                    () => isDarkMode = b,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.dark_mode,
                                color: Color(0xFF1F3C5D),
                              ),
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
                                ColorStyleView(isDarkMode),
                              if (selectedTab == StyleTab.typography)
                                FontsView(isDarkMode: isDarkMode),
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
