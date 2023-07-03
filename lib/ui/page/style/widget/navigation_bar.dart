import 'package:flutter/material.dart';

import '/themes.dart';

class StyleNavigationBar extends StatelessWidget {
  const StyleNavigationBar({super.key});

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
                                  'System messages', // Подсказки и предупреждения
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
        ],
      ),
    );
  }
}
