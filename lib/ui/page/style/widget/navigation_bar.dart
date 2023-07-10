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

import 'custom_switcher.dart';
import '/themes.dart';

///
class StyleNavigationBar extends StatelessWidget {
  const StyleNavigationBar({super.key, required this.onChanged});

  final void Function(bool) onChanged;

  @override
  Widget build(BuildContext context) {
    final (style, fonts) = Theme.of(context).styles;

    return Container(
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
                SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      Column(
                        children: [
                          ExpansionTile(
                            iconColor: const Color(0xFF1F3C5D),
                            collapsedIconColor: const Color(0xFF1F3C5D),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.format_paint_rounded,
                                  color: Color(0xFF1F3C5D),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Color palette',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Application colors',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Avatar colors',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ExpansionTile(
                            iconColor: const Color(0xFF1F3C5D),
                            collapsedIconColor: const Color(0xFF1F3C5D),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.text_fields_rounded,
                                  color: Color(0xFF1F3C5D),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Typography',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Font',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Styles',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Links',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ExpansionTile(
                            iconColor: const Color(0xFF1F3C5D),
                            collapsedIconColor: const Color(0xFF1F3C5D),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.play_lesson_rounded,
                                  color: Color(0xFF1F3C5D),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Multimedia',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Images',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Animation',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Sound',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          ExpansionTile(
                            iconColor: const Color(0xFF1F3C5D),
                            collapsedIconColor: const Color(0xFF1F3C5D),
                            title: Row(
                              children: [
                                const Icon(
                                  Icons.widgets_rounded,
                                  color: Color(0xFF1F3C5D),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Elements',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Text fields',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Buttons',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Avatars',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'System messages',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Switchers',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Pop-ups',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
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
                    Icon(Icons.light_mode, color: style.colors.warningColor),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: CustomSwitcher(
                        onChanged: onChanged,
                      ),
                    ),
                    const Icon(Icons.dark_mode, color: Color(0xFF1F3C5D)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
