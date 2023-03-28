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
import 'package:messenger/themes.dart';

import '../widget/caption.dart';

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

    Widget gradient(String desc, Gradient gradient) => Column(
          children: [
            Caption(
              '${gradient.colors.map((e) => e.toHex())}, $desc',
              color: isDarkMode ? style.onPrimary : style.onBackground,
            ),
            _Colored(
              gradient: gradient,
              outline: isDarkMode ? style.onPrimary : style.onBackground,
            )
          ],
        );

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
              'background - Общий фон.', context.theme.colorScheme.background),
          color('primary - Основной цвет текста и обводки.',
              context.theme.colorScheme.primary),
          color('Hover на кнопках.',
              context.theme.colorScheme.primary.withOpacity(0.04)),
          color('Нажатие на кнопку.',
              context.theme.colorScheme.primary.withOpacity(0.12)),
          color('Основной цвет текста и обводки.',
              context.theme.colorScheme.primary),
          gradient(
            'Градиент кнопки начать общение.',
            const LinearGradient(
              colors: [Color(0xFF03A803), Color(0xFF20CD66)],
            ),
          ),
          color('Цвет заднего фона звонка.', style.primaryBackgroundLight),
          color('Цвет затемнения заднего фона в звонке.',
              style.transparentOpacity74),
          color('Цвет надписей и иконок над задним фоном звонка.',
              style.primaryHighlightDarkest),
          color('Цвет кнопок принятия звонка.', const Color(0xA634B139)),
          color('Цвет кнопки завершения звонка.', const Color(0xA6FF0000)),
          color(
            'Цвет кнопок в звонке.',
            style.primaryOpacity20,
          ),
          color('Цвет разделителей в панели ПКМ и в панели настроек.',
              style.transparentOpacity44),
          color('Задний фон панели настроек.', style.onPrimaryOpacity20),
          color('Задний фон панели ПКМ.', style.onPrimaryOpacity10),
          color('Цвет нижней панели с кнопками в звонке.',
              style.transparentOpacity60),
          color('Цвет разделителей в нижней панели с кнопками в звонке.',
              style.onPrimaryOpacity40),
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
    this.gradient,
    this.outline,
  }) : super(key: key);

  /// Color of the container.
  final Color? color;

  /// Gradient of the container.
  final Gradient? gradient;

  /// Optional outline of the container.
  final Color? outline;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<Style>()!;
    return Container(
      decoration: BoxDecoration(
        color: color,
        gradient: gradient,
        border: Border.all(color: outline ?? style.onBackground),
      ),
      height: 50,
    );
  }
}
