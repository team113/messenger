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
class StyleView extends StatelessWidget {
  const StyleView({super.key});

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
                            shape: const RoundedRectangleBorder(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(10),
                              ),
                            ),
                            title: Text(
                              'Style by Gapopa',
                              style: fonts.displayMedium!.copyWith(
                                color: style.colors.onBackground,
                              ),
                            ),
                          ),
                          SliverList(
                            delegate: SliverChildListDelegate(
                              [
                                Column(
                                  children: [
                                    ExpansionTile(
                                      iconColor: style.colors.secondary,
                                      collapsedIconColor:
                                          style.colors.secondary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.format_paint_rounded,
                                            color: style.colors.secondary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Цветовая палитра',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Цвета приложения',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Цвета аватаров',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      iconColor: style.colors.secondary,
                                      collapsedIconColor:
                                          style.colors.secondary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.text_fields_rounded,
                                            color: style.colors.secondary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Типографика',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Виды шрифтов',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Стили шрифтов',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Интервалы',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      iconColor: style.colors.secondary,
                                      collapsedIconColor:
                                          style.colors.secondary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.play_lesson_rounded,
                                            color: style.colors.secondary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Мультимедиа',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Изображения',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Анимация',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Звук',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    ExpansionTile(
                                      iconColor: style.colors.secondary,
                                      collapsedIconColor:
                                          style.colors.secondary,
                                      title: Row(
                                        children: [
                                          Icon(
                                            Icons.widgets_rounded,
                                            color: style.colors.secondary,
                                          ),
                                          const SizedBox(width: 7),
                                          Text(
                                            'Элементы',
                                            style:
                                                fonts.headlineLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ],
                                      ),
                                      children: [
                                        ListTile(
                                          title: Text(
                                            'Поля ввода',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Кнопки',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Аватары',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Системные сообщения', // Подсказки и предупреждения
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Переключатели',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                        ListTile(
                                          title: Text(
                                            'Всплывающие окна',
                                            style: fonts.labelLarge!.copyWith(
                                              color: style.colors.onBackground,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 1800),
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
              child: Container(
                color: Color(0xFFF5f5f5),
                child: CustomScrollView(
                  slivers: [
                    SliverList(
                      delegate: SliverChildListDelegate(
                        [
                          Column(
                            children: [Text('Content')],
                          )
                        ],
                      ),
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
