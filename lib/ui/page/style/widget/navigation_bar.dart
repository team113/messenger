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
                  expandedHeight: 100,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(10),
                    ),
                  ),
                  leadingWidth: double.infinity,
                  leading: Padding(
                    padding: const EdgeInsets.only(
                      left: 20,
                      top: 20,
                    ),
                    child: Text(
                      'Style by Gapopa',
                      style: fonts.displayLarge!.copyWith(
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
                                  'Цветовая палитра',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Цвета приложения',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Цвета аватаров',
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
                                  'Типографика',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Виды шрифтов',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Стили шрифтов',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Интервалы',
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
                                Icon(
                                  Icons.play_lesson_rounded,
                                  color: const Color(0xFF1F3C5D),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Мультимедиа',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Изображения',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Анимация',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Звук',
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
                                Icon(
                                  Icons.widgets_rounded,
                                  color: const Color(0xFF1F3C5D),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Элементы',
                                  style: fonts.headlineLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ],
                            ),
                            children: [
                              ListTile(
                                title: Text(
                                  'Поля ввода',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Кнопки',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Аватары',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Системные сообщения', // Подсказки и предупреждения
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Переключатели',
                                  style: fonts.labelLarge!.copyWith(
                                    color: const Color(0xFF1F3C5D),
                                  ),
                                ),
                              ),
                              ListTile(
                                title: Text(
                                  'Всплывающие окна',
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
