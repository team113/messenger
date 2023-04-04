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

import '../widget/caption.dart';
import '/themes.dart';

/// Colors tab view of the [Routes.style] page.
class ColorStyleTabView extends StatefulWidget {
  const ColorStyleTabView({Key? key}) : super(key: key);

  @override
  State<ColorStyleTabView> createState() => _ColorStyleTabViewState();
}

/// State of a [ColorStyleTabView] used to keep the [isDarkMode] indicator.
class _ColorStyleTabViewState extends State<ColorStyleTabView> {
  /// Indicator whether this page is in dark mode.
  bool isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;

    Widget color(String desc, Color color) => Column(
          children: [
            Caption(
              '${color.toHex()}, $desc',
              color: isDarkMode ? style.onPrimary : style.onBackground,
            ),
            _Colored(
              color: color,
              outline: isDarkMode ? style.onPrimary : style.onBackground,
            )
          ],
        );

    Widget avatarColors() {
      List<Color> avatarColors = style.avatarColors;
      return ListView.builder(
        itemCount: avatarColors.length,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 140,
            width: 100,
            child: Column(
              children: [
                Caption(
                  avatarColors[index].toHex(),
                  color: isDarkMode ? style.onPrimary : style.onBackground,
                ),
                _Colored(
                  color: avatarColors[index],
                  outline: isDarkMode ? style.onPrimary : style.onBackground,
                )
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor: isDarkMode ? style.onBackground : style.onPrimary,
      body: ListView(
        controller: ScrollController(),
        padding: const EdgeInsets.all(8),
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.light_mode, color: style.doNotDistrubColor),
              Switch(
                value: isDarkMode,
                onChanged: (b) => setState(() => isDarkMode = b),
              ),
              Icon(Icons.dark_mode, color: style.primary),
            ],
          ),
          color(
            'Основной цвет текста и обводки.',
            style.primary,
          ),
          color(
            'Вторичный цвет кнопок и фона.',
            style.secondary,
          ),
          color(
            'Общий фон.',
            style.background,
          ),
          color(
            'Фон текста и обводки.',
            style.primaryBackground,
          ),
          color(
            'Цвет заднего фона звонка.',
            style.primaryBackgroundLight,
          ),
          color(
            'Цвет заднего фона аватара, кнопок звонка.',
            style.primaryBackgroundLightest,
          ),
          color(
            'Цвет колеса загрузки.',
            style.primaryHighlight,
          ),
          color(
            'Цвет кнопок навигационной панели.',
            style.primaryHighlightDark,
          ),
          color(
            'Цвет надписей и иконок над задним фоном звонка.',
            style.primaryHighlightDarkest,
          ),
          color(
            'Цвет, использующийся в левой части страницы профиля.',
            style.onPrimary,
          ),
          color(
            'Цвет выпадающего меню.',
            style.secondaryHighlight,
          ),
          color(
            'Цвет кнопок "Подробнее" и "Забыл пароль".',
            style.secondaryHighlightShiny,
          ),
          color(
            'Цвет затемнения основного вида при неактивном вызове.',
            style.secondaryHighlightShinier,
          ),
          color(
            'Цвет сообщения в чате.',
            style.secondaryHighlightShiniest,
          ),
          color(
            'Цвет кнопок в звонке.',
            style.onSecondary,
          ),
          color(
            'Цвет активного звонка.',
            style.backgroundAuxiliary,
          ),
          color(
            'Цвет фона профиля.',
            style.backgroundAuxiliaryLight,
          ),
          color(
            'Цвет отмены загрузки.',
            style.backgroundAuxiliaryLighter,
          ),
          color(
            'Цвет фона участников группы.',
            style.backgroundAuxiliaryLightest,
          ),
          color(
            'Цвет основного текста приложения.',
            style.onBackground,
          ),
          color(
            'Цвет кнопки принятия звонка.',
            style.acceptColor,
          ),
          color(
            'Цвет панели пользователя.',
            style.acceptAuxilaryColor,
          ),
          color(
            'Цвет кнопки завершения звонка.',
            style.declineColor,
          ),
          color(
            'Цвет, предупредающий о чем-либо.',
            style.warningColor,
          ),
          color(
            'Цвет статуса "Не беспокоить".',
            style.doNotDistrubColor,
          ),
          const SizedBox(height: 100),
          Text(
            'Цвета аватаров:',
            style: context.textTheme.displayLarge!
                .copyWith(color: style.onBackground),
          ),
          SizedBox(
            height: 1000,
            child: avatarColors(),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}

/// Displays a colored container.
class _Colored extends StatelessWidget {
  const _Colored({
    Key? key,
    this.color,
    this.outline,
  }) : super(key: key);

  /// Color of the container.
  final Color? color;

  /// Optional outline of the container.
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;
    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: outline ?? style.onBackground),
      ),
      height: 50,
    );
  }
}
