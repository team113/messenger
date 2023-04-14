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
    final Style style = Theme.of(context).extension<Style>()!;

    Widget color(String desc, Color color) => Column(
          children: [
            Caption(
              '${color.toHex()}, $desc',
              color: isDarkMode
                  ? style.colors.onPrimary
                  : style.colors.onBackground,
            ),
            _Colored(
              color: color,
              outline: isDarkMode
                  ? style.colors.onPrimary
                  : style.colors.onBackground,
            )
          ],
        );

    Widget userColors() {
      return ListView.builder(
        itemCount: style.colors.userColors.length,
        itemBuilder: (context, index) {
          return SizedBox(
            height: 138,
            width: 100,
            child: Column(
              children: [
                Caption(
                  style.colors.userColors[index].toHex(),
                  color: isDarkMode
                      ? style.colors.onPrimary
                      : style.colors.onBackground,
                ),
                _Colored(
                  color: style.colors.userColors[index],
                  outline: isDarkMode
                      ? style.colors.onPrimary
                      : style.colors.onBackground,
                )
              ],
            ),
          );
        },
      );
    }

    return Scaffold(
      backgroundColor:
          isDarkMode ? style.colors.onBackground : style.colors.onPrimary,
      body: ListView(
        controller: ScrollController(),
        padding: const EdgeInsets.all(8),
        children: [
          const SizedBox(height: 20),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.light_mode, color: style.colors.warningColor),
              Switch(
                value: isDarkMode,
                onChanged: (b) => setState(() => isDarkMode = b),
              ),
              Icon(Icons.dark_mode, color: style.colors.secondary),
            ],
          ),
          color(
            'Основной цвет текста и обводки.',
            style.colors.secondary,
          ),
          color(
            'Вторичный цвет кнопок и фона.',
            style.colors.primary,
          ),
          color(
            'Общий фон.',
            style.colors.background,
          ),
          color(
            'Фон текста и обводки.',
            style.colors.primaryBackground,
          ),
          color(
            'Цвет заднего фона звонка.',
            style.colors.primaryBackgroundLight,
          ),
          color(
            'Цвет заднего фона аватара, кнопок звонка.',
            style.colors.primaryBackgroundLightest,
          ),
          color(
            'Цвет колеса загрузки.',
            style.colors.primaryHighlight,
          ),
          color(
            'Цвет кнопок навигационной панели.',
            style.colors.primaryHighlightDark,
          ),
          color(
            'Цвет надписей и иконок над задним фоном звонка.',
            style.colors.primaryHighlightDarkest,
          ),
          color(
            'Цвет, использующийся в левой части страницы профиля.',
            style.colors.onPrimary,
          ),
          color(
            'Цвет выпадающего меню.',
            style.colors.secondaryHighlight,
          ),
          color(
            'Цвет кнопок "Подробнее" и "Забыл пароль".',
            style.colors.secondaryHighlightShiny,
          ),
          color(
            'Цвет затемнения основного вида при неактивном вызове.',
            style.colors.secondaryHighlightShinier,
          ),
          color(
            'Цвет сообщения в чате.',
            style.colors.secondaryHighlightShiniest,
          ),
          color(
            'Цвет кнопок в звонке.',
            style.colors.onSecondary,
          ),
          color(
            'Цвет активного звонка.',
            style.colors.backgroundAuxiliary,
          ),
          color(
            'Цвет фона профиля.',
            style.colors.backgroundAuxiliaryLight,
          ),
          color(
            'Цвет отмены загрузки.',
            style.colors.backgroundAuxiliaryLighter,
          ),
          color(
            'Цвет фона участников группы.',
            style.colors.backgroundAuxiliaryLightest,
          ),
          color(
            'Цвет основного текста приложения.',
            style.colors.onBackground,
          ),
          color(
            'Цвет кнопки принятия звонка.',
            style.colors.acceptColor,
          ),
          color(
            'Цвет панели пользователя.',
            style.colors.acceptAuxiliaryColor,
          ),
          color(
            'Цвет кнопки завершения звонка.',
            style.colors.declineColor,
          ),
          color(
            'Цвет, предупредающий о чем-либо.',
            style.colors.dangerColor,
          ),
          color(
            'Цвет статуса "Не беспокоить".',
            style.colors.warningColor,
          ),
          const SizedBox(height: 100),
          Text(
            'Цвета аватаров:',
            style: context.textTheme.displayLarge!
                .copyWith(color: style.colors.onBackground),
          ),
          SizedBox(
            height: 1400,
            child: userColors(),
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
    final Style style = Theme.of(context).extension<Style>()!;

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: outline ?? style.colors.onBackground),
      ),
      height: 50,
    );
  }
}
