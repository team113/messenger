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

// import 'tab/color.dart';
// import 'tab/text.dart';
// import 'tab/element.dart';

/// View of the [Routes.style] page.
class StyleView extends StatefulWidget {
  const StyleView({super.key});

  @override
  State<StyleView> createState() => _StyleViewState();
}

class _StyleViewState extends State<StyleView> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

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
                color: style.colors.backgroundAuxiliaryLight.withOpacity(0.85),
                child: Column(
                  children: [
                    Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(10),
                        ),
                        color: style.colors.onBackgroundOpacity50,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Text(
                              'Style by Gapopa',
                              style: fonts.displayMedium!.copyWith(
                                color: style.colors.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                Column(
                                  children: [
                                    ExpansionTile(
                                      iconColor: style.colors.onPrimary,
                                      collapsedIconColor:
                                          style.colors.onPrimary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.format_paint_rounded,
                                            color: style.colors.onPrimary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Цветовая палитра',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Цвета приложения',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Цвета аватаров',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      iconColor: style.colors.onPrimary,
                                      collapsedIconColor:
                                          style.colors.onPrimary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.text_fields_rounded,
                                            color: style.colors.onPrimary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Типографика',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Виды шрифтов',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Стили шрифтов',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Интервалы',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      iconColor: style.colors.onPrimary,
                                      collapsedIconColor:
                                          style.colors.onPrimary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.play_lesson_rounded,
                                            color: style.colors.onPrimary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Мультимедиа',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Изображения',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Анимация',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Звук',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      iconColor: style.colors.onPrimary,
                                      collapsedIconColor:
                                          style.colors.onPrimary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.widgets_rounded,
                                            color: style.colors.onPrimary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Элементы',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Поля ввода',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Кнопки',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Аватары',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Системные сообщения', // Подсказки и предупреждения
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Переключатели',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Всплывающие окна',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
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
              ),
            ),
            Flexible(
              flex: 4,
              child: CustomScrollView(
                slivers: [
                  SliverList(
                    delegate: SliverChildListDelegate(
                      [Text('Style', style: fonts.displayLarge)],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
